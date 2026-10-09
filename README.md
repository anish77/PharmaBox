# PharmaBox

App Flutter per l'inventario in farmacia: si leggono i prodotti con uno scanner
Bluetooth, si organizzano in liste e si esportano in PDF o CSV.

## Funzionalità

- **Account** con Firebase Authentication: registrazione, login, recupero password.
- **Liste di inventario** salvate su Cloud Firestore, sincronizzate in tempo reale
  tra più telefoni collegati allo stesso account.
- **Scanner Bluetooth** (`BarCode Scanner BLE`): ogni lettura aggiunge un pezzo
  alla lista aperta. In alternativa, ricerca manuale e contatore.
- **Ricerca prodotti** per nome, EAN o MINSAN tramite servizio SOAP, con scheda
  prodotto e bugiardino.
- **Export** delle liste selezionate in PDF o CSV, con nome file, nome farmacia
  e totale pezzi.
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
  logic/                     ricerca SOAP, apertura email
  models/prodotto.dart       modello prodotto
  view/                      schermate
  widgets/                   componenti riutilizzabili; carrello.dart è la
                             copia locale della lista aperta
```

## Dati su Firestore

```
users/{uid}                                dati account, codiceInvito, UID_BLE
users/{uid}/liste/{idLista}                nome, totalePezzi, createdAt, updatedAt
users/{uid}/liste/{idLista}/items/{minsan} minsan, titolo, quantity, updatedAt
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

## Test

```bash
flutter test test/liste_repository_test.dart
```

I test di `ListeRepository` usano `fake_cloud_firestore` e non toccano i dati
reali. Coprono liste, prodotti, incrementi concorrenti e migrazione.
`test/widget_test.dart` è ancora il test d'esempio generato da Flutter e
fallisce.

## Branch

- `main`: ramo principale
- `in-app-purchase`: sviluppo corrente (abbonamenti, liste su sottocollezioni)
