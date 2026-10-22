# farmadati-proxy

Worker Cloudflare tra l'app PharmaBox e Farmadati. L'app non chiama più
Farmadati: chiama questo Worker, che interroga Farmadati e salva le risposte in
una cache **condivisa tra tutti gli utenti** (D1). Le credenziali Farmadati
stanno solo qui, come secret.

## API

Tutte `GET`, con header `Authorization: Bearer <ID token Firebase>`.

| Rotta | Risposta |
|---|---|
| `/v1/prodotti?q=` | `{prodotti: [{codice, minsan, nome, categoria}]}`. `q` può essere un nome, un codice ministeriale o un EAN (più di 9 cifre) |
| `/v1/vendibilita?codici=a,b,c` | `{esiti: {codice: {lotto, provvedimenti: [{stato, data, motivo, esaurimento}]} \| {errore: true}}}`, massimo 50 codici; `lotto` (primo record o null) resta per le versioni precedenti dell'app |
| `/v1/rendibilita?codice=` | `{trovato, codice}` (codice FDI_0460) |
| `/v1/immagine?codice=` | `{url}`: URL CDN su R2, oppure null (anche se TDZ indica un file che Farmadati non ha). L'ingest passa dal service binding `R2_INGEST` verso `pharmabox-r2-ingest` |
| `/v1/bugiardino?codice=&tipo=F` | `{url}`: copia su doublecore, oppure un link firmato `/v1/doc` valido per un'ora |
| `/v1/doc?tipo=&nome=&exp=&sig=` | inoltra il documento Farmadati senza esporre l'accesskey (senza token, firmato HMAC) |

## Cache

| Dato | Durata | Dopo la scadenza |
|---|---|---|
| Anagrafica per codice, EAN | 30 giorni | risponde col dato vecchio e lo aggiorna in background |
| Ricerca per nome | 7 giorni | come sopra |
| Immagine (URL R2), bugiardino | 90 / 30 giorni | come sopra |
| Rendibilità | 7 giorni | come sopra |
| Lotti invendibili (TR012) | 12 ore | aspetta il dato nuovo; il vecchio solo se Farmadati non risponde |

Inoltre:
- si salvano anche le risposte vuote;
- le chiavi sono in maiuscolo (`CONTIENE` di Farmadati non distingue maiuscole e minuscole);
- una ricerca per nome viene ricavata filtrando una ricerca più corta già in cache, se questa ha meno di 100 risultati;
- al massimo 6 chiamate contemporanee a Farmadati per isolate.

## Sviluppo

```sh
npm install
npm test                       # vitest
npm run typecheck
cp .dev.vars.example .dev.vars # e compilare i valori
npm run db:migrate:local
npm run dev                    # http://localhost:8787
```

App sull'emulatore Android contro il Worker locale:

```sh
flutter run --dart-define=FARMADATI_PROXY=http://10.0.2.2:8787
```

## Deploy

```sh
npx wrangler login
npx wrangler d1 create farmadati-cache   # copiare database_id in wrangler.toml
npm run db:migrate:remote
npx wrangler secret put FARMADATI_USERNAME
npx wrangler secret put FARMADATI_PASSWORD
npx wrangler secret put R2_API_KEY
npx wrangler secret put DOC_SIGNING_KEY  # stringa casuale lunga
npm run deploy
```

Dopo il deploy, impostare l'URL del Worker come `defaultValue` di
`kFarmadatiProxyEndpoint` in `lib/data/constants.dart`.
