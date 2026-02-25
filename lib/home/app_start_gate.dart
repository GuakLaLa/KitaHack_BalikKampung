import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floodsense/admin/admin_navigation.dart';
import 'package:floodsense/home/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:floodsense/home/getStarted_page.dart';
import 'package:floodsense/navigation.dart';

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

    setState(() => isFirstLaunch = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstLaunch == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // FIRST LAUNCH
    if (isFirstLaunch!) {
      return GetStartedPage(
        onFinished: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('seenGetStarted', true);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthGate()),
          );
        },
      );
    }

    // NOT FIRST LAUNCH
    return const AuthGate();
  }
}
