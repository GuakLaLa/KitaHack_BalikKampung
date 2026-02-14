import 'package:flutter/material.dart';
import 'package:floodsense/report/emergencyForm_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportPage extends StatelessWidget{
  const ReportPage({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse("tel:$phoneNumber");

    await launchUrl(
      phoneUri,
      mode: LaunchMode.externalApplication,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
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
            number: "0123456789",
          ),

          const SizedBox(height: 20),

          _buildCallButton(
            context,
            title: "Emergency contact\n(+60118938866)",
            number: "+60118938866",
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
    );
  }

  Widget _buildCallButton(
      BuildContext context,
      {required String title, required String number}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9ED0D6),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
      ),
      onPressed: () {
        _makePhoneCall(number);
      },
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