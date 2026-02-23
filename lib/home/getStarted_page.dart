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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/get_started_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Predict Early (LEFT)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Predict Early',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            offset: Offset(2, 3),
                            color: Colors.black26,
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Act Faster (RIGHT)
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Act Faster',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            offset: Offset(2, 3),
                            color: Colors.black26,
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stay Safe (LEFT)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Stay Safe',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            offset: Offset(2, 3),
                            color: Colors.black26,
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),

                  // Subtitle
                  const Text(
                    'When floods rise, we guide you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA6E3E9),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await onFinished();
                      },
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sign Up Link
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
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
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
