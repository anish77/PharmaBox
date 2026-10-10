import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/include/ble_functions.dart';
import 'package:pharma_box/logic/open_email.dart';

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
          'Collega il tuo Bluetooth',
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
    final dispositivi = _dispositivi;
    final bluetoothOn = _adapterState == BluetoothAdapterState.on;

    return ColoredBox(
      color: kBackGround,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Image.asset(
                      kScannerBle,
                      height: 210,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => const SizedBox(
                            height: 210,
                            child: Icon(
                              Icons.bluetooth_searching,
                              size: 120,
                              color: kPrimary,
                            ),
                          ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Collega il tuo scanner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kBluScuro,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tocca il pulsante qui sotto per avviare la connessione '
                      'Bluetooth.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kBluScuro.withValues(alpha: 0.75),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed:
                            _adapterState == BluetoothAdapterState.unknown ||
                                    !bluetoothOn ||
                                    _scanning
                                ? null
                                : _avviaScansione,
                        icon:
                            _scanning
                                ? const SizedBox(
                                  width: 21,
                                  height: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.bluetooth_searching),
                        label: Text(
                          _scanning ? 'Ricerca scanner…' : 'Connetti scanner',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _connectionStatusCard(bluetoothOn),
                    if (dispositivi.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const Text(
                        'Dispositivi trovati',
                        style: TextStyle(
                          color: kBluScuro,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final result in dispositivi) _deviceTile(result),
                      if (_altriDispositivi > 0 || _mostraTutti)
                        Center(child: _toggleMostraTutti()),
                    ] else if (bluetoothOn && !_scanning)
                      _nessunoScanner(),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: () => OpenEmail().openWebsite(kLinkScanner),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text(
                        'Non hai uno scanner? Scopri quelli compatibili',
                        textAlign: TextAlign.center,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimary,
                        textStyle: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    if (_adapterState == BluetoothAdapterState.unknown)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!bluetoothOn &&
                        _adapterState != BluetoothAdapterState.unknown &&
                        Platform.isAndroid)
                      Center(
                        child: TextButton(
                          onPressed: () => FlutterBluePlus.turnOn(),
                          child: const Text('Attiva Bluetooth'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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

  Widget _connectionStatusCard(bool bluetoothOn) {
    final title =
        _adapterState == BluetoothAdapterState.unknown
            ? 'Controllo Bluetooth…'
            : !bluetoothOn
            ? 'Bluetooth disattivato'
            : _scanning
            ? 'Ricerca dispositivi in corso'
            : _dispositivi.isEmpty
            ? 'Scanner non connesso'
            : 'Seleziona il tuo scanner';
    final message =
        !bluetoothOn
            ? 'Attiva il Bluetooth e assicurati che lo scanner sia acceso e '
                'vicino al telefono.'
            : _scanning
            ? 'Assicurati che lo scanner sia acceso e già associato al '
                'dispositivo.'
            : _dispositivi.isEmpty
            ? 'Accendi lo scanner Bluetooth e avvia la ricerca per collegarlo.'
            : 'Tocca il nome dello scanner nell’elenco per completare la '
                'connessione.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBluScuro.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: kBluScuro.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            bluetoothOn ? Icons.info_outline : Icons.bluetooth_disabled,
            color: bluetoothOn ? kPrimary : Colors.orange,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kBluScuro,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: kBluScuro.withValues(alpha: 0.65),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceTile(ScanResult result) {
    final scanner = _isScanner(result);
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
          _nome(result),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          scanner ? 'Scanner barcode' : result.device.remoteId.str,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconaSegnale(result.rssi), size: 18, color: Colors.black45),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _seleziona(result.device),
      ),
    );
  }

  /// Ricerca finita senza scanner: si può riprovare o vedere gli altri dispositivi
  Widget _nessunoScanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 56, color: kPrimary),
          const SizedBox(height: 12),
          const Text(
            'Nessuno scanner trovato',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kBluScuro,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Accendi lo scanner e riprova.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _avviaScansione,
            child: const Text('Cerca di nuovo'),
          ),
          if (_altriDispositivi > 0) _toggleMostraTutti(),
        ],
      ),
    );
  }
}
