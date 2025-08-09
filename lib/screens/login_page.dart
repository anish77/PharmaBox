import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/screens/new_account_page.dart';
import 'package:pharma_box/widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  bool _isLogin = true; // Toggle between login and signup
  var _enteredEmail = '';
  var _enteredPassword = '';

  void _submitLogin() {
    final isValid = _form.currentState?.validate();
    /*
    if (!isValid) {
      return;
    }

    _form.currentSatte.save();

    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Contenuto centrale
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo + Brand Name
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
                            if (value == null || value.trim().length < 6) {
                              return kPasswordError;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        CustomButton(
                          title: "Accedi",
                          titleColor: Colors.white,
                          backgroundColor: kPrimary,
                          onPressed: () {},
                        ),
                        const SizedBox(height: 16),

                        // Forgot password
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Password dimenticata?',
                            style: TextStyle(color: kPrimary, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottone in fondo
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CustomButton(
                  title: "Crea nuovo account",

                  titleColor: kPrimary,
                  backgroundColor: kSecondary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => NewAccountPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
