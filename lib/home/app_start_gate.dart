import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floodsense/admin/admin_navigation.dart';
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
  
  Widget? nextPage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenGetStarted') ?? false;

        if (!seen) {
      setState(() => isFirstLaunch = true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isFirstLaunch = false;
        nextPage = const NavigationPage(); //Guest Mode
      });
      return;
    }

    // 🔥 Fetch role from Firestore
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final role = doc.data()?["role"] ?? "user";

    setState(() {
      isFirstLaunch = false;
      nextPage = role == "admin"
          ? const AdminNavigationPage()
          : const NavigationPage();
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
    if (nextPage == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return nextPage!;

  }
}
