# Manuale utente PharmaBox

Edizione italiana del 12 ottobre 2026, riferita alla versione 1.0.2+2.

- [Manuale PDF](Manuale-PharmaBox.pdf): pronto da consultare, stampare o condividere, con indice e segnalibri.
- [Manuale HTML](Manuale-PharmaBox.html): file autonomo, con indice cliccabile e screenshot incorporati. Non richiede un server né una connessione.
- [Sorgente Markdown](Manuale-PharmaBox.md): testo modificabile, con collegamenti agli screenshot originali.
- [Screenshot](screenshots/): 23 acquisizioni PNG dall'emulatore Android.

Le immagini sono catture reali dell'app installata, non ricostruzioni grafiche.
I dati mostrati appartengono alle liste di prova dell'ambiente. Per accesso e
cambio email sono stati modificati soltanto i campi non inviati, senza salvare
nuove credenziali né modificare l'indirizzo dell'account. L'appendice del manuale
distingue le schermate percorse dalle operazioni non collaudate.

## Rigenerare PDF e HTML

Dalla radice del repository, con Python 3.10 o successivo:

```powershell
python -m pip install -r tools/manuale/requirements.txt
python tools/manuale/build.py
```

Il generatore usa il Markdown, gli screenshot e i font Roboto già presenti in
`assets/fonts`. Non modifica il codice dell'app. I file generati vengono
sovrascritti: aggiornare il Markdown, non direttamente il PDF o l'HTML.

## Acquisire una schermata aggiornata

Aprire la schermata desiderata nell'app Android. Il programma usa ADB nell'SDK
Android standard dell'utente Windows. Indicare il dispositivo se diverso da
quello usato per questa edizione:

```powershell
$env:ANDROID_SERIAL = 'emulator-5556'
python tools/manuale/capture.py ui
python tools/manuale/capture.py shot 04-liste
```

`ui` elenca le etichette visibili e la posizione dei controlli; può contenere dati
personali presenti sullo schermo, quindi non salvarne l'output nel repository.
`shot` acquisisce il display intero. Verificare sempre app in primo piano, stato
del caricamento e dati visibili prima di includere una nuova immagine.

Gli altri comandi disponibili sono `tap X Y`, `swipe X1 Y1 X2 Y2`, `text TESTO`
e `back`. Le coordinate fanno riferimento a un display di 448 × 997 e vengono
adattate alla risoluzione dell'emulatore. Non usare azioni di acquisto,
eliminazione o invio di email per ottenere semplici screenshot.
