# PharmaBox

App Flutter per l'inventario in farmacia: si leggono i prodotti con uno scanner
Bluetooth, si organizzano in liste e si esportano in PDF o CSV.

## Manuale utente

La guida completa in italiano, con screenshot e procedure dalla registrazione
all'esportazione, è disponibile in [PDF](docs/manuale-utente/Manuale-PharmaBox.pdf),
[HTML](docs/manuale-utente/Manuale-PharmaBox.html) e
[Markdown](docs/manuale-utente/Manuale-PharmaBox.md).
Le [istruzioni di aggiornamento](docs/manuale-utente/README.md) spiegano come
rigenerare il manuale e acquisire nuove schermate.

## Funzionalità

- **Account** con Firebase Authentication: registrazione, login, recupero password.
- **Liste di inventario** salvate su Cloud Firestore, sincronizzate in tempo reale
  tra più telefoni collegati allo stesso account.
- **Scanner Bluetooth**: lo scanner si sceglie da una schermata che elenca i
  dispositivi BLE vicini (`BarCode Scanner BLE` in evidenza). Sono supportati gli
  scanner che espongono il servizio GATT `FEEA` o `FFF0`; ogni lettura aggiunge
  un pezzo alla lista aperta. In alternativa, ricerca manuale e contatore.
- **DataMatrix dei farmaci** (GS1, obbligatorio dal febbraio 2027): dalla
  lettura si ricavano AIC, scadenza, lotto e seriale. La lista mostra la
  scadenza più vicina e si può ordinare per scadenza. Alla lettura compaiono
  avvisi per confezioni scadute o in scadenza, e una confezione già contata
  non viene contata due volte. Dettagli in [docs/datamatrix.md](docs/datamatrix.md).
- **Ricerca prodotti** per nome, EAN o MINSAN tramite servizio SOAP, con scheda
  prodotto e bugiardino.
- **Export** delle liste selezionate in PDF o CSV, con nome file, nome farmacia,
  totale pezzi e scadenza più vicina.
- **Abbonamento** gestito con RevenueCat (entitlement `Premium`).
- **Invita un amico** con codice invito personale.

## Requisiti

- Flutter 3.35 o successivo (Dart SDK `^3.7.2`)
- Android Studio con Android SDK, oppure Xcode per iOS
- Un dispositivo reale per provare scanner e acquisti: sull'emulatore il
  Bluetooth e Google Play Billing non sono disponibili

## Avvio

```bash
flutter pub get
flutter run
```

La configurazione Firebase è già nel repository
(`lib/firebase/firebase_options.dart`, `android/app/google-services.json`,
`ios/Runner/GoogleService-Info.plist`). Le chiavi RevenueCat sono in
`lib/data/constants.dart`.

Su iOS, dopo aver cambiato dipendenze: `cd ios && pod install`.

In `android/gradle.properties` sono presenti i flag aggiunti dal migratore
Flutter `android.builtInKotlin=false` e `android.newDsl=false`: disabilitano
Kotlin integrato e la nuova DSL Android per mantenere la configurazione attuale.

## Struttura del codice

```
lib/
  main.dart                  avvio: Firebase, RevenueCat, provider globali BLE
  data/                      costanti (colori, chiavi) e dati in cache
  firebase/
    firebase_logic.dart      dati utente (es. autorizzazione scanner UID_BLE)
    liste_repository.dart    tutte le operazioni su liste e prodotti
  features/subscribtions/    stato abbonamento e offerte (Bloc + RevenueCat)
  include/ble_functions.dart connessione e letture dello scanner Bluetooth
  include/gs1_datamatrix.dart parser del GS1 DataMatrix (AIC, scadenza, lotto)
  include/lettura_scanner.dart lettura dello scanner -> codice da cercare
  logic/                     ricerca SOAP, apertura email
  models/prodotto.dart       modello prodotto
  models/lotto_confezione.dart lotti e scadenze letti dai DataMatrix
  view/                      schermate
  widgets/                   componenti riutilizzabili; carrello.dart è la
                             copia locale della lista aperta
```

## Dati su Firestore

```
users/{uid}                                dati account, UID_BLE
users/{uid}/liste/{idLista}                nome, totalePezzi, createdAt, updatedAt
users/{uid}/liste/{idLista}/items/{minsan} minsan, titolo, quantity, updatedAt,
                                           lotti, seriali (solo da DataMatrix)
```

