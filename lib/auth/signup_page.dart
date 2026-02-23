import 'package:floodsense/components/my_textfield.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  SignupPage({super.key});

 @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final AuthService authService = AuthService();

  bool isLoginSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// SWITCH BOX
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [

                      /// LOGIN TAB
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LoginPage(),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// SIGNUP TAB
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8CCCD3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                Icon(
                  Icons.water_drop,
                  color: Colors.blue.shade400,
                  size: 100,
                ),

                const SizedBox(height: 25),

                const Text(
                  'Create your FloodSense account',
                  style: TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 25),

                // NAME
                MyTextField(
                  controller: nameController,
                  labelText: "Full Name",
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                // PHONE
                MyTextField(
                  controller: phoneController,
                  labelText: "Phone Number",
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                // EMAIL
                MyTextField(
                  controller: emailController,
                  labelText: "Email",
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                // PASSWORD
                MyTextField(
                  controller: passwordController,
                  labelText: "Password",
                  obscureText: true,
                ),

                const SizedBox(height: 10),

                // CONFIRM PASSWORD
                MyTextField(
                  controller: confirmPasswordController,
                  labelText: "Confirm Password",
                  obscureText: true,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                  onPressed: () async {

                    // Validation
                    if (nameController.text.isEmpty ||
                        phoneController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        passwordController.text.isEmpty) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill in all fields"),
                        ),
                      );
                      return;
                    }

                    if (passwordController.text !=
                        confirmPasswordController.text) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Passwords do not match"),
                        ),
                      );
                      return;
                    }

                    try {
                      await authService.signUp(
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                      );

                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Account Created 🎉"),
                          content: const Text("Welcome to FloodSense!"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LoginPage(),
                                  ),
                                );
                              },
                              child: const Text("Continue"),
                            )
                          ],
                        ),
                      );

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8CCCD3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),

                  child: const Text("Create Account",
                  style: TextStyle(color: Colors.black)),
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
