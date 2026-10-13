import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Voce di cache: [payload] null rappresenta una risposta vuota (cache negativa).
class CacheEntry {
  const CacheEntry(this.payload, this.fetchedAt);

  final String? payload;
  final DateTime fetchedAt;

  bool isFresh(Duration ttl, DateTime now) => now.difference(fetchedAt) < ttl;
}

/// Cache persistente chiave -> stringa, indipendente dal formato del contenuto
/// (XML SOAP oggi, JSON del Worker domani).
///
/// Livello in memoria (LRU) + un file per voce nella cartella cache dell'app.
/// Se la cartella non è disponibile (es. nei test) lavora solo in memoria.
class FarmadatiCache {
  FarmadatiCache({
    Future<Directory?> Function()? directory,
    DateTime Function()? clock,
    this.maxMemoryEntries = 500,
    this.maxAge = const Duration(days: 120),
  }) : _directoryProvider = directory ?? _defaultDirectory,
       _clock = clock ?? DateTime.now;

  final Future<Directory?> Function() _directoryProvider;
  final DateTime Function() _clock;
  final int maxMemoryEntries;

  /// Le voci più vecchie di così vengono cancellate dal disco all'avvio.
  final Duration maxAge;

  final LinkedHashMap<String, CacheEntry> _memory = LinkedHashMap();
  Future<Directory?>? _dir;

  DateTime now() => _clock();

  Future<CacheEntry?> read(String key) async {
    final inMemory = _memory.remove(key);
    if (inMemory != null) {
      _memory[key] = inMemory; // in coda: usato di recente
      return inMemory;
    }

    final file = await _fileFor(key);
    if (file == null || !await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString()) as Map;
      final entry = CacheEntry(
        decoded['p'] as String?,
        DateTime.fromMillisecondsSinceEpoch(decoded['t'] as int),
      );
      _remember(key, entry);
      return entry;
    } catch (_) {
      // file corrotto o troncato: lo trattiamo come assente
      await _deleteQuietly(file);
      return null;
    }
  }

  Future<void> write(String key, String? payload) async {
    final entry = CacheEntry(payload, now());
    _remember(key, entry);

    final file = await _fileFor(key);
    if (file == null) return;
    try {
      await file.writeAsString(
        jsonEncode({'t': entry.fetchedAt.millisecondsSinceEpoch, 'p': payload}),
        flush: true,
      );
    } catch (_) {
      // la cache su disco è un'ottimizzazione: un errore di scrittura non blocca
    }
  }

  void _remember(String key, CacheEntry entry) {
    _memory.remove(key);
    _memory[key] = entry;
    while (_memory.length > maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  Future<File?> _fileFor(String key) async {
    final dir = await (_dir ??= _openDirectory());
    if (dir == null) return null;
    final name = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    if (name.length > 200) return null; // nome file troppo lungo: solo memoria
    return File('${dir.path}${Platform.pathSeparator}$name.json');
  }

  Future<Directory?> _openDirectory() async {
    try {
      final dir = await _directoryProvider();
      if (dir == null) return null;
      await dir.create(recursive: true);
      _pruneOldFiles(dir); // in background, non serve attenderlo
      return dir;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pruneOldFiles(Directory dir) async {
    try {
      final limit = now().subtract(maxAge);
      await for (final f in dir.list()) {
        if (f is File && (await f.lastModified()).isBefore(limit)) {
          await _deleteQuietly(f);
        }
      }
    } catch (_) {}
  }

  static Future<void> _deleteQuietly(File f) async {
    try {
      await f.delete();
    } catch (_) {}
  }

  static Future<Directory?> _defaultDirectory() async {
    final base = await getApplicationCacheDirectory();
    return Directory('${base.path}${Platform.pathSeparator}farmadati');
  }
}
