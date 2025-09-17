class CategoriaMapper {
  static const Map<String, String> _map = {
    'P': 'PARAFARMACO',
    'F': 'FARMACO',
    'D': 'DISPOSITIVO MEDICO',
    'C': 'COSMETICO',
    'I': 'INTEGRATORE',
  };

  static String? getDescrizione(String codice) => _map[codice];

  static List<String> get codici => _map.keys.toList();

  static Map<String, String> get all => Map.unmodifiable(_map);
}