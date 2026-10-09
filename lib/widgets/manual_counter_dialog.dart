import 'package:flutter/material.dart';

class ManualCounterDialog extends StatefulWidget {
  const ManualCounterDialog({super.key, required this.initialValue});

  final int initialValue;

  @override
  State<ManualCounterDialog> createState() => ManualCounterDialogState();
}

class ManualCounterDialogState extends State<ManualCounterDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialValue}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica quantità'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Numero pezzi',
          errorText: _errorMessage,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        TextButton(onPressed: _submit, child: const Text('Salva')),
      ],
    );
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text);
    if (parsed == null || parsed < 0) {
      setState(() {
        _errorMessage = 'Inserisci un numero valido.';
      });
      return;
    }
    Navigator.of(context).pop(parsed);
  }
}
