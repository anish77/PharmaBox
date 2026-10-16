// Controlla le liste di un utente: per ognuna numero di prodotti, totale
// salvato (totalePezzi) e somma reale delle quantità. Sola lettura.
// Uso: EMAIL=... PASSWORD=... node verifica_liste.mjs

const KEY = "AIzaSyCySHo0x1vZqzXhRWuQBrYJqlgnpQwozwE";
const FS = "https://firestore.googleapis.com/v1/projects/pharmabox-1c149/databases/(default)/documents";
const r = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${KEY}`, {
  method: "POST", headers: { "content-type": "application/json" },
  body: JSON.stringify({ email: process.env.EMAIL, password: process.env.PASSWORD, returnSecureToken: true }) });
const { localId: uid, idToken } = await r.json();
const h = { authorization: `Bearer ${idToken}` };
const liste = (await (await fetch(`${FS}/users/${uid}/liste?pageSize=300`, { headers: h })).json()).documents ?? [];
for (const d of liste) {
  const items = (await (await fetch(`${d.name.replace(/^projects\/[^/]+\/databases\/\(default\)\/documents/, FS)}/items?pageSize=300`, { headers: h })).json()).documents ?? [];
  const somma = items.reduce((s, i) => s + Number(i.fields.quantity.integerValue), 0);
  const tot = Number(d.fields.totalePezzi.integerValue);
  console.log(`${d.fields.nome.stringValue.padEnd(20)} prodotti=${String(items.length).padStart(3)} pezzi=${tot} somma=${somma} ${somma === tot ? "OK" : "DIVERSO"}`);
}
