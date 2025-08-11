import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/screens/selected_list_page.dart';
import 'package:pharma_box/widgets/crea_lista_popup.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  int? selectedIndex; // indice elemento selezionato

  @override
  Widget build(BuildContext context) {
    final items = [
      "Tesla Model S",
      "Ford Mustang",
      "BMW M3",
      "Audi A4",
      "Porsche 911",
      "Lamborghini Huracán",
      "Ferrari 488",
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 45, left: 24, right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + titolo
              Row(
                children: [
                  Image.asset(kLogo, height: 25, width: 25),
                  const SizedBox(width: 8),
                  const Text(
                    kAppName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bottone
              CustomButton(
                title: "Crea Nuova Lista",
                titleColor: Colors.white,
                backgroundColor: kPrimary,
                onPressed: () {
                  CreaListaPopup().showPopup(context);
                },
              ),

              const SizedBox(height: 45),

              // Intestazione Liste
              Container(
                width: double.infinity,
                color: kSecondary,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: const Text(
                  "Liste",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kBluScuro,
                  ),
                ),
              ),

              // Lista
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedIndex == index;
                    return ListTile(
                      title: Text(items[index]),
                      tileColor:
                          isSelected ? kSecondary.withOpacity(0.3) : null,
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => SelectedListPage(
                                  titolo: items[index],
                                  nrListe: items.length,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
