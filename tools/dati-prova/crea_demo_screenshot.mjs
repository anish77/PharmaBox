// Account demo per gli screenshot App Store (integration_test/screenshot_app_store_test.dart):
// 5 liste con nomi realistici, lotti e scadenze, un prodotto ritirato e parafarmaci con immagine.
// uso: EMAIL=... PASSWORD=... node tools/dati-prova/crea_demo_screenshot.mjs [--scrivi] [--rifai]
const KEY = "AIzaSyC_b_V_x-40wEN7dRRSeMKHBIaqu3dlKso";
const PROJECT = "pharmabox-1c149";
const WORKER = "https://farmadati-proxy.gianluca-carta.workers.dev";
const FS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
const scrivi = process.argv.includes("--scrivi");
// rete instabile: fino a 4 tentativi, solo risposte JSON 2xx
async function json(url, init) {
  for (let t = 1; ; t++) {
    try {
      const r = await fetch(url, init);
      if (r.ok) return await r.json();
      if (t >= 4) throw new Error(`${url}: ${r.status} ${(await r.text()).slice(0, 200)}`);
    } catch (e) { if (t >= 4) throw e; }
    await new Promise((ok) => setTimeout(ok, 3000 * t));
  }
}

const LISTE = [ // nell'ordine in cui l'app le mostra (createdAt crescente)
  { nome: "Inventario ottobre", prodotti: 30, pezzi: [1, 9], lotti: 14, nonVendibili: 1 },
  { nome: "Banco OTC", prodotti: 20, pezzi: [1, 12] },
  { nome: "Magazzino", prodotti: 28, pezzi: [2, 24] },
  { nome: "Frigo", prodotti: 6, pezzi: [1, 4] },
  { nome: "Vetrina", prodotti: 12, pezzi: [1, 6] },
];
const rifai = process.argv.includes("--rifai");
const RICERCHE = ["TACHIPIRINA", "BRUFEN", "MOMENT", "VOLTAREN", "OKI", "ENTEROGERMINA", "FLUIMUCIL",
  "GAVISCON", "NUROFEN", "BUSCOPAN", "MAALOX", "IMODIUM", "BENAGOL", "VIVIN", "LASONIL", "BEPANTHENOL",
  "RINAZINA", "ACTIGRIP", "MUCOSOLVAN", "BRONCHENOLO", "XAMAMINA", "DICLOREUM", "SUPRADYN", "SPIDIFEN"];

