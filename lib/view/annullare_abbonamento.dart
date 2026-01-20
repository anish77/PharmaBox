import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class AnnullareAbbonamento extends StatelessWidget {
  const AnnullareAbbonamento({super.key});

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
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          ("Come annullare l'abbonamento?"),
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
                _title(
                  "Per annullare l'abbonamento sull'App Store, segui questi passaggi:",
                ),
                _body(
                  "\n1. Apri l'app App Store (sul tuo dispositivo) \n2. Seleziona il tuo nome. Se non riesci a trovare il tuo nome, tocca 'Accedi' \n3. Tocca 'Impostazioni account' \n4. Scorri fino alla sezione 'Abbonamenti', quindi tocca 'Gestisci' \n5. Tocca 'PharmaBox' \n6. Tocca 'Annulla abbonamento'",
                ),
                _title(
                  "Per annullare l'abbonamento su Google Play, segui questi passaggi:",
                ),
                _body(
                  "\n1. Apri l'app Google Play Store sul tuo dispositivo Android \n2. Tocca l'icona del menu (tre linee orizzontali) nell'angolo in alto a sinistra \n3. Seleziona Pagamenti e abbonamenti > Abbonamenti \n4. Trova l'abbonamento a PharmaBox nell'elenco e toccalo \n5. Tocca 'Annulla abbonamento' e segui le istruzioni per completare il processo di annullamento)\n",
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
