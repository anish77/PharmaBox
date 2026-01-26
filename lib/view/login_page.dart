import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/web.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_cubit.dart';
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
  final logger = Logger(printer: PrettyPrinter());

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  var _enteredEmail = '';
  var _enteredPassword = '';
  bool _rememberCredentials = false;
  bool _isLoading = false;

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
            (savedEmail?.isNotEmpty ?? false) &&
            (savedPassword?.isNotEmpty ?? false);
      });
    } catch (e) {
      logger.e('Errore caricamento credenziali $e');
    }
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final credentials = await _firebase.signInWithEmailAndPassword(
        email: _enteredEmail.trim(),
        password: _enteredPassword.trim(),
      );

      logger.i('Login OK: ${credentials.user?.email}');

      if (_rememberCredentials) {
        await _secureStorage.write(
          key: 'login_email',
          value: _enteredEmail.trim(),
        );
        await _secureStorage.write(
          key: 'login_password',
          value: _enteredPassword.trim(),
        );
      } else {
        await _secureStorage.delete(key: 'login_email');
        await _secureStorage.delete(key: 'login_password');
      }

      if (!mounted) return;

      context.read<SubscriptionCubit>().checkProStatus();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreaNuovaLista()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Errore di autenticazione';
      if (e.code == 'wrong-password') message = 'Password errata';
      if (e.code == 'user-not-found') message = 'Utente non trovato';
      if (e.code == 'invalid-email') message = 'Email non valida';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );

      logger.e('Login error $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.of(context).size.height -
                              45 - // spazio bottone
                              kToolbarHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
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
                                    const SizedBox(height: 40),

                                    CustomTextFormField(
                                      label: 'Email',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator:
                                          (v) =>
                                              (v == null || !v.contains('@'))
                                                  ? kEmailError
                                                  : null,
                                      onChanged: (v) => _enteredEmail = v,
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextFormField(
                                      label: 'Password',
                                      controller: _passwordController,
                                      obscureText: true,
                                      enableVisibilityToggle: true,
                                      validator:
                                          (v) =>
                                              (v == null || v.length < 6)
                                                  ? kPasswordError
                                                  : null,
                                      onChanged: (v) => _enteredPassword = v,
                                    ),

                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: _rememberCredentials,
                                      activeColor: kPrimary,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: const Text('Ricorda credenziali'),
                                      onChanged:
                                          (v) => setState(
                                            () =>
                                                _rememberCredentials =
                                                    v ?? false,
                                          ),
                                    ),

                                    const SizedBox(height: 24),
                                    CustomButton(
                                      title: "Accedi",
                                      titleColor: Colors.white,
                                      backgroundColor: kPrimary,
                                      onPressed: () {
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          return;
                                        }
                                        _submitLogin();
                                      },
                                    ),

                                    TextButton(
                                      onPressed: () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => const ForgotPassword(),
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
                            ],
                          ),
                        ),
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
                          title: 'Crea nuovo account',
                          titleColor: kPrimary,
                          backgroundColor: kSecondary,
                          onPressed: () {
                            FocusScope.of(context).unfocus(); // chiude tastiera
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NewAccountPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
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
