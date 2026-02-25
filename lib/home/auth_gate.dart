import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floodsense/navigation.dart';
import 'package:floodsense/auth/login_page.dart';
import 'package:floodsense/admin/admin_navigation.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return LoginPage();
        }

        final user = snapshot.data!;

        // 🔥 Fetch role
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {

            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role =
                roleSnapshot.data?.get("role") ?? "user";

            if (role == "admin") {
              return const AdminNavigationPage();
            } else {
              return const NavigationPage();
            }
          },
        );
      },
    );
  }
}