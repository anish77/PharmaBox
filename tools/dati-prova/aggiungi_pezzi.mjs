// Aggiunge pezzi a liste esistenti: una parte su prodotti già in lista, una
// parte su MINSAN nuovi. Incrementi atomici (come l'app).
// Uso: EMAIL=... PASSWORD=... NOMI=a,b,c PEZZI=20 node aggiungi_pezzi.mjs [--scrivi]

const KEY = "AIzaSyCySHo0x1vZqzXhRWuQBrYJqlgnpQwozwE";
const DOCS = "projects/pharmabox-1c149/databases/(default)/documents";
const FS = `https://firestore.googleapis.com/v1/${DOCS}`;
const WORKER = "https://farmadati-proxy.gianluca-carta.workers.dev";
const RICERCHE = [
  "TACHIPIRINA", "BRUFEN", "ASPIRINA", "MOMENT", "VOLTAREN", "OKI", "ENTEROGERMINA",
  "AUGMENTIN", "FLUIMUCIL", "GAVISCON", "BENTELAN", "NUROFEN", "ZITROMAX", "BUSCOPAN",
  "MAALOX", "IMODIUM", "BENAGOL", "VIVIN", "AULIN", "LASONIL",
];
const NOMI = process.env.NOMI.split(",");
const PEZZI = Number(process.env.PEZZI);
const scrivi = process.argv.includes("--scrivi");
const rand = (min, max) => min + Math.floor(Math.random() * (max - min + 1));
const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
const shuffle = (a) => {
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
};

const login = await (await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${KEY}`, {
  method: "POST", headers: { "content-type": "application/json" },
  body: JSON.stringify({ email: process.env.EMAIL, password: process.env.PASSWORD, returnSecureToken: true }),
})).json();
if (!login.idToken) throw new Error(`login: ${login.error?.message}`);
const h = { authorization: `Bearer ${login.idToken}` };
const get = async (url) => {
  const r = await fetch(url, { headers: h });
  if (!r.ok) throw new Error(`${url}: ${r.status} ${await r.text()}`);
  return r.json();
};

const pool = new Map();
for (const q of RICERCHE) {
  const r = await fetch(`${WORKER}/v1/prodotti?q=${encodeURIComponent(q)}`, { headers: h });
  if (!r.ok) continue;
  for (const p of (await r.json()).prodotti) if (p.minsan && p.nome) pool.set(p.minsan, p.nome);
}

const liste = (await get(`${FS}/users/${login.localId}/liste?pageSize=300`)).documents ?? [];
for (const nome of NOMI) {
  const lista = liste.find((d) => d.fields?.nome?.stringValue === nome);
  if (!lista) { console.log(`- ${nome}: non trovata, salto`); continue; }
  const items = (await get(`${FS}/${lista.name.slice(DOCS.length + 1)}/items?pageSize=300`)).documents ?? [];
  const presenti = items.map((d) => ({ minsan: d.fields.minsan.stringValue, nome: d.fields.titolo?.stringValue ?? "" }));
  const giaInLista = new Set(presenti.map((p) => p.minsan));

  // circa metà dei pezzi su 4-6 MINSAN nuovi (almeno 1 pezzo ciascuno), il resto sui presenti
  const nNuovi = rand(4, 6);
  const nuovi = shuffle([...pool].filter(([m]) => !giaInLista.has(m))).slice(0, nNuovi)
    .map(([minsan, nome]) => ({ minsan, nome }));
  const pezziNuovi = rand(nNuovi, Math.max(nNuovi, Math.round(PEZZI / 2)));
  const delta = new Map();
  const aggiungi = (p, n) => delta.set(p.minsan, { ...p, n: (delta.get(p.minsan)?.n ?? 0) + n });
  for (const p of nuovi) aggiungi(p, 1);
  for (let i = nNuovi; i < pezziNuovi; i++) aggiungi(pick(nuovi), 1);
  for (let i = pezziNuovi; i < PEZZI; i++) aggiungi(pick(presenti), 1);
  const totale = [...delta.values()].reduce((s, d) => s + d.n, 0);

  console.log(`- ${nome}: +${totale} pezzi (${pezziNuovi} su ${nuovi.length} MINSAN nuovi, ${totale - pezziNuovi} su ${delta.size - nuovi.length} già presenti)${scrivi ? "" : " (prova)"}`);
  if (!scrivi) continue;

  const adesso = { timestampValue: new Date().toISOString() };
  const writes = [
    ...[...delta.values()].map((d) => ({
      update: {
        name: `${lista.name}/items/${d.minsan.replaceAll("/", "_")}`,
        fields: { minsan: { stringValue: d.minsan }, titolo: { stringValue: d.nome }, updatedAt: adesso },
      },
      updateMask: { fieldPaths: ["minsan", "titolo", "updatedAt"] },
      updateTransforms: [{ fieldPath: "quantity", increment: { integerValue: String(d.n) } }],
    })),
    {
      update: { name: lista.name, fields: { updatedAt: adesso } },
      updateMask: { fieldPaths: ["updatedAt"] },
      updateTransforms: [{ fieldPath: "totalePezzi", increment: { integerValue: String(totale) } }],
    },
  ];
  const r = await fetch(`${FS}:commit`, {
    method: "POST", headers: { ...h, "content-type": "application/json" }, body: JSON.stringify({ writes }),
  });
  if (!r.ok) throw new Error(`${nome}: ${r.status} ${await r.text()}`);
}
