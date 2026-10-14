# Lettura del DataMatrix dei farmaci

PharmaBox legge il GS1 DataMatrix delle confezioni di medicinali e ne usa
scadenza, lotto e seriale nelle liste di inventario. Il bollino (Code 32) e
l'EAN continuano a funzionare come prima.

## Normativa e contenuto del codice

- D.Lgs. 6 febbraio 2025, n. 10, che recepisce il Reg. delegato UE 2016/161
  (Falsified Medicines Directive).
- DM Salute 6 marzo 2025 (GU n. 84 del 10/04/2025): specifiche tecniche.
- Periodo di stabilizzazione: dal 9 febbraio 2025 all'8–9 febbraio 2027. Fino
  ad allora si vendono ancora confezioni con il bollino. Anche dopo, i farmaci
  senza obbligo di ricetta e i parafarmaci non hanno il DataMatrix, quindi
  l'app deve leggere tutti e tre i codici.

| AI | Campo | Formato | In chiaro sulla confezione |
|---|---|---|---|
| (01) | GTIN | 14 cifre, fisso | PC |
| (17) | Scadenza | AAMMGG, fisso | SCAD |
| (10) | Lotto | fino a 20 caratteri | LOTTO |
| (21) | Seriale | fino a 20 caratteri | SN |
| (716) | AIC (= MINSAN) | 9 cifre, la prima è 0 | AIC |

Esempio di lettura (GS = carattere ASCII 29):

```
]d2 01 08032089000017 17 280300 10 L1234 <GS> 21 SN9X7Q2K <GS> 716 012745182
```

Regole applicate:

- **Giorno 00**: è l'ultimo giorno del mese (`280300` = 31/03/2028).
- **Secolo** dell'anno secondo la regola GS1: da -49 a +50 anni rispetto
  all'anno corrente.
- **Ordine dei campi**: non è garantito; il parser legge per AI.
- **GS**: chiude i campi a lunghezza variabile che non sono gli ultimi.
- **Cifre di controllo** verificate su GTIN (mod 10 GS1) e AIC (stesso
  algoritmo del Code 32).

