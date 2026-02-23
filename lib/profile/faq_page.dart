import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FAQ")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ExpansionTile(
            title: Text("How does FloodSense work?"),
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                    "FloodSense uses rainfall and water level data to detect possible flood risks."),
              )
            ],
          ),
          ExpansionTile(
            title: Text("How do I receive alerts?"),
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                    "Enable flood and rainfall alerts in your profile settings."),
              )
            ],
          ),
        ],
      ),
    );
  }
}