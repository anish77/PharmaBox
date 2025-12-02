import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/view/forgot_password.dart';
import 'package:pharma_box/view/crea_nuova_lista.dart';
import 'package:pharma_box/view/new_account_page.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/custom_text_form_field.dart';

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
  bool _rememberCredentials = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedEmail = await _secureStorage.read(key: 'login_email');
      final savedPassword = await _secureStorage.read(key: 'login_password');
      if (!mounted) return;
      _emailController.text = savedEmail ?? '';
      _passwordController.text = savedPassword ?? '';
      setState(() {
        _enteredEmail = savedEmail ?? '';
        _enteredPassword = savedPassword ?? '';
        _rememberCredentials =
            (savedEmail != null && savedEmail.isNotEmpty) &&
            (savedPassword != null && savedPassword.isNotEmpty);
      });
    } catch (error, stackTrace) {
      logger.e(
        'Errore nel caricare credenziali salvate: $error',
        stackTrace: stackTrace,
      );
    }
  }

  void _submitLogin() async {
    final email = _enteredEmail.trim();
    final password = _enteredPassword.trim();
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredentials = await _firebase.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      logger.i('Login successful: ${userCredentials.user?.email}');

      if (_rememberCredentials) {
        await _secureStorage.write(key: 'login_email', value: email);
        await _secureStorage.write(key: 'login_password', value: password);
      } else {
        await _secureStorage.delete(key: 'login_email');
        await _secureStorage.delete(key: 'login_password');
      }
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (ctx) => const CreaNuovaLista()),
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

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).clearSnackBars();
      // ignore: use_build_context_synchronously
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Padding(
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
                              CustomTextFormField(
                                label: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
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
                                onChanged: (value) {
                                  _enteredEmail = value;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Password field
                              CustomTextFormField(
                                label: 'Password',
                                obscureText: true,
                                enableVisibilityToggle: true,
                                controller: _passwordController,
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
                                onChanged: (value) {
                                  _enteredPassword = value;
                                },
                              ),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _rememberCredentials,
                                activeColor: kPrimary,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: const Text('Ricorda credenziali'),
                                onChanged: (value) {
                                  setState(() {
                                    _rememberCredentials = value ?? false;
                                  });
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
                                  _enteredEmail = _emailController.text;
                                  _enteredPassword = _passwordController.text;
                                  _submitLogin();
                                },
                              ),
                              // const SizedBox(height: 6),

                              // Forgot password
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ForgotPassword(),
                                    ),
                                  );
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
                    padding: const EdgeInsets.only(bottom: 45),
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
      ),
    );
  }
}