Fonti: [GS1 Italy](https://gs1it.org/settori/sanitario-healthcare/farmaci-con-standard-gs1/),
[Farmacista33](https://www.farmacista33.it/aggiornamento-professionale/31012/data-matrix-farmaci-cosa-legge-il-farmacista-e-il-lettore-ottico-ecco-gli-elementi-del-nuovo-codice.html),
[Quotidiano Sanità](https://www.quotidianosanita.it/governo-e-parlamento/articolo.php?articolo_id=129020).

## Dallo scanner alla lista

```
notifiche BLE ──> AssemblatoreBle ──> bleDecode ──> interpretaLettura ──> scannedBarcodeProvider
 (pezzi da 20 B)   (ricompone fino a   (byte->testo)  (DataMatrix o        (LetturaScanner)
                    CR/LF o 80 ms)                     bollino/EAN)
```

1. **`AssemblatoreBle`** (`lib/include/ble_functions.dart`): un DataMatrix
   (45–70 caratteri) arriva spezzato in più notifiche. I pezzi si accumulano
   fino al terminatore CR/LF o a 80 ms di silenzio. Il pacchetto da 17 byte
   del bollino passa subito, come prima.
2. **`parseGs1`** (`lib/include/gs1_datamatrix.dart`) accetta:
   - prefisso AIM `]d2` (e scarta ciò che lo precede);
   - FNC1 iniziale, GS anche scritto come `<GS>`;
   - formato leggibile `(01)…(17)…`.
3. **Senza GS** (scanner non configurato) prova tutte le divisioni possibili
   dei campi variabili:
   - dentro un campo variabile possono iniziare solo gli AI dei farmaci (01,
     17, 10, 21, 710–716): un seriale casuale con "22" o "30" non moltiplica
     le interpretazioni;
   - vince l'interpretazione con più campi validi;
   - se ne restano più d'una, i campi su cui non concordano diventano null e
     la confezione è segnata `ambigua`.
4. **`interpretaLettura`** (`lib/include/lettura_scanner.dart`) produce una
   `LetturaScanner`:
   - `codice`: l'AIC, oppure l'EAN-13 ricavato dal GTIN;
   - `confezione`: i dati del DataMatrix.
   Per tutto il resto applica `tradCode` come prima.
5. **`SelectedListPage._handleScannedCode`** cerca il prodotto. Se l'AIC non
   è su Farmadati riprova con l'EAN. Poi aggiunge il pezzo con lotto,
   scadenza e seriale e mostra gli avvisi:
   - confezione scaduta: avviso rosso e vibrazione;
   - scadenza entro la soglia arancione (3 mesi, da Opzioni): avviso arancione;
   - seriale già in lista: "Confezione già contata", con **Conta di nuovo**;
   - lettura ambigua: invito a configurare lo scanner per il GS.

### Configurazione dello scanner

Serve uno scanner **2D a immagine**: i laser 1D leggono il bollino ma non il
DataMatrix. Sullo scanner vanno attivati:

- la simbologia DataMatrix;
- la trasmissione dell'FNC1 come GS (ASCII 29);
- se possibile, il prefisso AIM (`]d2`).

Il formato dei pacchetti BLE oltre i 17 byte va ancora verificato con lo
scanner vero: i byte grezzi compaiono nel log come `BLE ricevuto`.

## Dati su Firestore

Nel documento `users/{uid}/liste/{idLista}/items/{minsan}`, solo per i pezzi
letti da DataMatrix:

```
lotti.{chiave}    lotto, scadenza ('AAAA-MM-GG'), quantity
seriali.{chiave}  seriale
```

- **Scritture**: `ListeRepository.incrementa(..., confezione:)` usa un batch
  con `FieldValue.increment`. Niente transazione, quindi funziona offline e
  con più telefoni insieme.
- **Chiavi**: passano da `chiaveCampo`. Lotti e seriali possono contenere `.`
  e `/`, che sono vietati nei nomi dei campi: questi caratteri diventano
  `_XX`, senza collisioni.
- **Scadenza**: salvata come testo `AAAA-MM-GG`, per evitare problemi di fuso
  orario.
- **Quantità a 0**: `impostaQuantita` cancella anche `lotti` e `seriali`, così
  le confezioni rilette vengono contate di nuovo.
- **Pezzi senza scadenza**: quelli aggiunti dal bollino o a mano non hanno
  lotto. La somma dei lotti può quindi essere minore di `quantity`.
- **Doppioni**: `Carrello` tiene i seriali in memoria e rifiuta subito una
  confezione già contata, anche offline.

## Interfaccia

- **Etichetta di scadenza** (`lib/widgets/scadenza_chip.dart`): nella lista
  mostra la scadenza più vicina con il numero di lotti. Colori:
  - rosso: scaduto;
  - arancione: entro 3 mesi;
  - ocra: entro 6 mesi;

  Le due soglie si cambiano in Opzioni (menu laterale), solo per il
  dispositivo; lì si possono anche spegnere gli avvisi alla lettura, tranne
  "già contata".
  - verde: oltre.

  Toccandola si apre sotto il prodotto l'elenco delle scadenze, ognuna con
  il totale e tutti i suoi lotti; in fondo i pezzi senza scadenza.
- **Ordinamento**: nella lista compare "Ordinati per nome / per scadenza"
  quando almeno un prodotto ha una scadenza.
- **Export PDF e CSV**: nuova colonna **Scadenza**, con la scadenza più
  vicina.

## DataMatrix di prova

In `docs/datamatrix_esempi/` ci sono 8 DataMatrix GS1 dell'AIC 040295141 da
scansionare a schermo (`index.html`) o stampare: scaduta, in scadenza, giorno
00, giorno preciso, stesso lotto con altro seriale, stesso lotto con altra
scadenza, stessa scadenza con altro lotto e seriale ripetuto ("già contata").
Sono gli stessi codici dei test in `test/ble_simulator_test.dart` e di
`integration_test/datamatrix_scadenze_test.dart`, che legge le confezioni dal
simulatore e salva gli screenshot:

```
SCREEN_DIR=screenshots/datamatrix flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/datamatrix_scadenze_test.dart -d <device> \
  --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
```

Per rigenerarli: `cd tool/datamatrix && npm install && node genera.js`.

## Simulatore (solo debug)

Nella pagina di una lista, l'icona **Simula lettura Bluetooth**:

- **Inserisci DataMatrix di esempio**: 6 confezioni dei primi MINSAN, con
  scadenze diverse:
  - scaduta;
  - entro 3 mesi;
  - entro 6 mesi;
  - lontane.

  I seriali sono nuovi a ogni pressione.
- **Componi DataMatrix…**: si sceglie prodotto, scadenza (scelte rapide con
  giorno 00 o una data dal calendario), lotto e seriale.
- **DataMatrix senza separatore GS**: simula uno scanner non configurato.
- **Già contata**: ripetendo la stessa lettura (Recenti o Ripetizioni) si
  prova l'avviso.

I DataMatrix simulati fanno il percorso di una lettura vera
(`BleSimulator.letturaDataMatrix`):

1. Il testo viene trasmesso con `componiGs1`.
2. Viene spezzato in notifiche da 20 byte.
3. Passa da `AssemblatoreBle`, `bleDecode` e `interpretaLettura`.

## Test

| File | Cosa verifica |
|---|---|
| `test/gs1_datamatrix_test.dart` | Cifre di controllo, date (giorno 00, secolo), formati di ingresso, letture senza GS, ambiguità |
| `test/lettura_datamatrix_ble_test.dart` | Riassemblaggio delle notifiche, pacchetto del bollino invariato, stati di scadenza |
| `test/liste_repository_test.dart` | Lotti e seriali su Firestore, azzeramento, `chiaveCampo` |
| `test/ble_simulator_test.dart` | Esempi del simulatore attraverso la catena BLE, con e senza GS |
| `test/scadenza_chip_test.dart` | Etichetta di scadenza ed elenco lotti |

## Da fare

- **Prova con uno scanner 2D reale**: verificare il formato dei pacchetti BLE
  oltre i 17 byte.
- **Lotti ritirati per singolo lotto**: il Worker oggi restituisce di TR012
  solo stato e data. Bisogna individuare il campo Farmadati con il numero di
  lotto ed esporlo.
- **Scadenza inserita a mano** per le confezioni senza DataMatrix.
- **Lettura con la fotocamera** (`mobile_scanner`) per chi non ha lo scanner.
