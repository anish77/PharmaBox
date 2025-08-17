import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:toggle_switch/toggle_switch.dart';

class SelectedListPage extends StatefulWidget {
  const SelectedListPage({
    super.key,
    required this.titolo,
    required this.nrListe,
  });
  final String titolo;
  final int nrListe;
  

  @override
  State<SelectedListPage> createState() => _SelectedListPageState();
}

class _SelectedListPageState extends State<SelectedListPage> {
  var logger = Logger(printer: PrettyPrinter());
  var selectedIndex = 0;
  final _cercaProdottoKeyForm = GlobalKey<FormState>();
  String _query = '';
  bool _isLoading = false;
  List<dynamic> _risultati = [];

  Future<String> _postXml(String endpoint, String xmlBody) async {
  final uri = Uri.parse(endpoint);
  final resp = await http
      .post(
        uri,
        headers: {
          'Content-Type': 'application/xml',
          'Accept': 'application/xml',
        },
        body: utf8.encode(xmlBody), // assicuri UTF-8
      )
      .timeout(const Duration(seconds: 12));

  if (resp.statusCode != 200) {
    throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
  }
  return utf8.decode(resp.bodyBytes); // risposta come XML string
}

String buildSearchXml(String query) {
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<Request>
  <Search>${query}</Search>
</Request>
''';
}

  Future<void> _submit() async {
  if (!_cercaProdottoKeyForm.currentState!.validate()) return;
  _cercaProdottoKeyForm.currentState!.save(); // 👉 qui scatta il tuo onSaved
  logger.i('Hai cercato: $_query');

  // fai qui la chiamata HTTP con _query
  setState(() => _isLoading = true);
  try {
    // TODO: chiama il tuo endpoint. Esempio GET:
    // final uri = Uri.parse('https://tuoserver/search?q=${Uri.encodeQueryComponent(_query)}');
    // final resp = await http.get(uri);
    // if (resp.statusCode == 200) {
    //   final data = jsonDecode(resp.body) as List;
    //   setState(() => _risultati = data);
    // }
    final xmlBody = buildSearchXml(_query);
    final responseXml = await _postXml('http://webservices.farmadati.it/WS2/FarmadatiItaliaWebServicesM1.svc', xmlBody);

    // per demo:
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _risultati = ['Prodotto A', 'Prodotto B', 'Prodotto C']);
  } finally {
    setState(() => _isLoading = false);
  }

}

  Widget cercaProdotto() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: kCercaProdotto,
        suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _submit, // 🔎 esegue la ricerca
        ),
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
      textInputAction: TextInputAction.search, // invio fa “cerca”
      autocorrect: false,
      validator: (value) {
        if (value == null || value.trim().length < 3) {
          return kMsgErroreCercaProdotto;
        }
        logger.i('validator');
        return null;
      },
      onSaved: (value) {
        // Logica per salvare il prodotto
        _query = (value ?? '').trim();
        logger.i('onSaved query: $_query');
      },
      onFieldSubmitted: (_) => _submit(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titolo),
        centerTitle: false,
        titleSpacing: 0, // riduce lo spazio prima del titolo
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(
                  width:
                      double.infinity, // occupa tutta la larghezza disponibile
                  child: ToggleSwitch(
                    minWidth: double.infinity,
                    cornerRadius: 28.0,
                    borderWidth: 1.0,
                    fontSize: 16,
                    initialLabelIndex: selectedIndex,
                    activeBgColor: [kPrimary],
                    activeFgColor: Colors.white,
                    inactiveBgColor: kSecondary,
                    inactiveFgColor: kBluScuro,
                    totalSwitches: 2,
                    labels: ['Cerca', 'Opzioni'],
                    onToggle: (index) {
                      setState(() {
                        logger.i('switched to: $index');
                        selectedIndex = index!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (selectedIndex == 0) ...[
                  Form(
                    key: _cercaProdottoKeyForm,
                    child: cercaProdotto()
                    )
                    ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
