import 'package:flutter/widgets.dart';

const kAppName = 'PharmaBox';
const kLogo = 'assets/Logo.png';

//colors
const kPrimary = Color(0xFF5D5FEF);
const kSecondary = Color(0xFFE5E6FF);
const kBackGround = Color(0xFFF5F7FA);
const kBluScuro = Color(0xFF2B2D66);

//messages
const kEmailError = 'Please enter a valid email address';
const kPasswordError = 'Password must be at least 6 characters long';
const kCercaProdotto = 'Cerca prodotto';
const kMsgErroreCercaProdotto =
    'Inserisci un valore da cercare che abbia almeno 3 caratteri';

// API endpoints
const kFarmadatiEndpoint =
    'http://webservices.farmadati.it/WS2/FarmadatiItaliaWebServicesM1.svc';

// Cloudflare R2 integration (configura questi valori nel tuo ambiente)
// Dominio pubblico (CDN) collegato al bucket R2 "prod-images"
const kR2CdnBaseUrl = 'https://www.doublecore.it';
// Endpoint del Worker per l'ingest (POST /ingest)
const kR2IngestEndpoint = 'https://pharmabox-r2-ingest.gianluca-carta.workers.dev/ingest';
// Opzionale: una API key semplice allineata con il Worker (header x-api-key)
const kR2ApiKey = 'doublecore';
/*const kLoginSuccess = 'Login successful!';
const kLoginError = 'Login failed. Please try again.';
const kSignUpSuccess = 'Sign up successful!';
const kSignUpError = 'Sign up failed. Please try again.';
const kPasswordHint = 'Enter your password';*/
