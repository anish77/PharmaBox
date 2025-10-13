import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/carrello.dart';
import 'package:pharma_box/widgets/counter_button.dart';
import 'package:pharma_box/domain/models/prodotto.dart';
import 'package:pharma_box/widgets/non_autorizzato.dart';

class GestioneProdotto {
  var logger = Logger(printer: PrettyPrinter());
  // Widget prodotto trovato
  Widget prodottoTrovato() {
    // Creo il prodotto da aggiungere
    final Prodotto prodotto = Prodotto(
      id: 0,
      nome: 'Prodotto Oki',
      minsan: 'Minsan 123456789',
      immagine: 'assets/noImage.png',
      pezzi: 1,
      vendibile: 0,
      description:
          "Cardiavax™ is a combination therapy containing an HMG-CoA reductase inhibitor (atorvastatin) and a beta-adrenergic blocker (metoprolol).",
      ingredients:
          "Each tablet contains atorvastatin calcium (20 mg) and metoprolol tartrate (25 mg). Other ingredients: cellulose, lactose, magnesium stearate, coating agents.",
      howToTake:
          "Not for use in pregnancy or breastfeeding. \nMay cause dizziness, tiredness, or muscle pain. \nAvoid alcohol and grapefruit juice. \nUse with caution if you have liver or kidney problems. \nDo not stop suddenly without medical advice.",
      codice: '1234567',
    );

    return Padding(
      padding: const EdgeInsets.only(top: 80, left: 10, right: 0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: kRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                kProdottoNonConsentito,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(kNoImage, height: 100, width: 100, color: kBluScuro),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prodotto.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBluScuro,
                      ),
                      softWrap: true,
                    ),
                    Text(
                      prodotto.minsan,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: kBluScuro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<int>(
                      valueListenable: prodotto.pezzi,
                      builder: (context, value, _) {
                        return CounterButton(
                          initialValue: value,
                          onChanged: (newValue) {
                            prodotto.pezzi.value = newValue;
                            Carrello.instance.aggiungiProdotto(prodotto);
                            logger.i("Valore aggiornato: $newValue");
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget cerca prodotto
  Widget cercaProdotto({
    required BuildContext context,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: kCercaProdotto,
          labelStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: kBluScuro),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: kPrimary),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: kPrimary),
          ),
        ),
        keyboardType: TextInputType.text,
        autocorrect: false,
        validator: (value) {
          if (value == null || value.trim().isEmpty || value.length < 3) {
            return kMsgErroreCercaProdotto;
          }
          return null;
        },
        onChanged: onChanged,
      ),
    );
  }

  Widget nonAutorizzato() {
    return const NonAutorizzato();
  }
}
