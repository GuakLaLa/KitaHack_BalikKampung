import 'package:floodsense/components/my_textfield.dart';
import 'package:floodsense/navigation.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'signup_page.dart';
import 'forgot_password.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floodsense/admin/admin_navigation.dart';   // change path if needed


class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();
  
  bool isLoginSelected = true; //controls switch UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [

              /// 🔹 SWITCH BOX (Login | Sign Up)
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
                          setState(() {
                            isLoginSelected = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isLoginSelected
                                ? const Color(0xFF8CCCD3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "Login",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// SIGN UP TAB
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => SignupPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: const Center(
                            child: Text(
                              "Sign Up",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),

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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                onPressed: () async {

                  // Validation
                    if (emailController.text.isEmpty ||
                        passwordController.text.isEmpty) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill in all fields"),
                        ),
                      );
                      return;
                    }

                try {
                  final user = await authService.loginWithEmailPassword(
                    emailController.text.trim(),
                    passwordController.text,
                  );

                  if (!context.mounted) return;

                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  final userDoc =await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .get();

                  if (!userDoc.exists) {
                    throw Exception("User record not found in database.");
                  }

                  final data = userDoc.data();
                  if (data == null) {
                    throw Exception("User data is empty.");
                  }

                  final role = data["role"] ?? "user";

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

                  // 🔥 Role-based navigation
                  if (role == "admin") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminNavigationPage(),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NavigationPage(),
                      ),
                    );
                  }

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

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8CCCD3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),

                child: const Text("Login",
                style: TextStyle(color: Colors.black)),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
                    );
                  },
                  child: const Text("Forgot Password?", style: TextStyle(color: Colors.blueGrey),),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
