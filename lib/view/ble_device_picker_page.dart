import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/ble_functions.dart';

/// Servizi degli scanner supportati, se presenti nell'advertising
final _serviziScanner = [Guid('FEEA'), Guid('FFF0')];

/// Parole che compaiono nel nome degli scanner (confronto minuscolo)
const _nomiScanner = ['scanner', 'barcode', 'scan'];

/// Cerca i dispositivi Bluetooth vicini e restituisce con Navigator.pop
/// il [BluetoothDevice] scelto. La connessione la fa chi ha aperto la pagina.
class BleDevicePickerPage extends StatefulWidget {
  const BleDevicePickerPage({super.key});

  @override
  State<BleDevicePickerPage> createState() => _BleDevicePickerPageState();
}

class _BleDevicePickerPageState extends State<BleDevicePickerPage> {
  final List<StreamSubscription> _subs = [];
  List<ScanResult> _risultati = [];
  bool _scanning = false;
  bool _mostraTutti = false;
  final Set<String> _loggati = {};
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await bleRequestPermissions();
    if (!mounted) return;
    _subs.add(
      FlutterBluePlus.scanResults.listen((r) {
        r.forEach(_logAdvertising);
        if (mounted) setState(() => _risultati = r);
      }),
    );
    _subs.add(
      FlutterBluePlus.isScanning.listen((v) {
        if (mounted) setState(() => _scanning = v);
      }),
    );
    _subs.add(
      FlutterBluePlus.adapterState.listen((s) {
        if (!mounted) return;
        setState(() => _adapterState = s);
        if (s == BluetoothAdapterState.on && !FlutterBluePlus.isScanningNow) {
          _avviaScansione();
        }
      }),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _avviaScansione() async {
    setState(() => _risultati = []);
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (e) {
      logger.e('Avvio scansione fallito: $e');
    }
  }

  Future<void> _seleziona(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    if (mounted) Navigator.pop(context, device);
  }

  String _nome(ScanResult r) =>
      r.device.platformName.isNotEmpty
          ? r.device.platformName
          : r.advertisementData.advName;

  /// Diagnostica: cosa trasmette ogni dispositivo prima della connessione
  void _logAdvertising(ScanResult r) {
    if (!_loggati.add(r.device.remoteId.str)) return;
    final adv = r.advertisementData;
    logger.i(
      'BLE adv "${_nome(r)}" ${r.device.remoteId.str} '
      'servizi: ${adv.serviceUuids.map((g) => g.str).join(', ')} '
      'produttore: ${adv.manufacturerData.keys.map((k) => '0x${k.toRadixString(16)}').join(', ')}',
    );
  }

  bool _isScanner(ScanResult r) {
    final nome = _nome(r).toLowerCase();
    return nome == kNomeScannerBle.toLowerCase() ||
        _nomiScanner.any(nome.contains) ||
        r.advertisementData.serviceUuids.any(_serviziScanner.contains);
  }

  /// Gli scanner in cima, poi i più vicini; senza "mostra tutti" solo scanner
  List<ScanResult> get _dispositivi =>
      _risultati
          .where((r) => _mostraTutti ? _nome(r).isNotEmpty : _isScanner(r))
          .toList()
        ..sort((a, b) {
          if (_isScanner(a) != _isScanner(b)) return _isScanner(a) ? -1 : 1;
          return b.rssi.compareTo(a.rssi);
        });

  int get _altriDispositivi =>
      _risultati.where((r) => _nome(r).isNotEmpty && !_isScanner(r)).length;

  IconData _iconaSegnale(int rssi) {
    if (rssi >= -60) return Icons.signal_cellular_alt;
    if (rssi >= -80) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          'Seleziona scanner',
          style: TextStyle(
            color: kBluScuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: kBluScuro),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          if (_adapterState == BluetoothAdapterState.on)
            _scanning
                ? IconButton(
                  tooltip: 'Interrompi ricerca',
                  icon: const Icon(Icons.stop_circle_outlined),
                  onPressed: FlutterBluePlus.stopScan,
                )
                : IconButton(
                  tooltip: 'Cerca di nuovo',
                  icon: const Icon(Icons.refresh),
                  onPressed: _avviaScansione,
                ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child:
              _scanning
                  ? const LinearProgressIndicator(minHeight: 3, color: kPrimary)
                  : const SizedBox(height: 3),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_adapterState == BluetoothAdapterState.unknown) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_adapterState != BluetoothAdapterState.on) {
      return _messaggio(
        icon: Icons.bluetooth_disabled,
        titolo: 'Bluetooth disattivato',
        testo: 'Attiva il Bluetooth per cercare lo scanner.',
        azione:
            Platform.isAndroid
                ? TextButton(
                  onPressed: () => FlutterBluePlus.turnOn(),
                  child: const Text('Attiva Bluetooth'),
                )
                : null,
      );
    }

    final dispositivi = _dispositivi;
    if (dispositivi.isEmpty) {
      return _scanning
          ? _messaggio(
            icon: Icons.bluetooth_searching,
            titolo: 'Ricerca in corso…',
            testo: 'Assicurati che lo scanner sia acceso e vicino al telefono.',
          )
          : _messaggio(
            icon: Icons.search_off,
            titolo: 'Nessuno scanner trovato',
            testo: 'Accendi lo scanner e riprova.',
            azione: Column(
              children: [
                TextButton(
                  onPressed: _avviaScansione,
                  child: const Text('Cerca di nuovo'),
                ),
                if (_altriDispositivi > 0) _toggleMostraTutti(),
              ],
            ),
          );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dispositivi.length + 1,
      itemBuilder: (_, i) {
        if (i == dispositivi.length) {
          return _altriDispositivi > 0 || _mostraTutti
              ? Center(child: _toggleMostraTutti())
              : const SizedBox.shrink();
        }
        final r = dispositivi[i];
        final scanner = _isScanner(r);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (scanner ? kGreen : kPrimary).withValues(
                alpha: 0.12,
              ),
              child: Icon(
                scanner ? Icons.qr_code_scanner : Icons.bluetooth,
                color: scanner ? kGreen : kPrimary,
              ),
            ),
            title: Text(
              _nome(r),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              scanner ? 'Scanner barcode' : r.device.remoteId.str,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconaSegnale(r.rssi), size: 18, color: Colors.black45),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _seleziona(r.device),
          ),
        );
      },
    );
  }

  Widget _toggleMostraTutti() {
    return TextButton(
      onPressed: () => setState(() => _mostraTutti = !_mostraTutti),
      child: Text(
        _mostraTutti
            ? 'Mostra solo gli scanner'
            : 'Mostra tutti i dispositivi ($_altriDispositivi)',
      ),
    );
  }

  Widget _messaggio({
    required IconData icon,
    required String titolo,
    required String testo,
    Widget? azione,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: kPrimary),
            const SizedBox(height: 12),
            Text(
              titolo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kBluScuro,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              testo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            if (azione != null) ...[const SizedBox(height: 12), azione],
          ],
        ),
      ),
    );
  }
}
