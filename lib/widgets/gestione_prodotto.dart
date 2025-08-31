import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/counter_button.dart';

class GestioneProdotto {
  // Widget prodotto trovato
  Widget prodottoTrovato() {
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
                    const Text(
                      "title Oki",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBluScuro,
                      ),
                      softWrap: true,
                    ),
                    const Text(
                      "subtitle",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: kBluScuro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CounterButton(
                      initialValue: 1,
                      onChanged: (value) {
                        print("Valore aggiornato: $value");
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
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            kNotAuthorized,
            height: 100,
            width: 100,
            color: kBluScuro,
          ),
          Text(
            kUtenteNonAutorizzato,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: kBluScuro,
            ),
          ),
        ],
      ),
    );
  }
}
