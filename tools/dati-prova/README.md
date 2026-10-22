# Dati di prova

Script Node.js (18 o successivo, nessuna dipendenza) per riempire di liste
realistiche l'account PharmaBox di un tester. Scrivono su Firestore con la
stessa struttura dell'app (`users/{uid}/liste/{id}` e `items/{minsan}`) e
prendono nomi e MINSAN reali da Farmadati tramite il Worker `farmadati-proxy`.

Le credenziali si passano solo da riga di comando: non vanno scritte nei file.
Senza `--scrivi` ogni script mostra cosa farebbe senza modificare nulla.

| Script | Cosa fa |
|---|---|
| `crea_liste.mjs` | Crea liste nuove; quelle con lo stesso nome vengono saltate. |
| `aggiungi_pezzi.mjs` | Aggiunge pezzi a liste esistenti, in parte su prodotti già presenti e in parte su MINSAN nuovi, con incrementi atomici come l'app. |
| `modifiche_casuali.mjs` | Simula il lavoro di un operatore: cancella 2–3 liste (con i prodotti), ne rinomina 3–4 e in altre 2–3 toglie prodotti e cambia quantità, tenendo coerente il totale. Con lo stesso `SEED` ripete le stesse scelte. |
| `verifica_liste.mjs` | Sola lettura: per ogni lista confronta il totale salvato con la somma delle quantità. |
| `crea_demo_screenshot.mjs` | Prepara l'account demo degli screenshot App Store: 5 liste con nomi realistici, lotti e scadenze, un prodotto ritirato e parafarmaci con immagine. Sceglie solo prodotti con la vendibilità già nella cache del Worker; `--rifai` ricrea le liste demo e si ferma se l'account ha altre liste. Poi `tool/screenshot_app_store.sh`. |

## Esempi (PowerShell)

```powershell
$env:EMAIL = 'tester@example.com'; $env:PASSWORD = '...'

# 3 liste con 40 MINSAN e 124 pezzi ciascuna: prima la prova, poi la scrittura
$env:NOMI = 'Banco ingresso,Retro scaffale C,Retro frigo 2'
$env:PRODOTTI = 40; $env:PEZZI_MIN = 124; $env:PEZZI_MAX = 124
node tools/dati-prova/crea_liste.mjs
node tools/dati-prova/crea_liste.mjs --scrivi

# 20 pezzi in più per ognuna delle liste indicate
$env:PEZZI = 20
node tools/dati-prova/aggiungi_pezzi.mjs --scrivi

node tools/dati-prova/verifica_liste.mjs
```

Valori predefiniti di `crea_liste.mjs`: 10 liste "Banco …" / "Retro …",
60 MINSAN per lista, tra 100 e 230 pezzi per lista. I pezzi sono distribuiti
come in un inventario reale: pochi prodotti con molti pezzi, molti con 1–3.

L'account deve esistere e avere l'email verificata. Le liste create sono
dati veri dell'account: per toglierle usare l'app (scorrere la lista verso
sinistra) o la console Firebase.
