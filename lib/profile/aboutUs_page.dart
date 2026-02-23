import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Us")),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "FloodSense is a smart flood monitoring application designed to provide early flood warnings and rainfall anomaly alerts to ensure public safety.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}