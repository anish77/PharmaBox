import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/view/crea_nuova_lista.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/custom_text_form_field.dart';

final _firebase = FirebaseAuth.instance;

class NewAccountPage extends StatefulWidget {
  const NewAccountPage({super.key});

  @override
  State<NewAccountPage> createState() {
    return _NewAccountPageState();
  }
}

class _NewAccountPageState extends State<NewAccountPage> {
  final _form = GlobalKey<FormState>();
  var logger = Logger(printer: PrettyPrinter());

  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredFirstName = '';
  var _enteredLastName = '';
  var _enteredPhoneNumber = '';

  void _submitLogin() async {
    try {
      final userCredential = await _firebase.createUserWithEmailAndPassword(
        email: _enteredEmail,
        password: _enteredPassword,
      );

      final uid = userCredential.user!.uid;
      final codiceInvito =
          uid.substring(10, 16).toUpperCase(); // dalla posizione 11 fino a 16
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('users').doc(uid).set({
        'firstName': _enteredFirstName,
        'lastName': _enteredLastName,
        'email': _enteredEmail,
        'phoneNumber': _enteredPhoneNumber,
        'uid': uid,
        'liste': [],
        'codiceInvito': codiceInvito,
        'isPro': false,
        'subscription': [],
      });

      logger.i('Account created: $userCredential');
      logger.i(
        'info: ${userCredential.user!.uid}, $_enteredEmail, $_enteredFirstName, $_enteredLastName, $_enteredPhoneNumber',
      );

      // Vai a ListsPage
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const CreaNuovaLista()),
      );
    } on FirebaseAuthException catch (error, stack) {
      String message = 'Errore di registrazione';
      if (error.code == 'email-already-in-use') {
        message = 'Email già in uso';
      } else if (error.code == 'invalid-email') {
        message = 'Email non valida';
      } else if (error.code == 'weak-password') {
        message = 'Password troppo debole';
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      logger.e(stack);
    }
  }

  bool isPasswordSecure(String password) {
    return kRegexPassword.hasMatch(password);
  }

  bool isCellCorrect(String cellulare) {
    return kRegexCell.hasMatch(cellulare);
  }

  bool isEmailCorrect(String email) {
    return kRegexEmail.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: kBluScuro),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _form,
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),
                            Align(
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
                            const SizedBox(height: 32),

                            CustomTextFormField(
                              label: 'Nome',
                              labelStyle: const TextStyle(color: kBluScuro),
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? kNomeError
                                          : null,
                              onSaved: (v) => _enteredFirstName = v!,
                            ),
                            const SizedBox(height: 16),

                            CustomTextFormField(
                              label: 'Cognome',
                              labelStyle: const TextStyle(color: kBluScuro),
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? kCognomeError
                                          : null,
                              onSaved: (v) => _enteredLastName = v!,
                            ),
                            const SizedBox(height: 16),

                            CustomTextFormField(
                              label: 'Email',
                              labelStyle: const TextStyle(color: kBluScuro),
                              keyboardType: TextInputType.emailAddress,
                              validator:
                                  (v) =>
                                      v != null && !isEmailCorrect(v)
                                          ? kEmailError
                                          : null,
                              onSaved: (v) => _enteredEmail = v!,
                            ),
                            const SizedBox(height: 16),

                            CustomTextFormField(
                              label: 'Cellulare',
                              labelStyle: const TextStyle(color: kBluScuro),
                              keyboardType: TextInputType.phone,
                              validator:
                                  (v) =>
                                      v != null && !isCellCorrect(v)
                                          ? kCellError
                                          : null,
                              onSaved: (v) => _enteredPhoneNumber = v!,
                            ),
                            const SizedBox(height: 16),

                            CustomTextFormField(
                              label: 'Password',
                              labelStyle: const TextStyle(color: kBluScuro),
                              obscureText: true,
                              enableVisibilityToggle: true,
                              validator:
                                  (v) =>
                                      v != null && !isPasswordSecure(v)
                                          ? kPasswordError
                                          : null,
                              onSaved: (v) => _enteredPassword = v!,
                            ),

                            const SizedBox(height: 120), // spazio per bottone
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
                            title: "Crea Account",
                            titleColor: Colors.white,
                            backgroundColor: kPrimary,
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              if (!_form.currentState!.validate()) return;
                              _form.currentState!.save();
                              _submitLogin();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
