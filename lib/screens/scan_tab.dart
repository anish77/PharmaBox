import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pharma_box/data/constants.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  bool _bluetoothOn = false;
  bool _scannerReady = false;

  @override
  void initState() {
    super.initState();
    // ascolta lo stato dell'adapter e aggiorna la UI
    FlutterBluePlus.adapterState.listen((s) {
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
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final imagePath = _scannerReady ? kScanCode : kBluetoothImage;
    final label = _scannerReady ? 'Scan code' : 'collega il tuo scanner';

    return Align(
      alignment: Alignment.topCenter,
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
              color: _scannerReady ? null : kPrimary,
              colorBlendMode: _scannerReady ? null : BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: kBluScuro,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
