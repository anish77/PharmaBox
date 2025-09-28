class CategoriaMapper {
  static const Map<String, List<String>> _map = {
    'A': ['OMEOPATICO USO UMANO', 'O'],
    'B': ['OMEOPATICO USO VETERINARIO', 'O'],
    'C': ['PRESIDIO MEDICO CHIRURGICO', 'P'],
    'D': ['FARMACO DA BANCO', 'F'],
    'E': ['FARMACO ETICO', 'F'],
    
    'F': ['FARMACO OSPEDALIERO', 'F'],
    'G': ['FARMACO GENERICO', 'F'],
    'H': ['FARMACO SOLO USO OPEDALIERO', 'F'],
    'J': ['PREPARAZIONE MAGISTRALE', 'F'],
    'I': ['BIOCIDA', 'P'],
    'M': ['MEDICINALE VET. PREFABBRICATO', 'V'],
    'N': ['ALIMENTO FINI MED. SPECIALI', 'P'],
    'O': ['FARMACO ODONTOIATRICO', 'F'],
    'P': ['PARAFARMACO USO UMANO', 'P'],
    'Q': ['SERVIZI', 'I'],
    'R': ['SOSTANZA PRECONFEZIONATA', 'P'],
    'V': ['FARMACO VETERINARIO', 'V'],
    'W': ['PARAFARMACO USO VETERINARIO', 'P'],
    'X': ['DISPOSITIVO MEDICO', 'D'],
  };

  static List<String>? getDescrizione(String codice) => _map[codice];

  static List<String> get codici => _map.keys.toList();

  static Map<String, String> get all => Map.unmodifiable(_map);
}
