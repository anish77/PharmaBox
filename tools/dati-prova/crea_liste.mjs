// Crea liste di prova su Firestore per un utente PharmaBox, con la stessa
// struttura di ListeRepository: users/{uid}/liste/{id} + items/{minsan}.
// Uso: EMAIL=... PASSWORD=... [NOMI=a,b] [PRODOTTI=60] [PEZZI_MIN=100] [PEZZI_MAX=230] \
//      node crea_liste.mjs [--scrivi]
// Senza --scrivi mostra solo cosa farebbe.

const API_KEYS = [
  "AIzaSyCySHo0x1vZqzXhRWuQBrYJqlgnpQwozwE", // android
  "AIzaSyC_b_V_x-40wEN7dRRSeMKHBIaqu3dlKso", // ios
];
const PROJECT = "pharmabox-1c149";
const WORKER = "https://farmadati-proxy.gianluca-carta.workers.dev";
const FS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

const NOMI_LISTE = (process.env.NOMI ? process.env.NOMI.split(",") : [
  "Banco destra", "Banco sinistra", "Banco centrale", "Banco cassa", "Banco vetrina",
  "Retro scaffale A", "Retro scaffale B", "Retro magazzino", "Retro frigo", "Retro cassettiere",
]);
const RICERCHE = [
  "TACHIPIRINA", "BRUFEN", "ASPIRINA", "MOMENT", "VOLTAREN", "OKI", "ENTEROGERMINA",
  "AUGMENTIN", "FLUIMUCIL", "GAVISCON", "BENTELAN", "NUROFEN", "ZITROMAX", "BUSCOPAN",
  "MAALOX", "IMODIUM", "BENAGOL", "VIVIN", "AULIN", "LASONIL",
];
const PRODOTTI_PER_LISTA = Number(process.env.PRODOTTI ?? 60);
const PEZZI_MIN = Number(process.env.PEZZI_MIN ?? 100);
const PEZZI_MAX = Number(process.env.PEZZI_MAX ?? 230);

const scrivi = process.argv.includes("--scrivi");
const rand = (min, max) => min + Math.floor(Math.random() * (max - min + 1));
const shuffle = (a) => {
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
};
const autoId = () => {
  const c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  return Array.from({ length: 20 }, () => c[Math.floor(Math.random() * c.length)]).join("");
};

async function login() {
  for (const key of API_KEYS) {
    const r = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${key}`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          email: process.env.EMAIL,
          password: process.env.PASSWORD,
          returnSecureToken: true,
        }),
      },
    );
    const data = await r.json();
    if (r.ok) return { uid: data.localId, token: data.idToken };
    console.warn(`login con chiave ${key.slice(0, 10)}…: ${data.error?.message}`);
  }
  throw new Error("login fallito");
}

async function listeEsistenti({ uid, token }) {
  const r = await fetch(`${FS}/users/${uid}/liste?pageSize=300`, {
    headers: { authorization: `Bearer ${token}` },
  });
  if (!r.ok) throw new Error(`lettura liste: ${r.status} ${await r.text()}`);
  const data = await r.json();
  return (data.documents ?? []).map((d) => ({
    id: d.name.split("/").pop(),
    nome: d.fields?.nome?.stringValue,
    pezzi: d.fields?.totalePezzi?.integerValue,
  }));
}

async function poolProdotti({ token }) {
  const perMinsan = new Map();
  for (const q of RICERCHE) {
    const r = await fetch(`${WORKER}/v1/prodotti?q=${encodeURIComponent(q)}`, {
      headers: { authorization: `Bearer ${token}` },
    });
    if (!r.ok) {
      console.warn(`ricerca ${q}: ${r.status}`);
      continue;
    }
    for (const p of (await r.json()).prodotti) {
      if (p.minsan && p.nome) perMinsan.set(p.minsan, p.nome);
    }
  }
  return [...perMinsan.entries()].map(([minsan, nome]) => ({ minsan, nome }));
}

/** Distribuisce `totale` pezzi su `n` prodotti, almeno 1 ciascuno. */
function distribuisci(totale, n) {
  const pesi = Array.from({ length: n }, () => Math.random() ** 2);
  const somma = pesi.reduce((a, b) => a + b, 0);
  const extra = totale - n;
  const q = pesi.map((p) => 1 + Math.floor((p / somma) * extra));
  let resto = totale - q.reduce((a, b) => a + b, 0);
  while (resto-- > 0) q[rand(0, n - 1)]++;
  return q;
}

const ts = (d) => ({ timestampValue: d.toISOString() });

async function creaLista({ uid, token }, nome, prodotti, quantita, quando) {
  const id = autoId();
  const base = `projects/${PROJECT}/databases/(default)/documents/users/${uid}/liste/${id}`;
  const totale = quantita.reduce((a, b) => a + b, 0);
  const writes = [
    {
      update: {
        name: base,
        fields: {
          nome: { stringValue: nome },
          totalePezzi: { integerValue: String(totale) },
          createdAt: ts(quando),
          updatedAt: ts(quando),
        },
      },
    },
    ...prodotti.map((p, i) => ({
      update: {
        name: `${base}/items/${p.minsan.replaceAll("/", "_")}`,
        fields: {
          minsan: { stringValue: p.minsan },
          titolo: { stringValue: p.nome },
          quantity: { integerValue: String(quantita[i]) },
          updatedAt: ts(quando),
        },
      },
    })),
  ];
  const r = await fetch(`${FS}:commit`, {
    method: "POST",
    headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    body: JSON.stringify({ writes }),
  });
  if (!r.ok) throw new Error(`creazione ${nome}: ${r.status} ${await r.text()}`);
  return { id, totale };
}

const auth = await login();
console.log(`utente: ${process.env.EMAIL} uid=${auth.uid}`);
const esistenti = await listeEsistenti(auth);
console.log(`liste esistenti (${esistenti.length}):`, esistenti.map((l) => `${l.nome} [${l.pezzi}]`).join(", ") || "nessuna");

const pool = await poolProdotti(auth);
console.log(`prodotti reali disponibili: ${pool.length}`);
if (pool.length < PRODOTTI_PER_LISTA) throw new Error("troppo pochi prodotti");

const giaUsati = new Set(esistenti.map((l) => (l.nome ?? "").toLowerCase()));
for (const [i, nome] of NOMI_LISTE.entries()) {
  if (giaUsati.has(nome.toLowerCase())) {
    console.log(`- ${nome}: esiste già, salto`);
    continue;
  }
  const prodotti = shuffle([...pool]).slice(0, PRODOTTI_PER_LISTA);
  const quantita = distribuisci(rand(PEZZI_MIN, PEZZI_MAX), PRODOTTI_PER_LISTA);
  // date diverse, una lista al minuto, così l'ordinamento è stabile
  const quando = new Date(Date.now() - (NOMI_LISTE.length - i) * 60_000);
  if (!scrivi) {
    console.log(`- ${nome}: ${prodotti.length} prodotti, ${quantita.reduce((a, b) => a + b, 0)} pezzi (prova)`);
    continue;
  }
  const { id, totale } = await creaLista(auth, nome, prodotti, quantita, quando);
  console.log(`- ${nome}: creata ${id}, ${prodotti.length} prodotti, ${totale} pezzi`);
}
