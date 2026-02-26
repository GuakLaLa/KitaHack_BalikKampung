import 'package:floodsense/profile/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floodsense/auth/login_page.dart';
import 'package:floodsense/profile/change_password_page.dart';

import 'emergency_contact_page.dart';
import 'faq_page.dart';
import 'aboutUs_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool floodAlert = false;
  bool rainfallAlert = false;

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
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

                  //Profile Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.blueGrey,
                        backgroundImage: data['photoUrl'] != null &&
                                data['photoUrl'].toString().isNotEmpty
                            ? NetworkImage(data['photoUrl'])
                            : null,
                        child: data['photoUrl'] == null ||
                                data['photoUrl'].toString().isEmpty
                            ? const Icon(Icons.person,
                                size: 40, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text("Name: ${data['name'] ?? ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
                            Text("Gender: ${data['gender'] ?? ''}"),
                            Text("Email: ${user.email ?? ''}"),
                            Text("Phone Number: ${data['phoneNumber'] ?? ''}"),
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
                    title: const Text("Emergency Contact"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmergencyContactPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("Change Password"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
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
                      activeColor: const Color(0xFF8CCCD3), // thumb color ON
                      activeTrackColor: const Color(0xFF8CCCD3).withOpacity(0.5), // track color ON
                      inactiveThumbColor: Colors.grey, // thumb OFF
                      inactiveTrackColor: Colors.grey.withOpacity(0.3), // track OFF
                    onChanged: (value) async {
                      setState(() => floodAlert = value);
                      await _updateNotification(
                          user.uid, "floodAlert", value);
                    },
                  ),

                  SwitchListTile(
                    title: const Text("Rainfall anomaly alert"),
                    value: rainfallAlert,
                      activeColor: const Color(0xFF8CCCD3), // thumb color ON
                      activeTrackColor: const Color(0xFF8CCCD3).withOpacity(0.5), // track color ON
                      inactiveThumbColor: Colors.grey, // thumb OFF
                      inactiveTrackColor: Colors.grey.withOpacity(0.3), // track OFF
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FAQPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("About Us"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutUsPage(),
                        ),
                      );
                    },
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
                      child: const Text("Edit Profile", 
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
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
                      child: const Text("Logout", style: TextStyle(fontSize: 16, color: Colors.black),),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }
