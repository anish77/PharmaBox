// DataMatrix GS1 di prova dell'AIC 040295141 (scadenze, lotti e seriali
// diversi): stessi codici di test/ble_simulator_test.dart e di
// integration_test/datamatrix_scadenze_test.dart.
//
//   cd tool/datamatrix && npm install && node genera.js
//
// Scrive i PNG e index.html (da aprire nel browser e scansionare a schermo)
// in docs/datamatrix_esempi. bwip-js non conosce ancora l'AI 716 (AIC):
// dontlint salta solo il controllo degli AI, la codifica resta GS1 con FNC1.
// Il GTIN è fittizio, costruito come quelli del simulatore dell'app.
const bwipjs = require('bwip-js');
const fs = require('fs');
const path = require('path');
const out = process.argv[2] || path.join(__dirname, '../../docs/datamatrix_esempi');
fs.mkdirSync(out, { recursive: true });
const aic = '040295141';
const base = '0803208' + aic.substring(3);
let s = 0;
for (let k = 0; k < base.length; k++) { const d = +base[base.length-1-k]; s += k % 2 === 0 ? d*3 : d; }
const gtin = base + ((10 - s % 10) % 10);
const casi = [
  ['1', '260915', 'LA01', 'SN7K2M9QX4PA', 'Scaduta il 15/09/2026 (rosso)'],
  ['2', '261120', 'LB02', 'SN3HD8W2RT6B', 'Scade il 20/11/2026: entro 3 mesi (arancione)'],
  ['3', '270300', 'LC03', 'SN9PL4ZE7VJC', 'Giorno 00 → 31/03/2027: entro 6 mesi (ocra)'],
  ['4', '280615', 'LD04', 'SN5TQ2NB8XKD', 'Giorno preciso 15/06/2028 (verde)'],
  ['5', '280615', 'LD04', 'SN2WF6YC3MHE', 'Stesso lotto e scadenza del 4, altro seriale: si somma (2 pz)'],
  ['6', '280600', 'LD04', 'SN8RJ5UA4GLF', 'Stesso lotto del 4, giorno 00 → 30/06/2028: lotto separato'],
  ['7', '280615', 'LD07', 'SN4CV7HN2QWG', 'Stessa scadenza del 4, altro lotto: stessa data, due lotti'],
  ['8', '280615', 'LD04', 'SN5TQ2NB8XKD', 'Stesso seriale del 4: deve dire "già contata"'],
];
(async () => {
const righe = [];
for (const [n, scad, lotto, ser, nota] of casi) {
  const text = `(01)${gtin}(17)${scad}(10)${lotto}(21)${ser}(716)${aic}`;
  const png = await bwipjs.toBuffer({ bcid: 'gs1datamatrix', text, dontlint: true, scale: 6, padding: 4, backgroundcolor: 'FFFFFF' });
  fs.writeFileSync(`${out}/${n}_${scad}_${ser}.png`, png);
  righe.push({ n, text, nota, b64: png.toString('base64') });
  console.log(n, text);
}
const html = `<!doctype html><html lang="it"><head><meta charset="utf-8"><title>DataMatrix 040295141</title>
<style>body{font-family:-apple-system,sans-serif;margin:24px;background:#fff;color:#1b2340}
.g{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:24px}
.c{border:1px solid #ccd;border-radius:10px;padding:16px;text-align:center;break-inside:avoid}
img{width:180px;image-rendering:pixelated}code{font-size:11px;word-break:break-all;display:block;margin-top:8px}
h1{font-size:20px}p{margin:6px 0;font-weight:600}</style></head><body>
<h1>AIC 040295141 · GTIN ${gtin} (fittizio)</h1><div class="g">
${righe.map(r => `<div class="c"><img src="data:image/png;base64,${r.b64}"><p>${r.n}. ${r.nota}</p><code>${r.text}</code></div>`).join('\n')}
</div></body></html>`;
fs.writeFileSync(`${out}/index.html`, html);
})();
