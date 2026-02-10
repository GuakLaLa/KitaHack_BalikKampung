import 'package:flutter/material.dart';
import 'auth_service.dart';

class ForgotPasswordPage extends StatelessWidget {
  ForgotPasswordPage({super.key});

  final emailController = TextEditingController();
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                await authService.resetPassword(
                  emailController.text,
                );
                Navigator.pop(context);
              },
              child: const Text("Send Reset Email"),
            ),
          ],
        ),
      ),
    );
  }
}
