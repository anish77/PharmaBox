import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/domain/repository/carrello.dart';
import 'package:pharma_box/widgets/counter_button.dart';
import 'package:pharma_box/domain/models/prodotto.dart';
import 'package:pharma_box/widgets/non_autorizzato.dart';

class GestioneProdotto {
  final logger = Logger(printer: PrettyPrinter());
  final carrello = CarrelloIsar.instance;

  // Widget prodotto trovato (esempio dimostrativo)
  Widget prodottoTrovato() {
    final Prodotto prodotto = Prodotto(
      id: 0,
      nome: 'Prodotto Oki',
      minsan: 'Minsan 123456789',
      immagine: 'assets/noImage.png',
      pezzi: 1,
      vendibile: 0,
      description:
          "Cardiavax™ è una terapia combinata contenente un inibitore dell'HMG-CoA reduttasi (atorvastatina) e un beta-bloccante (metoprololo).",
      ingredients:
          "Ogni compressa contiene atorvastatina calcio (20 mg) e metoprololo tartrato (25 mg). Altri ingredienti: cellulosa, lattosio, magnesio stearato, agenti di rivestimento.",
      howToTake:
          "Non usare in gravidanza o allattamento.\nPuò causare vertigini, stanchezza o dolori muscolari.\nEvitare alcol e succo di pompelmo.\nUsare con cautela in caso di problemi epatici o renali.\nNon interrompere improvvisamente senza consiglio medico.",
      codice: '1234567',
    );

    return Padding(
      padding: const EdgeInsets.only(top: 80, left: 10, right: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicatore di non vendibilità
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
              const Text(
                kProdottoNonConsentito,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dettagli del prodotto
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
                      style: const TextStyle(
                        fontSize: 16,
                        color: kBluScuro,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<int>(
                      valueListenable: prodotto.pezzi,
                      builder: (context, value, _) {
                        return CounterButton(
                          initialValue: value,
                          onChanged: (newValue) async {
                            prodotto.pezzi.value = newValue;
                            await carrello.aggiungiProdotto(prodotto);
                            logger.i("Quantità aggiornata: $newValue per ${prodotto.nome}");
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

  // Campo di ricerca prodotto
  Widget cercaProdotto({
    required BuildContext context,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: kCercaProdotto,
          labelStyle: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: kBluScuro),
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

  // Schermata non autorizzato (account inattivo)
  Widget nonAutorizzato() {
    return const NonAutorizzato();
  }
}
