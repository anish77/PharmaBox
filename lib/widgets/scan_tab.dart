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
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;

  @override
  void initState() {
    super.initState();
    // ascolta lo stato dell'adapter e aggiorna la UI
    _adapterSubscription = FlutterBluePlus.adapterState.listen((s) {
      if (mounted) {
        setState(() {
          _scannerReady();
        });
      }
    });
    // check iniziale
    _scannerReady();
  }

  Future<void> _scannerReady() async {
    if (widget.statusLabel == 'Disconnesso' || widget.statusLabel.isEmpty) {
      _bluetoothOn = false;
    } else {
      _bluetoothOn = true;
    }
  }

  @override
  void dispose() {
    _adapterSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scannerReady();
    final h = MediaQuery.of(context).size.height;
    final imagePath = _bluetoothOn ? kScanCode : kBluetoothImage;
    final computedLabel =
        _bluetoothOn
            ? (widget.statusLabel.isNotEmpty ? widget.statusLabel : 'Scan code')
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
                color: _bluetoothOn || widget.isScanning ? null : kPrimary,
                colorBlendMode:
                    _bluetoothOn || widget.isScanning ? null : BlendMode.srcIn,
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
