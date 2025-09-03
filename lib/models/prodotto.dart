class Prodotto {
  final String titolo;
  final String minsan;
  final String imagePath;
  int pezzi;
  final bool consentito;
  //double prezzo;

  Prodotto({
    required this.titolo,
    required this.minsan,
    required this.imagePath,
    this.pezzi = 1,
    required this.consentito,
  });
}
