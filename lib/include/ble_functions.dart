import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/web.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pharma_box/main.dart';
import '../include/general_functions.dart';
// rimuoviamo la dipendenza diretta dalla pagina UI per evitare cicli di import

var logger = Logger(printer: PrettyPrinter());
Future<bool> ensureBleReady() async {
  // 1. Permessi
  final statuses =
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse, // per Android < 12
      ].request();

  if (statuses.values.any((status) => !status.isGranted)) {
    //return false;
  }

  // 2. Verifica supporto
  if ((await FlutterBluePlus.isSupported) == false) {
    return false;
  }

  // 3. Stato adapter
  var state = await FlutterBluePlus.adapterState.first;
  if (state != BluetoothAdapterState.on) {
    try {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn(); // su Android apre il dialog
      }
    } catch (_) {}
    // 🔹 Aspetta che diventi ON prima di proseguire
    state = await FlutterBluePlus.adapterState.firstWhere(
      (s) => s == BluetoothAdapterState.on,
      orElse: () => BluetoothAdapterState.off,
    );
  }

  return state == BluetoothAdapterState.on;
}

// UUID standard
final dis = Guid('0000180A-0000-1000-8000-00805F9B34FB');
final serialCh = Guid('00002A25-0000-1000-8000-00805F9B34FB');

final Guid disUuid = Guid(
  '0000180A-0000-1000-8000-00805F9B34FB',
); // Device Information Service
final Guid serialUuid = Guid(
  '00002A25-0000-1000-8000-00805F9B34FB',
); // Serial Number String

Future<String?> readSerialNumber(BluetoothDevice dev) async {
  try {
    // Assicurati di essere connesso prima di chiamare discoverServices()
    final services = await dev.discoverServices();

    // Trova il servizio DIS senza usare firstWhere/orElse:null
    BluetoothService? dis;
    for (final s in services) {
      if (s.uuid == disUuid) {
        dis = s;
        break;
      }
    }
    if (dis == null) return null; // DIS non presente

    // Trova la caratteristica "Serial Number"
    BluetoothCharacteristic? ch;
    for (final c in dis.characteristics) {
      if (c.uuid == serialUuid) {
        ch = c;
        break;
      }
    }
    if (ch == null || !ch.properties.read) {
      return null; // niente char o non leggibile
    }

    // Leggi e decodifica
    final bytes = await ch.read();
    final serial =
        utf8
            .decode(bytes, allowMalformed: true)
            .replaceAll('\u0000', '') // rimuove eventuali terminatori NUL
            .trim();

    return serial.isEmpty ? null : serial;
  } catch (e) {
    // es. non connesso, servizi non disponibili, ecc.
    // debugPrint('readSerialNumber error: $e');
    return null;
  }
}

// ==== BLE ====
//bool _bleScanning = false;
//String _bleStatus = 'BLE pronto';
BluetoothDevice? _bleDevice;
final List<StreamSubscription> _bleSubs = [];
final Guid _feea = Guid('0000FEEA-0000-1000-8000-00805F9B34FB');

Future<void> _bleEnsurePerms() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse, // per Android <12
  ].request();
}

String _bleDecode(List<int> bytes) {
  try {
    return utf8.decode(bytes, allowMalformed: true).trim();
  } catch (_) {
    return String.fromCharCodes(bytes).trim();
  }
}

