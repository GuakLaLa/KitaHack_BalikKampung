import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floodsense/profile/emergency_contact_page.dart';
import 'package:floodsense/report/advanced_flood_hotline_page.dart';
import 'package:flutter/material.dart';
import 'package:floodsense/report/emergencyForm_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floodsense/auth/login_page.dart';

class ReportPage extends StatefulWidget{
  const ReportPage({super.key});

    @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;

    final Uri phoneUri = Uri.parse("tel:$phoneNumber");

    await launchUrl(
      phoneUri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<String?> _getUserEmergencyContact() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    return doc.data()?['emergencyContact'] as String?;
  }

  void _showMissingContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Emergency Contact Required"),
        content: const Text(
          "Please fill in your emergency contact first.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmergencyContactPage(),
                ),
              ).then((_) {
                setState(() {}); //Refresh UI after returning
              });
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return 
      Scaffold(
        body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Phone Call",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )
            ),

            const SizedBox(height: 20),

            _buildCallButton(
              context,
              title: "Emergency Services",
              number: "999",
            ),

            const SizedBox(height: 20),

            _buildCallButton(
              context,
              title: "Flood Response Team",
              number: "",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdvancedFloodHotlinePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            FutureBuilder<String?>(
              future: _getUserEmergencyContact(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final number = snapshot.data;

                return _buildCallButton(
                  context,
                  title: number != null
                      ? "Emergency Contact\n($number)"
                      : "Set Emergency Contact",

                  number: number ?? "",

                  onPressed: (){ 
                    if (number == null || number.isEmpty) {
                      _showMissingContactDialog(context);
                    } else {
                      _makePhoneCall(number);
                    } 
                  },
                );
              },
            ),

            const SizedBox(height: 30),

            const Text(
              "Emergency Help Needed Form",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9ED0D6),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencyFormPage(),
                  ),
                );
              },
              child: const Text(
                "Emergency Form",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(
      BuildContext context,
      {required String title, required String number, VoidCallback? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9ED0D6),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
      ),
      onPressed: onPressed ?? () => _makePhoneCall(number),

      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
      ),
    );
    
  }
}