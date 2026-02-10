import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:floodsense/home/getStarted_page.dart';
import 'package:floodsense/navigation.dart';
import 'package:floodsense/auth/login_page.dart';

class AppStartGate extends StatefulWidget {
  const AppStartGate({super.key});

  @override
  State<AppStartGate> createState() => _AppStartGateState();
}

class _AppStartGateState extends State<AppStartGate> {
  bool? isFirstLaunch;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenGetStarted') ?? false;

    setState(() {
      isFirstLaunch = !seen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstLaunch == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // FIRST LAUNCH → Get Started
    if (isFirstLaunch!) {
      return GetStartedPage(
        onFinished: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('seenGetStarted', true);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NavigationPage()),
          );
        },
      );
    }

    // NOT FIRST LAUNCH
    final user = FirebaseAuth.instance.currentUser;

    // Guest OR Logged-in → Home
    return const NavigationPage();
  }
}
