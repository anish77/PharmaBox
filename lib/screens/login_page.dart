import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/screens/new_account_page.dart';
import 'package:pharma_box/widgets/custom_button.dart';

final _firebase = FirebaseAuth.instance;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  var logger = Logger(printer: PrettyPrinter());

  var _enteredEmail = '';
  var _enteredPassword = '';
  bool _isLoading = false;

  void _submitLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredentials = await _firebase.signInWithEmailAndPassword(
        email: _enteredEmail.trim(),
        password: _enteredPassword.trim(),
      );

      logger.i('Login successful: ${userCredentials.user?.email}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login effettuato con successo'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (error) {
      String message = 'Errore di autenticazione';
      if (error.code == 'wrong-password') {
        message = 'Password errata';
      } else if (error.code == 'user-not-found') {
        message = 'Utente non trovato';
      } else if (error.code == 'invalid-email') {
        message = 'Email non valida';
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );

      logger.e('Login failed: ${error.message}');
      logger.i(error.code);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFullScreenLoader() {
    if (!_isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: const Center(child: CircularProgressIndicator(color: kPrimary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo + Brand
                              Column(
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
                              const SizedBox(height: 40),

                              // Email field
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: kPrimary),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: kPrimary),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      !value.contains('@')) {
                                    return kEmailError;
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredEmail = value ?? '';
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: kPrimary),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: kPrimary),
                                  ),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 6) {
                                    return kPasswordError;
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredPassword = value ?? '';
                                },
                              ),
                              const SizedBox(height: 24),

                              // Login Button
                              CustomButton(
                                title: "Accedi",
                                titleColor: Colors.white,
                                backgroundColor: kPrimary,
                                onPressed: () {
                                  final isValid =
                                      _formKey.currentState!.validate();
                                  if (!isValid) return;
                                  _formKey.currentState!.save();
                                  _submitLogin();
                                },
                              ),
                              const SizedBox(height: 16),

                              // Forgot password
                              TextButton(
                                onPressed: () {
                                  // TODO: implement password reset
                                },
                                child: const Text(
                                  'Password dimenticata?',
                                  style: TextStyle(
                                    color: kPrimary,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottone crea account
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CustomButton(
                      title: "Crea nuovo account",
                      titleColor: kPrimary,
                      backgroundColor: kSecondary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => const NewAccountPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loader full screen fuori SafeArea così copre tutto
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: kPrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
