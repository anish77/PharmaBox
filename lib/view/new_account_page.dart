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
      final expirationDate = DateTime(
        1970,
      ); //--> Data espirata cosi deve fare l'upgrade

      await firestore.collection('users').doc(uid).set({
        'firstName': _enteredFirstName,
        'lastName': _enteredLastName,
        'email': _enteredEmail,
        'phoneNumber': _enteredPhoneNumber,
        'uid': uid,
        'password': _enteredPassword,
        'liste': [],
        'isActive': false,
        'newMember': true,
        'expirationDate': Timestamp.fromDate(expirationDate),
        'codiceInvito': codiceInvito,
        'amiciInvitati': [],
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
        backgroundColor: kBackGround,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _form,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 160 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return kNomeError;
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredFirstName = value!;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          label: 'Cognome',
                          labelStyle: const TextStyle(color: kBluScuro),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return kCognomeError;
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredLastName = value!;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          label: 'Email',
                          labelStyle: const TextStyle(color: kBluScuro),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null &&
                                isEmailCorrect(value) == false) {
                              return kEmailError;
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredEmail = value!;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          label: 'Cellulare',
                          labelStyle: const TextStyle(color: kBluScuro),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value != null &&
                                isCellCorrect(value) == false) {
                              return kCellError;
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredPhoneNumber = value!;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          label: 'Password',
                          labelStyle: const TextStyle(color: kBluScuro),
                          obscureText: true,
                          validator: (value) {
                            if (value != null &&
                                isPasswordSecure(value) == false) {
                              return kPasswordError;
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredPassword = value!;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 45,
                    child: CustomButton(
                      title: "Crea Account",
                      titleColor: Colors.white,
                      backgroundColor: kPrimary,
                      onPressed: () {
                        final isValid = _form.currentState!.validate();
                        if (!isValid) {
                          return;
                        }
                        _form.currentState!.save();
                        _submitLogin();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
