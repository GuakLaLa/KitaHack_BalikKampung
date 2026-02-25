import 'package:floodsense/components/my_textfield.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  final nameFocus = FocusNode();
  final phoneFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();

  final nameFieldKey = GlobalKey<FormFieldState>();
  final phoneFieldKey = GlobalKey<FormFieldState>();
  final emailFieldKey = GlobalKey<FormFieldState>();
  final passwordFieldKey = GlobalKey<FormFieldState>();
  final confirmPasswordFieldKey = GlobalKey<FormFieldState>();


  bool isLoginSelected = false;

  @override
  void initState() {
    super.initState();

    _setupFocusValidation(nameFocus, nameFieldKey);
    _setupFocusValidation(phoneFocus, phoneFieldKey);
    _setupFocusValidation(emailFocus, emailFieldKey);
    _setupFocusValidation(passwordFocus, passwordFieldKey);
    _setupFocusValidation(confirmPasswordFocus, confirmPasswordFieldKey);
  }

  void _setupFocusValidation(FocusNode focusNode, GlobalKey<FormFieldState> key) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        key.currentState?.validate(); 
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    nameFocus.dispose();
    phoneFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();

    super.dispose();
  }

    String _getFriendlySignupError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "This email is already registered. Please log in instead.";
      case 'invalid-email':
        return "Please enter a valid email address.";
      case 'weak-password':
        return "Password is too weak. Please use at least 6 characters.";
      case 'operation-not-allowed':
        return "Email/password accounts are not enabled.";
      case 'too-many-requests':
        return "Too many attempts. Please try again later.";
      default:
        return "Account creation failed. Please try again.";
    }
  }

    void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sign Up Failed ❌"),
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
          child: SingleChildScrollView(
             child: Form(
                key: _formKey,
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
                          behavior: HitTestBehavior.opaque,
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
                  fieldKey: nameFieldKey ,
                  controller: nameController,
                  labelText: "Full Name",
                  focusNode: nameFocus,
                  obscureText: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Name is required";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // PHONE
                MyTextField(
                  fieldKey: phoneFieldKey,
                  controller: phoneController,
                  labelText: "Phone Number",
                  focusNode: phoneFocus,
                  obscureText: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Phone number is required";
                    }
                    if (value.length < 10) {
                      return "Invalid phone number";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // EMAIL
                MyTextField(
                  fieldKey: emailFieldKey,
                  controller: emailController,
                  labelText: "Email",
                  focusNode: emailFocus,
                  obscureText: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Email is required";
                    }
                    if (!value.contains('@')) {
                      return "Invalid email";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // PASSWORD
                MyTextField(
                  fieldKey: passwordFieldKey,
                  controller: passwordController,
                  labelText: "Password",
                  focusNode: passwordFocus,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // CONFIRM PASSWORD
                MyTextField(
                  fieldKey: confirmPasswordFieldKey,
                  controller: confirmPasswordController,
                  labelText: "Confirm Password",
                  focusNode: confirmPasswordFocus,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm password";
                    }
                    if (value != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                  onPressed: () async {
                    setState(() => _submitted = true);

                    if (!_formKey.currentState!.validate()) {
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
                                  MaterialPageRoute(builder: (_) => LoginPage()),
                                );
                              },
                              child: const Text("Continue"),
                            )
                          ],
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      final message = _getFriendlySignupError(e);
                      _showError(message);
                    } catch (e) {
                      _showError("Something went wrong. Please try again.");
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
    ),
    );
  }
}
