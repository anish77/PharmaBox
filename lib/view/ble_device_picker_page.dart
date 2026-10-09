import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/ble_functions.dart';

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

  bool _isScanner(ScanResult r) => _nome(r) == kNomeScannerBle;

  /// Solo dispositivi con un nome; lo scanner compatibile in cima, poi i più vicini
  List<ScanResult> get _dispositivi =>
      _risultati.where((r) => _nome(r).isNotEmpty).toList()..sort((a, b) {
        if (_isScanner(a) != _isScanner(b)) return _isScanner(a) ? -1 : 1;
        return b.rssi.compareTo(a.rssi);
      });

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
            titolo: 'Nessun dispositivo trovato',
            testo: 'Accendi lo scanner e riprova.',
            azione: TextButton(
              onPressed: _avviaScansione,
              child: const Text('Cerca di nuovo'),
            ),
          );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dispositivi.length,
      itemBuilder: (_, i) {
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
              scanner ? 'Scanner compatibile' : r.device.remoteId.str,
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
