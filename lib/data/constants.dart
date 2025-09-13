import 'package:flutter/widgets.dart';

const kAppName = 'PharmaBox';
const kLogo = 'assets/Logo.png';
const kNoImage = 'assets/noImage.png';
const kScanCode = 'assets/scanCode.png';
const kNotAuthorized = 'assets/lock.png';

//colors
const kPrimary = Color(0xFF5D5FEF);
const kSecondary = Color(0xFFE5E6FF);
const kBackGround = Color(0xFFF5F7FA);
const kBluScuro = Color(0xFF2B2D66);
const kWarning = Color(0xFFE59700);
const kGreen = Color(0xFF0B8E63);
const kRed = Color(0xFFC6180B);
const kWhite = Color(0xFFFFFFFF);
const kYellow = Color(0x33F8BB45);

//messages
const kNomeError = 'Il nome non deve essere vuoto';
const kCognomeError = 'Il cognome non deve essere vuoto';
const kEmailError = 'Inserisci un email corretto';
const kPasswordError =
    'La Password deve avere almeno 8 caratteri, \nuna lettera maiuscola, \nuna lettera minuscola, \nun numero, e un carattere speciale';
const kCellError = 'Inserisci un numero di cellulare valido';
const kCercaProdotto = 'Cerca prodotto';
const kMsgErroreCercaProdotto =
    'Inserisci un valore da cercare che abbia almeno 3 caratteri';
const kForgotPasswordTitle = 'Password dimenticata';
const kForgotPassword =
    'Invieremo un codice di verifica a questo indirizzo email, se corrisponde a un account creato in precedenza.';
// Errori
const kProdottoNonConsentito = 'Severe worning';
const kUtenteNonAutorizzato = 'Utente non autorizzato, invia un email a xxxx ';

// Password sicura
// Requisiti:
// - Almeno 8 caratteri
// - Almeno 1 lettera maiuscola
// - Almeno 1 lettera minuscola
// - Almeno 1 numero
// - Almeno 1 carattere speciale
final kRegexPassword = RegExp(
  r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~^%+=?_\-]).{8,}$',
);
// reguisiti:
final kRegexCell = RegExp(r'^(?:\+39)?3\d{9}$');
final kRegexEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

// Filtri
class FilterGroup {
  final String title;
  final List<String> items;
  const FilterGroup({required this.title, required this.items});
}

const kFiltri1 = FilterGroup(
  title: 'Status',
  items: ["warning1", "prova2", "blabla"],
);
const kFiltri2 = FilterGroup(
  title: 'Category',
  items: ["warning2", "prova3", "blabla4"],
);
const kFiltri3 = FilterGroup(
  title: 'Category2',
  items: ["warning23", "prova33", "blabla43"],
);

//titoli
const kAddToList = 'Aggiungi';
const kOpzioni = 'Cerca prodotto';
const kScarica = 'Scarica file';
