import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pharma_box/data/constants.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({
    super.key,
    required this.isScanning,
    required this.onToggleScan,
    required this.statusLabel,
  });

  final bool isScanning;
  final VoidCallback onToggleScan;
  final String statusLabel;

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  bool _bluetoothOn = false;
  bool _scannerReady = false;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;

  @override
  void initState() {
    super.initState();
    // ascolta lo stato dell'adapter e aggiorna la UI
    _adapterSubscription = FlutterBluePlus.adapterState.listen((s) {
      final isOn = s == BluetoothAdapterState.on;
      if (mounted) {
        setState(() => _bluetoothOn = isOn);
      }
      _updateScannerStatus();
    });
    // check iniziale
    _updateScannerStatus();
  }

  Future<void> _updateScannerStatus() async {
    try {
      if (!_bluetoothOn) {
        if (mounted) setState(() => _scannerReady = false);
        return;
      }
      // considera "associato" se esiste almeno un dispositivo BLE connesso
      final connected = await FlutterBluePlus.connectedDevices;
      final ready = connected.isNotEmpty;
      if (mounted) setState(() => _scannerReady = ready);
    } catch (_) {
      if (mounted) setState(() => _scannerReady = false);
    }
  }

  @override
  void didUpdateWidget(covariant ScanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isScanning != widget.isScanning && mounted) {
      // Forza un rebuild per riflettere lo stato corrente nella UI.
      setState(() {});
    }
  }

  @override
  void dispose() {
    _adapterSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final imagePath = _scannerReady ? kScanCode : kBluetoothImage;
    final computedLabel = _scannerReady
        ? (widget.statusLabel.isNotEmpty
            ? widget.statusLabel
            : 'Scan code')
        : 'collega il tuo scanner';

    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggleScan,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: h * 0.10),
            SizedBox(
              height: h * 0.30,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                color: _scannerReady || widget.isScanning ? null : kPrimary,
                colorBlendMode:
                    _scannerReady || widget.isScanning ? null : BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              computedLabel,
              style: const TextStyle(
                fontSize: 16,
                color: kBluScuro,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
