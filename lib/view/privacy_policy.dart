import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  TextSpan _title(String text) {
    return TextSpan(
      text: "$text\n",
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600, // semibold
        height: 1.6,
        color: Colors.black,
      ),
    );
  }

  TextSpan _subTitle(String text) {
    return TextSpan(
      text: "$text\n",
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w300, // semibold
        height: 1.6,
        color: Colors.black,
      ),
    );
  }

  TextSpan _body(String text) {
    return TextSpan(
      text: "$text\n\n",
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: Colors.black,
      ),
    );
  }

  TextSpan _link(String text, String url) {
    return TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Color.fromARGB(255, 2, 85, 228),
      ),
      recognizer:
          TapGestureRecognizer()
            ..onTap = () {
              launchUrl(Uri.parse(url));
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          ('Informativa sulla Privacy'),
          style: TextStyle(
            color: kBluScuro,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: kBluScuro),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SelectableText.rich(
            TextSpan(
              children: [
                _subTitle("Ultimo aggiornamento: 19/01/2026"),
                _subTitle(
                  "La presente Informativa sulla Privacy descrive le modalità con cui l’app PharmaBox (di seguito “App”) raccoglie, utilizza e protegge i dati personali degli utenti. Utilizzando l’App, accetti le pratiche descritte in questa Informativa.\n",
                ),
                _title("1. Titolare del Trattamento"),
                _body(
                  "Il titolare del trattamento dei dati è lo sviluppatore dell’app PharmaBox.",
                ),

                _title("2. Dati Personali Raccolti"),
                _body(
                  "L’App può raccogliere le seguenti categorie di dati personali:\n"
                  "* Indirizzo email\n"
                  "* Identificativo utente\n"
                  "* Informazioni necessarie all’autenticazione",
                ),

                _title("3. Finalità del Trattamento"),
                _body(
                  "I dati personali sono raccolti e trattati esclusivamente per:\n"
                  "* consentire l’autenticazione degli utenti\n"
                  "* permettere l’accesso all’App\n"
                  "* garantire la sicurezza del servizio\n"
                  "* gestire gli abbonamenti e le funzionalità associate",
                ),

                _title("4. Servizi di Terze Parti"),
                TextSpan(
                  text:
                      "L’App utilizza i seguenti servizi di terze parti:\n"
                      "* Firebase Authentication (Google LLC) per la gestione dell’autenticazione\n"
                      "*Apple In-App Purchases per la gestione dei pagamenti\n"
                      "* RevenueCat per la gestione degli abbonamenti\n",
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black,
                  ),
                ),
                _subTitle(
                  "Tali servizi possono trattare i dati personali secondo le rispettive informative sulla privacy.",
                ),
                _link(
                  "https://policies.google.com/privacy",
                  "https://policies.google.com/privacy",
                ),
                _title(""),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
