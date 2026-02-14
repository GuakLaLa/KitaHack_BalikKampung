import 'package:floodsense/profile/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floodsense/auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool floodAlert = false;
  bool rainfallAlert = false;
  bool _dialogShown = false;

  // 🔐 Logout
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  // 🔔 Update notification switch
  Future<void> _updateNotification(
      String uid, String field, bool value) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({field: value});
  }

  // 🚨 Show login popup
  void _showLoginDialog(BuildContext context) {
    if (_dialogShown) return;
    _dialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Login Required"),
          content: const Text(
              "You need to login or create an account to access your profile."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _dialogShown = false;
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (route) => false,
                );
              },
              child: const Text("Login / Sign Up"),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        // ⏳ Waiting for Firebase
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!authSnapshot.hasData) {
          _showLoginDialog(context);

          return const Scaffold(
            body: Center(
              child: Text("Redirecting to login..."),
            ),
          );
        }

        final user = authSnapshot.data!;

        return Scaffold(
          body: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data =
                  snapshot.data?.data() as Map<String, dynamic>? ?? {};

              floodAlert = data['floodAlert'] ?? false;
              rainfallAlert = data['rainfallAlert'] ?? false;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // 👤 Profile Header
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.blueGrey,
                          child: Icon(Icons.person,
                              size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text("Name: ${data['name'] ?? ''}"),
                              Text("Gender: ${data['gender'] ?? ''}"),
                              Text("Email: ${user.email ?? ''}"),
                              Text("Phone Number: ${data['phone'] ?? ''}"),
                            ],
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),

                    // 🛡 Safety Preference
                    const SizedBox(height: 15),
                    const Text(
                      "Safety Preference",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 10),
                    ListTile(
                      title: const Text("Default location"),
                      onTap: () {},
                    ),
                    ListTile(
                      title: const Text("Emergency Contact"),
                      onTap: () {},
                    ),

                    const SizedBox(height: 20),

                    // 🔔 Notifications
                    const Text(
                      "Notifications",
                      style: TextStyle(color: Colors.grey),
                    ),

                    SwitchListTile(
                      title: const Text("Flood alert"),
                      value: floodAlert,
                      onChanged: (value) async {
                        setState(() => floodAlert = value);
                        await _updateNotification(
                            user.uid, "floodAlert", value);
                      },
                    ),

                    SwitchListTile(
                      title: const Text("Rainfall anomaly alert"),
                      value: rainfallAlert,
                      onChanged: (value) async {
                        setState(() => rainfallAlert = value);
                        await _updateNotification(
                            user.uid, "rainfallAlert", value);
                      },
                    ),

                    const SizedBox(height: 20),

                    // ℹ Info
                    const Text(
                      "Info",
                      style: TextStyle(color: Colors.grey),
                    ),

                    ListTile(
                      title: const Text("FAQ"),
                      onTap: () {},
                    ),
                    ListTile(
                      title: const Text("About Us"),
                      onTap: () {},
                    ),

                    const SizedBox(height: 40),

                    // ✏ Edit Profile
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8CCCD3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("Edit Profile"),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // 🚪 Logout
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _signOut(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 4,
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("Logout"),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
