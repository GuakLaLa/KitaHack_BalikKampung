import 'package:floodsense/components/my_textfield.dart';
import 'package:floodsense/navigation.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'signup_page.dart';
import 'forgot_password.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon( 
                Icons.water_drop,
                color: Colors.blue.shade400,
                size: 100,
              ),

              const SizedBox(height: 25),

              Text( 
                'Welcome Back to FloodSense',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 25),

              MyTextField(
                controller: emailController,
                labelText: "Email",
                obscureText: false,
              ),

              const SizedBox(height: 10),

              MyTextField(
                controller: passwordController,
                labelText: "Password",
                obscureText: true,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                try {
                  final user = await authService.loginWithEmailPassword(
                    emailController.text.trim(),
                    passwordController.text,
                  );

                  if (!context.mounted) return;

                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      title: const Text("Login Success ✅"),
                      content: const Text("Welcome back to FloodSense!"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("Continue"),
                        ),
                      ],
                    ),
                  );

                  if (!context.mounted) return;

                  //Navigate to HomePage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => NavigationPage()),
                  );

                } catch (e) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Login Failed ❌"),
                      content: Text(e.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              },

                child: const Text("Login"),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
                  );
                },
                child: const Text("Forgot Password?"),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignupPage()),
                  );
                },
                child: const Text("Create Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
