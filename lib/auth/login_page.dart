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

  final _formKey = GlobalKey<FormState>();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  final emailFieldKey = GlobalKey<FormFieldState>();
  final passwordFieldKey = GlobalKey<FormFieldState>();
  
  bool isLoginSelected = true; //controls switch UI

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    emailFocus.dispose();
    passwordFocus.dispose();

    super.dispose();
  }    

    @override
  void initState() {
    super.initState();

    _setupFocusValidation(emailFocus, emailFieldKey);
    _setupFocusValidation(passwordFocus, passwordFieldKey);

  }
  
  // Validation
  void _setupFocusValidation(FocusNode focusNode, GlobalKey<FormFieldState> key) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        key.currentState?.validate();
      }
    });
  }

  Future<void> _handleLogin() async {

    if (!_formKey.currentState!.validate()) return;

    try {
      // 🔐 Login using Firebase Auth
      final userCredential = await authService.loginWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (userCredential == null) {
        throw Exception("Login failed.");
      }

      if (!context.mounted) return;

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        throw Exception("User ID not found.");
      }

      // 🔎 Get user role from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User record not found.");
      }

      final role = userDoc.data()?["role"] ?? "user";

      //Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Login Success ✅"),
          content: const Text("Welcome back to FloodSense!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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

    } on FirebaseAuthException catch (e) {
        // Map technical message to friendly message
        final message = getFriendlyErrorMessage(e);
        _showError(message);

      } catch (e) {
        // Any other errors
        _showError("Something went wrong. Please try again later.");
      }
  }

  String getFriendlyErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return "No account found with this email.";
    case 'wrong-password':
      return "Incorrect password. Please try again.";
    case 'invalid-email':
      return "Invalid email address.";
    case 'user-disabled':
      return "This account has been disabled.";
    case 'too-many-requests':
      return "Too many login attempts. Please try again later.";
    default:
      return "Login failed. Please check your email and password.";
  }
}

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Failed ❌"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
            child: Form(  
              key: _formKey,
          child: Column(
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
                        behavior: HitTestBehavior.opaque,
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
                        behavior: HitTestBehavior.opaque,
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
                fieldKey: emailFieldKey,
                focusNode: emailFocus,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your email.";
                  }
                  // Basic email format validation
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return "Please enter a valid email address.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              MyTextField(
                controller: passwordController,
                labelText: "Password",
                obscureText: true,
                fieldKey: passwordFieldKey,
                focusNode: passwordFocus,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your password.";
                  }
                  if (value.length < 6) {
                    return "Password must be at least 6 characters.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8CCCD3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.center,
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
      ),
    );
  }
}
