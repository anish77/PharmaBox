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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'firstName': _enteredFirstName,
            'lastName': _enteredLastName,
            'email': _enteredEmail,
            'phoneNumber': _enteredPhoneNumber,
            'uid': userCredential.user!.uid,
            'password': _enteredPassword,
            'liste': [],
          });

      logger.i('Account created: $userCredential');
      logger.i('Password: $_enteredPassword');
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackGround,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _form,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo + Brand Name
                          SingleChildScrollView(
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

                          CustomTextFormField(
                            label: 'Nome',
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 45),
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
    );
  }
}