Future<void> bleStartScanAndListen(WidgetRef ref) async {
  await _bleEnsurePerms();
  // Evita listener duplicati da sessioni precedenti
  await _bleDispose();
  //final ok = await ensureBleReady();
  final bool bleScanning = ref.read(bleScanningProvider);
  /*
  if (!ok && mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('BLE non supportato')));
    return;
  }*/

  if (bleScanning) return;

  ref.read(bleScanningProvider.notifier).state = true;
  ref.read(bleStatusProvider.notifier).state = "Scanning...";

  // wait for bluetooth to turn on & permission granted
await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;

  await FlutterBluePlus.startScan(
    //withServices: [_feea],
    timeout: const Duration(seconds: 6),
    //scanMode: ScanMode.lowLatency,
    androidScanMode: AndroidScanMode.lowLatency,
  );

  // ascolta risultati
  final sub = FlutterBluePlus.scanResults.listen(
    (results) async {
      //logger.i(results.length);
      for (final r in results) {
        // 👉 Se conosci il nome del tuo scanner, filtra:
        //if (r.device.platformName != 'NOME_TUO_SCANNER') continue;
        logger.i(r.device);

        //if (r.device.remoteId.str != '54DCB6B0-828C-D8CF-57BB-3D4D7E54EC3B')
        if (r.device.platformName != 'BarCode Scanner BLE') continue;

        // preso il primo device; ferma scan e connetti
        await FlutterBluePlus.stopScan();

        ref.read(bleScanningProvider.notifier).state = false;
        ref.read(bleStatusProvider.notifier).state =
            'Connessione a ${r.device.remoteId.str}…';

        await _bleConnectAndSubscribe(r.device, ref);
        break;
      }
    },
    onError: (e) {
      ref.read(bleScanningProvider.notifier).state = false;
      ref.read(bleStatusProvider.notifier).state = "Errore scansione: $e";
    },
  );

  _bleSubs.add(sub);

  // quando finisce lo scan (per timeout)
  FlutterBluePlus.isScanning.where((v) => v == false).first.then((_) {
    if (ref.read(bleScanningProvider)) {
      ref.read(bleScanningProvider.notifier).state = false;
      ref.read(bleStatusProvider.notifier).state = "Nessun dispositivo trovato";
    }
  });
}

Future<void> _bleConnectAndSubscribe(BluetoothDevice dev, ref) async {
  _bleDevice = dev;
  try {
    await dev.connect(timeout: const Duration(seconds: 10));
  } catch (_) {
    // already connected: ignora
  }
  //if (!mounted) return;

  await dev.connectionState.firstWhere(
    (s) => s == BluetoothConnectionState.connected,
  );

  // Ascolta disconnessioni per ripulire i listener e lo stato
  final connSub = dev.connectionState.listen((s) async {
    if (s == BluetoothConnectionState.disconnected) {
      try {
        ref.read(bleStatusProvider.notifier).state = 'Disconnesso';
      } catch (_) {}
      ref.read(bleConnected.notifier).state = false;
      await _bleDispose();
      // opzionale: auto-riavvio della scansione
      // await bleStartScanAndListen(ref);
    }
  });
  _bleSubs.add(connSub);

  // check serial
  final serial = await readSerialNumber(dev);

  logger.i("SERIALE:");
  logger.i(serial);

  //setState(() => _bleStatus = 'Discover services…');
  ref.read(bleStatusProvider.notifier).state = "Discovering services...";

  final services = await dev.discoverServices();

  // 🔎 trova il service FEEA senza istanziare nulla
  BluetoothService? feeaSvc;
  for (final s in services) {
    if (s.uuid == _feea) {
      feeaSvc = s;
      break;
    }
  }

  if (feeaSvc == null) {
    //setState(() => _bleStatus = 'Service FEEA non trovato');
    ref.read(bleStatusProvider.notifier).state = 'Service FEEA non trovato';

    // opzionale: in alternativa sottoscrivi QUALSIASI characteristic con notify:
    // await _subscribeAllNotify(services);
    return;
  }

  // Sottoscrizione alle characteristic notify del service FEEA
  int subscribed = 0;
  for (final c in feeaSvc.characteristics) {
    if (c.properties.notify || c.properties.indicate) {
      await c.setNotifyValue(true);
      subscribed++;
      final s = c.onValueReceived.listen((data) async {
        final barcode = _bleDecode(data);
        if (barcode.isEmpty) return;
        //if (!mounted) return;
        //setState(() => _bleStatus = 'Letto: $barcode');
        ref.read(bleStatusProvider.notifier).state = 'Letto: $barcode';

        // Pubblica il barcode convertito su un provider di stato
        // L'UI lo ascolta e apre la ricerca
        ref.read(scannedBarcodeProvider.notifier).state = tradCode(barcode);
      }, onError: (_) {});
      _bleSubs.add(s);
      // Sottoscrivi una sola caratteristica notify per evitare duplicati
      break;
    }
  }
  ref.read(bleConnected.notifier).state = true;
  ref.read(bleStatusProvider.notifier).state =
      subscribed > 0
          ? 'In ascolto… scansiona un barcode'
          : 'Nessuna characteristic notify nel service FEEA';
}

Future<void> _bleDispose() async {
  for (final s in _bleSubs) {
    try {
      await s.cancel();
    } catch (_) {}
  }
  _bleSubs.clear();
  if (_bleDevice != null) {
    try {
      await _bleDevice!.disconnect();
    } catch (_) {}
  }
}
