import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/custom_text_form_field.dart';

final _firebase = FirebaseAuth.instance;

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  late final TextEditingController _emailController;
  late String _enteredEmail;

  @override
  void initState() {
    super.initState();
    _enteredEmail = widget.initialEmail;
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (!kRegexEmail.hasMatch(_enteredEmail.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Inserisci una email valida per reimpostare la password",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firebase.sendPasswordResetEmail(email: _enteredEmail.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se l’indirizzo è associato a un account, riceverai un’email '
            'con le istruzioni per reimpostare la password.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) Navigator.pop(context);
      });
    } on FirebaseAuthException catch (error) {
      String message = "Errore durante il reset";
      if (error.code == 'too-many-requests') {
        message = 'Troppe richieste. Attendi qualche minuto e riprova.';
      } else if (error.code == 'invalid-email') {
        message = 'Indirizzo email non valido.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: kBluScuro),
          centerTitle: false,
          titleSpacing: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo + Brand Name
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            Image.asset(kLogo, height: 70, width: 70),
                            const SizedBox(height: 8),
                            const Text(
                              kAppName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        kForgotPasswordTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: kBluScuro,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        label: "Email",
                        controller: _emailController,
                        onChanged: (value) {
                          setState(() {
                            _enteredEmail = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        kForgotPassword,
                        style: const TextStyle(fontSize: 16, color: kBluScuro),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                left: false,
                right: false,
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      title: "Invia",
                      titleColor: Colors.white,
                      backgroundColor: kPrimary,
                      onPressed: _resetPassword,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
