import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/custom_text_form_field.dart';

class NewAccountPage extends StatelessWidget {
  NewAccountPage({super.key});

  final _formKey = GlobalKey<FormState>();

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
            key: _formKey,
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

                          CustomTextFormField(label: 'Nome'),
                          const SizedBox(height: 16),

                          CustomTextFormField(label: 'Cognome'),
                          const SizedBox(height: 16),

                          CustomTextFormField(
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
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

                          CustomTextFormField(
                            label: 'Password',
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return kPasswordError;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          CustomButton(
                            title: "Crea Account",
                            titleColor: Colors.white,
                            backgroundColor: kPrimary,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                // ✅ campi validi
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
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
