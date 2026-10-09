import 'package:flutter/widgets.dart';

const kFarmadatiUsername = 'BDF203348XC';
const kFarmadatiPassword = 'epxD67iZR';
const kWebsiteURL = 'https://www.doublecore.it';
const kPrivacyPolicyUrl = 'https://www.doublecore.it/privacy.htm';
const kApiKeyApple = 'appl_KcHJKduAMoJsJlkfkugejJEmujK';
const kApiKeyGoogle = 'goog_XJBZiSYJNkQGCyBZPdzpcKnurXy';

const kAppName = 'PharmaBox';
const kLogo = 'assets/Logo.png';
const kNoImage = 'assets/noImage.png';
const kScanCode = 'assets/scanCode.png';
const kScanCode2 = 'assets/scan_code2.png';
const kNoScanCode = 'assets/noScanCode.png';
const kBluetoothImage = 'assets/bluetooth.png';
const kAddListImage = 'assets/add-list.png';
const kCongratulazioni = 'assets/congratulazioni.png';

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
const kProdottoNonConsentito = 'Non vendibile';
const kUtenteNonAutorizzato =
    'Questa sezione è riservata ai membri. Attiva l’abbonamento per continuare.';
const kMembershipEmail = 'infopharmabox@doublecore.it';
const kAccessoMembri = 'Richiesta accesso membri';
const kDiventareMembro = 'Ciao, vorrei diventare membro di PharmaBox.';
const kRichiestaAssistenza = 'Richiesta assistenza PharmaBox';
const kSupporto = 'Ciao, avrei bisogno di supporto con la mia esperienza.';
const kRegCompletata = 'Registrazione completata ✅';
const kAttivaAbbonamento = 'Attiva abbonamento';
const kAbbonamentoPremium = 'Con l’abbonamento Premium puoi:';
const kAbbonamentoPremiumDescrizione =
    '• Collegare uno scanner barcode esterno compatibile\n• Effettuare l’inventario della farmacia tramite scansione rapida\n• Ridurre il tempo di inventario rispetto all’inserimento manuale';

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
const kDisponibileMembri = 'Disponibile solo per i membri.';
const kDiventaMembro = 'Diventa membro';

//InviteFriendPage
const kInvitaAmico = 'Invita un amico';
const kInformazioni = 'Informazioni';
const kSconto = 'Invita un’amico e ottieni mesi gratuiti!';
const kLinkRiferimento = 'Condividi il tuo link di riferimento';
const kInvitaAmici = 'Invita amici a registrarsi';
const kGuadagna = 'Per ogni amico invitata ottieni 1 mese gratuito';

// API endpoints
const kFarmadatiEndpoint =
    'http://webservices.farmadati.it/WS2/FarmadatiItaliaWebServicesM1.svc';

// Cloudflare R2 integration (configura questi valori nel tuo ambiente)
// Dominio pubblico (CDN) collegato al bucket R2 "prod-images"
const kR2CdnBaseUrl = 'https://doublecore.it';
// Endpoint del Worker per l'ingest (POST /ingest)
const kR2IngestEndpoint =
    'https://pharmabox-r2-ingest.gianluca-carta.workers.dev/ingest';
// Opzionale: una API key semplice allineata con il Worker (header x-api-key)
const kR2ApiKey = 'doublecore';
const kFarmadatiSoapHeaders = {
  'Content-Type': 'text/xml; charset=utf-8',
  'Accept': 'application/xml',
  'SOAPAction':
      'http://webservices.farmadati.it/FarmadatiItaliaWebServicesM1/ExecuteQuery',
};

const kBitProdottoUndefined = 0;
const kBitProdottoVendibile = 1;
const kBitProdottoNonVendibile = 2;

const kBugiardinoMonografieBase = 'http://api.doublecore.it/pdf_html';
const kBugiardinoUploadEndpoint = 'http://api.doublecore.it/uploader.php';

enum DatasetKind { tr001, tdz, tdf, td1 }

// Amazon Scanner
const kAmazonScanner =
    'https://www.amazon.it/Tera-lettore-codici-barre-wireless/dp/B0BZRXDNVD';