let seme = 20261022;
const rnd = () => ((seme = (seme * 1103515245 + 12345) % 2 ** 31) / 2 ** 31);
const rand = (a, b) => a + Math.floor(rnd() * (b - a + 1));
const mescola = (a) => { for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
const autoId = () => Array.from({ length: 20 }, () => "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"[rand(0, 61)]).join("");
const chiaveCampo = (t) => [...Buffer.from(t, "utf8")].map((b) => /[A-Za-z0-9-]/.test(String.fromCharCode(b)) ? String.fromCharCode(b) : "_" + b.toString(16).padStart(2, "0").toUpperCase()).join("");
const iso = (d) => d.toISOString().slice(0, 10);
const ts = (d) => ({ timestampValue: d.toISOString() });

const login = await (await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${KEY}`, {
  method: "POST", headers: { "content-type": "application/json" },
  body: JSON.stringify({ email: process.env.EMAIL, password: process.env.PASSWORD, returnSecureToken: true }) })).json();
if (!login.idToken) throw new Error(`login: ${login.error?.message}`);
const h = { authorization: `Bearer ${login.idToken}` };
const esistenti = (await (await fetch(`${FS}/users/${login.localId}/liste?pageSize=100`, { headers: h })).json()).documents ?? [];
const nomiDemo = new Set(LISTE.map((l) => l.nome));
const altre = esistenti.filter((d) => !nomiDemo.has(d.fields?.nome?.stringValue));
if (altre.length) throw new Error(`l'account ha liste non demo: non lo tocco`);
if (esistenti.length && !rifai) throw new Error(`liste demo già presenti: usa --rifai per ricrearle`);
if (esistenti.length && scrivi) {
  // elimina le liste demo precedenti con i loro prodotti
  for (const d of esistenti) {
    const items = (await json(`https://firestore.googleapis.com/v1/${d.name}/items?pageSize=300`, { headers: h })).documents ?? [];
    const writes = [...items.map((i) => ({ delete: i.name })), { delete: d.name }];
    await json(`${FS}:commit`, { method: "POST", headers: { ...h, "content-type": "application/json" }, body: JSON.stringify({ writes }) });
  }
  console.log(`eliminate ${esistenti.length} liste demo precedenti`);
}

// prodotti reali, separati per esito di vendibilità
// Candidati con la vendibilità già nella cache condivisa del Worker: i primi
// 300 risultati delle ricerche e le prime 12 confezioni per ricerca (2 per
// marca), già verificati nei giri precedenti. Codici nuovi = attese su Farmadati.
const risultati = [];
for (const q of RICERCHE) risultati.push((await json(`${WORKER}/v1/prodotti?q=${q}`, { headers: h })).prodotti);
const candidati = new Map(risultati.flat().slice(0, 300).map((p) => [p.minsan, p.nome]));
const perMarcaGiaVisti = new Map();
for (const prodotti of risultati) {
  let presi = 0;
  for (const p of prodotti) {
    if (!p.minsan || !p.nome || presi >= 12) continue;
    const marca = p.nome.split(/[ *]/)[0];
    if ((perMarcaGiaVisti.get(marca) ?? 0) >= 2) continue;
    perMarcaGiaVisti.set(marca, (perMarcaGiaVisti.get(marca) ?? 0) + 1);
    candidati.set(p.minsan, p.nome);
    presi++;
  }
}
// liste varie (2 confezioni per marca) e niente codici di aggancio (7…, "VECCHIO=>NUOVO")
const pool = new Map();
const perMarca = new Map();
for (const [minsan, nome] of candidati) {
  if (!minsan || !nome || minsan.startsWith("7") || nome.includes("=>")) continue;
  const marca = nome.split(/[ *]/)[0];
  if ((perMarca.get(marca) ?? 0) >= 2) continue;
  perMarca.set(marca, (perMarca.get(marca) ?? 0) + 1);
  pool.set(minsan, nome);
}
const codici = [...pool.keys()];
const esiti = {};
for (let i = 0; i < codici.length; i += 20) {
  Object.assign(esiti, (await json(`${WORKER}/v1/vendibilita?codici=${codici.slice(i, i + 20).join(",")}`, { headers: h })).esiti);
}
const puliti = codici.filter((c) => esiti[c]?.provvedimenti?.length === 0);
const ritirati = codici.filter((c) => esiti[c]?.provvedimenti?.some((p) => p.stato === "RD" && p.data && p.data < "2025-01-01"));
console.log(`prodotti: ${codici.length}, senza provvedimenti ${puliti.length}, ritirati ${ritirati.length}`);
// parafarmaci con immagine già su R2 e senza provvedimenti: la scheda
// prodotto dello screenshot deve averne una
const CON_IMMAGINE = {
  "951882036": "BEPANTHENOL SENSIDERM CREMA50G",
  "980928396": "BEPANTHENOL TATTOO PASTA TRAT",
  "951873227": "BEPANTHENOL COLLIRIO 10ML",
  "900059991": "BEPANTHENOL PASTA LEN PROT100G",
};
const conImmagine = Object.keys(CON_IMMAGINE);
for (const [c, n] of Object.entries(CON_IMMAGINE)) { pool.set(c, n); if (!puliti.includes(c)) puliti.push(c); }
console.log(`parafarmaci con immagine: ${conImmagine.map((c) => pool.get(c)).join(", ")}`);

const oggi = new Date("2026-10-22T10:00:00Z");
const tra = (mesi, giorno) => new Date(Date.UTC(oggi.getUTCFullYear(), oggi.getUTCMonth() + mesi, giorno));
const codiceLotto = () => `${"ABCDEFGHKLMNPRSTW"[rand(0, 16)]}${rand(1, 9)}${rand(100, 999)}${"ABCDEF"[rand(0, 5)]}`;

const perNome = (a, b) => pool.get(a).localeCompare(pool.get(b));
for (const [i, l] of LISTE.entries()) {
  // due BEPANTHENOL con immagine solo nella lista principale, non quattro di fila ovunque
  let scelti = [...new Set([...(i === 0 ? conImmagine.slice(0, 2) : []), ...mescola(puliti.filter((c) => !conImmagine.includes(c)))])]
    .slice(0, l.prodotti - (l.nonVendibili ?? 0)).sort(perNome);
  if (l.nonVendibili) {
    // il ritirato tra le prime righe della lista ordinata per nome
    const r = [...ritirati].sort(perNome).find((c) => perNome(c, scelti[3]) < 0) ?? [...ritirati].sort(perNome)[0];
    scelti = [...scelti, r].sort(perNome);
  }
  const quando = new Date(oggi.getTime() - (LISTE.length - i) * 86_400_000);
  const id = autoId();
  const base = `projects/${PROJECT}/databases/(default)/documents/users/${login.localId}/liste/${id}`;
  let totale = 0;
  const items = scelti.map((minsan, k) => {
    const fields = { minsan: { stringValue: minsan }, titolo: { stringValue: pool.get(minsan) }, updatedAt: ts(quando) };
    let quantita = rand(...l.pezzi);
    // lotti sulle righe visibili per prime: in scadenza, due lotti, prossima
    const posLotti = [0, 2, 4, 6, 9, 12, 15, 18, 21, 24, 27].slice(0, l.lotti ?? 0);
    if (posLotti.includes(k) && !ritirati.includes(minsan)) {
      const n = k === 2 || k % 3 === 0 ? 2 : 1;
      const lotti = {};
      quantita = 0;
      for (let j = 0; j < n; j++) {
        const mesi = k === 0 ? 1 + j : k === 4 ? 4 + j * 6 : rand(8, 30) + j * 6;
        const scad = tra(mesi, mesi < 3 ? 28 : 1);
        const lotto = codiceLotto();
        const q = rand(1, 5);
        quantita += q;
        lotti[chiaveCampo(`${lotto}|${iso(scad)}`)] = { mapValue: { fields: {
          lotto: { stringValue: lotto }, scadenza: { stringValue: iso(scad) }, quantity: { integerValue: String(q) } } } };
      }
      fields.lotti = { mapValue: { fields: lotti } };
    }
    fields.quantity = { integerValue: String(quantita) };
    totale += quantita;
    return { update: { name: `${base}/items/${minsan}`, fields } };
  });
  const writes = [{ update: { name: base, fields: {
    nome: { stringValue: l.nome }, totalePezzi: { integerValue: String(totale) }, createdAt: ts(quando), updatedAt: ts(quando) } } }, ...items];
  console.log(`- ${l.nome}: ${items.length} prodotti, ${totale} pezzi${scrivi ? "" : " (prova)"}`);
  if (scrivi) {
    const r = await fetch(`${FS}:commit`, { method: "POST", headers: { ...h, "content-type": "application/json" }, body: JSON.stringify({ writes }) });
    if (!r.ok) throw new Error(`${l.nome}: ${r.status} ${await r.text()}`);
  }
}
