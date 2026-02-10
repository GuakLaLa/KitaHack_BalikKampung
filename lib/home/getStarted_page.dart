import 'package:floodsense/auth/login_page.dart';
import 'package:floodsense/auth/signup_page.dart';
import 'package:flutter/material.dart';

class GetStartedPage extends StatelessWidget {
  final Future<void> Function() onFinished;

  const GetStartedPage({
    super.key,
    required this.onFinished,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to FloodSense',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              ///Button → Finish Get Started
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await onFinished();
                  },
                  child: const Text('Get Started'),
                ),
              ),

              const SizedBox(height: 20),

              //Text → Sign Up
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignupPage(),
                    ),
                  );
                },
                child: const Text(
                  'Don’t have an account? Sign up',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
