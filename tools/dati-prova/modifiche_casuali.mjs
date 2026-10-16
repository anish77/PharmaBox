// Modifiche casuali alle liste di un utente, come farebbe un operatore:
// cancella alcune liste (con i loro prodotti), ne rinomina altre e in altre
// ancora toglie prodotti e cambia quantità, tenendo coerente totalePezzi.
// Uso: EMAIL=... PASSWORD=... [SEED=n] node modifiche_casuali.mjs [--scrivi]
// Senza --scrivi mostra solo cosa farebbe. Con lo stesso SEED (e le stesse
// liste) il piano è lo stesso.

const KEY = "AIzaSyCySHo0x1vZqzXhRWuQBrYJqlgnpQwozwE";
const DOCS = "projects/pharmabox-1c149/databases/(default)/documents";
const FS = `https://firestore.googleapis.com/v1/${DOCS}`;
const NOMI_NUOVI = [
  "Banco OTC", "Scaffale integratori", "Retro farmaci etici", "Banco dermocosmesi",
  "Magazzino resi", "Vetrina stagionale", "Frigo vaccini", "Banco veterinaria",
  "Scaffale omeopatici", "Retro scorte", "Banco infanzia", "Cassetti stupefacenti",
];

const scrivi = process.argv.includes("--scrivi");
const seed = Number(process.env.SEED) || Date.now() % 1_000_000;
let stato = seed;
const random = () => ((stato = (stato * 1103515245 + 12345) % 2 ** 31) / 2 ** 31);
const rand = (min, max) => min + Math.floor(random() * (max - min + 1));
const shuffle = (a) => {
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
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
const commit = async (writes) => {
  // Firestore accetta al massimo 500 scritture per commit
  for (let i = 0; i < writes.length; i += 450) {
    const r = await fetch(`${FS}:commit`, {
      method: "POST", headers: { ...h, "content-type": "application/json" },
      body: JSON.stringify({ writes: writes.slice(i, i + 450) }),
    });
    if (!r.ok) throw new Error(`commit: ${r.status} ${await r.text()}`);
  }
};
const items = async (lista) =>
  (await get(`${FS}/${lista.name.slice(DOCS.length + 1)}/items?pageSize=300`)).documents ?? [];
const nome = (l) => l.fields?.nome?.stringValue ?? "";
const qta = (d) => Number(d.fields?.quantity?.integerValue ?? 0);

const liste = shuffle((await get(`${FS}/users/${login.localId}/liste?pageSize=300`)).documents ?? []);
console.log(`utente ${process.env.EMAIL}, ${liste.length} liste, SEED=${seed}${scrivi ? "" : " (prova)"}`);
if (liste.length < 6) throw new Error("troppe poche liste per un giro completo");

const nCancella = rand(2, 3);
const nRinomina = rand(3, 4);
const nModifica = rand(2, 3);
const daCancellare = liste.slice(0, nCancella);
const daRinominare = liste.slice(nCancella, nCancella + nRinomina);
const daModificare = liste.slice(nCancella + nRinomina, nCancella + nRinomina + nModifica);
const adesso = { timestampValue: new Date().toISOString() };

// 1. Cancellazioni: prima i prodotti, poi la lista (come eliminaLista)
for (const l of daCancellare) {
  const prodotti = await items(l);
  console.log(`- CANCELLA "${nome(l)}" (${prodotti.length} prodotti, ${l.fields.totalePezzi.integerValue} pezzi)`);
  if (scrivi) await commit([...prodotti.map((d) => ({ delete: d.name })), { delete: l.name }]);
}

// 2. Rinomine: nomi nuovi, mai già usati
const usati = new Set(liste.map((l) => nome(l).toLowerCase()));
const liberi = shuffle(NOMI_NUOVI.filter((n) => !usati.has(n.toLowerCase())));
for (const l of daRinominare) {
  const nuovo = liberi.pop();
  if (!nuovo) break;
  console.log(`- RINOMINA "${nome(l)}" -> "${nuovo}"`);
  if (scrivi) {
    await commit([{
      update: { name: l.name, fields: { nome: { stringValue: nuovo }, updatedAt: adesso } },
      updateMask: { fieldPaths: ["nome", "updatedAt"] },
    }]);
  }
}

// 3. Modifiche ai prodotti: alcuni tolti, alcune quantità cambiate
for (const l of daModificare) {
  const prodotti = shuffle(await items(l));
  const tolti = prodotti.slice(0, rand(2, 5));
  const cambiati = prodotti.slice(tolti.length, tolti.length + rand(3, 6));
  const writes = [];
  let delta = 0;
  for (const d of tolti) {
    delta -= qta(d);
    writes.push({ delete: d.name });
  }
  const dettagli = cambiati.map((d) => {
    const prima = qta(d);
    // variazione sempre diversa da zero; a 0 il prodotto resta in lista
    const variazione = [-2, -1, 1, 2, 3][rand(0, 4)];
    const dopo = prima + variazione < 0 ? prima + 1 : prima + variazione;
    delta += dopo - prima;
    writes.push({
      update: { name: d.name, fields: { quantity: { integerValue: String(dopo) }, updatedAt: adesso } },
      updateMask: { fieldPaths: ["quantity", "updatedAt"] },
    });
    return `${prima}->${dopo}`;
  });
  writes.push({
    update: { name: l.name, fields: { updatedAt: adesso } },
    updateMask: { fieldPaths: ["updatedAt"] },
    updateTransforms: [{ fieldPath: "totalePezzi", increment: { integerValue: String(delta) } }],
  });
  console.log(`- MODIFICA "${nome(l)}": tolti ${tolti.length} prodotti, quantità cambiate ${dettagli.join(", ")} (totale ${delta >= 0 ? "+" : ""}${delta})`);
  if (scrivi) await commit(writes);
}
