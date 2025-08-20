import 'package:flutter/widgets.dart';

const kAppName = 'PharmaBox';
const kLogo = 'assets/Logo.png';

//colors
const kPrimary = Color(0xFF5D5FEF);
const kSecondary = Color(0xFFE5E6FF);
const kBackGround = Color(0xFFF5F7FA);
const kBluScuro = Color(0xFF2B2D66);
const kWarning = Color(0xFFE59700);
const kGreen = Color(0xFF0B8E63);
const kRed = Color(0xFFC6180B);
const kWhite = Color(0xFFFFFFFF);

//messages
const kEmailError = 'Please enter a valid email address';
const kPasswordError = 'Password must be at least 6 characters long';
const kCercaProdotto = 'Cerca prodotto';
const kMsgErroreCercaProdotto =
    'Inserisci un valore da cercare che abbia almeno 3 caratteri';
const kForgotPasswordTitle = 'Password dimenticata';
const kForgotPassword =
    'Invieremo un codice di verifica a questo indirizzo email, se corrisponde a un account creato in precedenza.';
/*const kLoginSuccess = 'Login successful!';
const kLoginError = 'Login failed. Please try again.';
const kSignUpSuccess = 'Sign up successful!';
const kSignUpError = 'Sign up failed. Please try again.';
const kPasswordHint = 'Enter your password';*/

// Password sicura
// Requisiti:
// - Almeno 8 caratteri
// - Almeno 1 lettera maiuscola
// - Almeno 1 lettera minuscola
// - Almeno 1 numero
// - Almeno 1 carattere speciale
final kRegex = RegExp(
  r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~^%+=?_\-]).{8,}$',
);
