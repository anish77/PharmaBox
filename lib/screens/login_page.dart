import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
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
                    disabledBorder: OutlineInputBorder(
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
                    return null; // Valid email
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimary),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimary),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().length < 6) {
                      return kPasswordError;
                    }
                    return null; // Valid password
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Azione login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Forgot password
                TextButton(
                  onPressed: () {
                    // Azione recupero password
                  },
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: kPrimary, fontSize: 18),
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
