import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/custom_text_form_field.dart';

final _firebase = FirebaseAuth.instance;

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  var _enteredEmail = '';

  Future<bool> checkIfEmailExists(String email) async {
    try {
      // provo a creare un utente "finto"
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: "passwordFinta123!",
          );

      // se non lancia errore → l'email era libera, quindi elimino subito l'utente
      await credential.user?.delete();
      return false; // NON esisteva prima
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return true; // esiste già
      }
      rethrow; // altri errori (tipo email non valida, ecc.)
    }
  }

  void _resetPassword() async {
    if (_enteredEmail.trim().isEmpty || !_enteredEmail.contains('@')) {
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
      if (await checkIfEmailExists(_enteredEmail)) {
        await _firebase.sendPasswordResetEmail(email: _enteredEmail.trim());
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Email di reset inviata! Controlla la tua casella di posta.",
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Questa email non esiste"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } on FirebaseAuthException catch (error) {
      String message = "Errore durante il reset";
      if (error.code == 'user-not-found') {
        message = "Nessun utente trovato con questa email";
      }
      // ignore: use_build_context_synchronously
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
          backgroundColor: kBackGround,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kPrimary),
            onPressed: () => Navigator.pop(context),
          ),
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
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 45,
                ), //45  EdgeInsets.fromLTRB(16, 40, 16, 0)
                child: CustomButton(
                  title: "Invia",
                  titleColor: Colors.white,
                  backgroundColor: kPrimary,
                  onPressed: _resetPassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
