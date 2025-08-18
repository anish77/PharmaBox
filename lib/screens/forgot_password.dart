import 'package:flutter/material.dart';
import 'package:pharma_box/data/constants.dart';
import 'package:pharma_box/widgets/custom_button.dart';
import 'package:pharma_box/widgets/custom_text_form_field.dart';

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("")),
      backgroundColor: kBackGround,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 45),
              child: Text(kForgotPasswordTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
            ),
            const SizedBox(height: 20),
            CustomTextFormField(label: "Email"),
            const SizedBox(height: 20),
            Text(kForgotPassword, style: TextStyle(fontSize: 16)),
            // Questo Spacer spinge tutto in basso
            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 45),
              child: CustomButton(
                title: "Invia",
                titleColor: Colors.white,
                backgroundColor: kPrimary,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
