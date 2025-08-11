import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 45, left: 24, right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
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

              // BOTTONE
              CustomButton(
                title: "Crea Nuova Lista",
                titleColor: Colors.white,
                backgroundColor: kPrimary,
                onPressed: () {},
              ),

              const SizedBox(height: 45),

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

              Expanded(
                child: ListView(
                  children: const [
                    ListTile(title: Text("Tesla Model S")),
                    ListTile(title: Text("Ford Mustang")),
                    ListTile(title: Text("BMW M3")),
                    ListTile(title: Text("Audi A4")),
                    ListTile(title: Text("Porsche 911")),
                    ListTile(title: Text("Lamborghini Huracán")),
                    ListTile(title: Text("Ferrari 488")),
                    ListTile(title: Text("Tesla Model S")),
                    ListTile(title: Text("Ford Mustang")),
                    ListTile(title: Text("BMW M3")),
                    ListTile(title: Text("Audi A4")),
                    ListTile(title: Text("Porsche 911")),
                    ListTile(title: Text("Lamborghini Huracán")),
                    ListTile(title: Text("Ferrari 488")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