- Ogni lista e ogni prodotto è un documento separato: più telefoni possono
  leggere prodotti in contemporanea senza sovrascriversi.
- Le letture dello scanner usano `FieldValue.increment`, insieme al totale della
  lista, quindi nessun pezzo va perso.
- Un prodotto portato a 0 pezzi resta nella lista; si elimina solo con la
  rimozione esplicita.
- Le scritture non vengono attese: offline restano in coda e l'interfaccia si
  aggiorna subito dalla cache locale.
- Leggere e scrivere liste solo tramite `ListeRepository`, non direttamente
  su Firestore.

### Migrazione dal vecchio formato

Le versioni precedenti salvavano le liste nell'array `liste` del documento
utente. Al primo accesso alla home, `ListeRepository.migraListeLegacy` copia
quelle liste nelle sottocollezioni e imposta `listeMigrate: true`. Il vecchio
array resta come backup; se la migrazione si interrompe viene ripetuta al login
successivo senza creare doppioni. I nuovi account nascono già migrati.

## Debug: simulatore scanner

Nelle build di debug, nella pagina di una lista c'è un'icona per simulare le
letture dello scanner (`lib/widgets/ble_simulator.dart`): si inseriscono uno o
più codici, il numero di ripetizioni e il ritardo. Serve a provare liste e
sincronizzazione senza lo scanner fisico. Nelle build di release non compare.

Per provare una sequenza pronta:

1. Aprire una lista e il dialogo **Simula lettura Bluetooth**.
2. Premere **Inserisci 30 MINSAN di esempio**: sostituisce il contenuto del
   campo Codici con i 30 codici definiti in `BleSimulator.minsanEsempio`.
   Il campo mostra fino a cinque righe; i codici restano modificabili.
3. Impostare **Ripetizioni** e **Ritardo (ms)**, poi premere **Simula**.
   Ogni ripetizione invia l'intera sequenza, quindi 2 ripetizioni producono
   60 letture. Il ritardo iniziale è 500 ms.

Si possono anche inserire codici scanner di 6 caratteri o MINSAN di 9 cifre,
separati da spazi, virgole, punti e virgola o a capo. I codici scanner vengono
convertiti in MINSAN con `tradCode`; i MINSAN sono inviati direttamente al
provider delle letture. Durante la sequenza, il pulsante di arresto permette
di interromperla. Gli ultimi otto codici sono disponibili per letture singole.

**DataMatrix**: **Inserisci DataMatrix di esempio** aggiunge 6 confezioni con
scadenze diverse. **Componi DataMatrix…** permette di scegliere prodotto,
scadenza, lotto e seriale. La casella **DataMatrix senza separatore GS** simula
uno scanner non configurato. I DataMatrix passano dalla stessa catena BLE delle
letture vere: notifiche da 20 byte, riassemblaggio e decodifica. Vedi
[docs/datamatrix.md](docs/datamatrix.md).

Il simulatore usa il normale flusso della lista: le letture possono aggiornare
i dati dell'account collegato. Per le prove usare una lista dedicata.

## Test

```bash
flutter test test/liste_repository_test.dart
flutter test test/ble_simulator_test.dart
flutter test test/lettura_minsan_test.dart
flutter test test/gs1_datamatrix_test.dart test/lettura_datamatrix_ble_test.dart
flutter test test/scadenza_chip_test.dart
```

I test di `ListeRepository` usano `fake_cloud_firestore` e non toccano i dati
reali. Coprono liste, prodotti, incrementi concorrenti, migrazione, lotti e
seriali da DataMatrix.
I test del simulatore controllano i 30 codici di esempio, il formato a 9 cifre
e la conversione reversibile MINSAN/Code 32. I test di lettura verificano anche
la decodifica dei pacchetti BLE; le ricerche sul servizio Farmadati reale sono
disattivate per impostazione predefinita. Per abilitarle:

```bash
flutter test --dart-define=ONLINE=true test/lettura_minsan_test.dart
```

`test/widget_test.dart` è ancora il test d'esempio generato da Flutter e
fallisce.

## Branch

- `main`: ramo principale
- `in-app-purchase`: sviluppo corrente (abbonamenti, liste su sottocollezioni)
