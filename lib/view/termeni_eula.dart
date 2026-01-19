import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class Termenieula extends StatelessWidget {
  const Termenieula({super.key});

  TextSpan _title(String text) {
    return TextSpan(
      text: "$text\n",
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600, // semibold
        height: 1.6,
        color: Colors.black,
      ),
    );
  }

  TextSpan _body(String text) {
    return TextSpan(
      text: "$text\n\n",
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: Colors.black,
      ),
    );
  }

  TextSpan _link(String text, String url) {
    return TextSpan(
      text: text,
      style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.blue),
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
          ('Termini di Utilizzo'),
          style: TextStyle(
            color: kBluScuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
                _title("1. Accettazione dei Termini"),
                _body(
                  "L’utilizzo dell’applicazione (“App”) implica l’accettazione "
                  "dei presenti Termini di Utilizzo. Se non accetti i Termini, "
                  "ti invitiamo a non utilizzare l’App.",
                ),

                _title("2. Descrizione del Servizio"),
                _body(
                  "L’App fornisce contenuti e funzionalità accessibili tramite "
                  "abbonamento auto-rinnovabile. Le funzionalità disponibili "
                  "possono variare in base al piano di abbonamento scelto.",
                ),

                _title("3. Abbonamenti e Pagamenti"),
                _body(
                  "Gli abbonamenti sono auto-rinnovabili e vengono addebitati "
                  "tramite l’account Apple ID dell’utente al momento della "
                  "conferma dell’acquisto.\n\n"
                  "L’abbonamento si rinnova automaticamente salvo disattivazione "
                  "almeno 24 ore prima della fine del periodo corrente. Il costo "
                  "del rinnovo viene addebitato entro le 24 ore precedenti la "
                  "scadenza.\n\n"
                  "L’utente può gestire o disattivare il rinnovo automatico "
                  "dalle Impostazioni del proprio account Apple ID dopo "
                  "l’acquisto.\n\n"
                  "Eventuali periodi di prova gratuiti, se offerti, verranno "
                  "convertiti automaticamente in abbonamenti a pagamento salvo "
                  "cancellazione prima della fine del periodo di prova.",
                ),

                _title("9. EULA Apple"),
                TextSpan(
                  text:
                      "Per quanto non espressamente previsto dai presenti Termini, "
                      "si applicano i Termini di Licenza Standard Apple (EULA), "
                      "disponibili al seguente link:\n",
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black,
                  ),
                ),
                _link(
                  "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
                  "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
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
