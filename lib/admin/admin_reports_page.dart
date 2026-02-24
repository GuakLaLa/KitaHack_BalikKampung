import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  Color _priorityColor(String level) {
    switch (level) {
      case "High":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

    Future<void> _navigateToLocation(
      double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl,
          mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submitted Reports"),
        centerTitle: true,
        backgroundColor: Color(0xFFA6E3E9),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("emergencyreports")
            .where("rescueStatus", isEqualTo: "active")
            .orderBy("priorityScore", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No reports available"),
            );
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, index) {

              final doc = reports[index];
              final data = doc.data() as Map<String, dynamic>;

              final priority = data["priorityLevel"] ?? "Low";

              final timestamp = data["createdAt"];
              String time = "";
              if (timestamp != null) {
                time = DateFormat("dd MMM yyyy, hh:mm a")
                    .format(timestamp.toDate());
              }

              final GeoPoint? geoPoint = data["location"];
              final latitude = geoPoint?.latitude;
              final longitude = geoPoint?.longitude;


              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _priorityColor(priority),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          priority,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        data["address"] ?? "No Address",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 6),

                      Text("👥 People: ${data["peopleAffected"]}"),
                      Text("🌊 Water Level: ${data["waterLevel"]}"),
                      Text("🚨 Victim Status: ${data["victimStatus"]}"),

                      const SizedBox(height: 6),

                      Text(
                        time,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [

                          // 🔵 NAVIGATE BUTTON (LEFT)
                          if (latitude != null && longitude != null)
                            TextButton.icon(
                              onPressed: () {
                                _navigateToLocation(
                                    latitude, longitude);
                              },
                              icon: const Icon(Icons.navigation, color: Color.fromARGB(255, 68, 219, 233)),
                              label: const Text("Navigate", style: TextStyle(color: Color.fromARGB(255, 116, 114, 114)),),
                            ),

                            const SizedBox(width: 8),

                          // 🟣 VIEW DETAILS BUTTON
                          TextButton(
                            onPressed: () {
                              _showDetailsDialog(context, doc);
                            },
                            child: const Text("View Details", style: TextStyle(color: Color.fromARGB(255, 116, 114, 114))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, DocumentSnapshot doc) {

  final data = doc.data() as Map<String, dynamic>;

  showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // TITLE
              const Text(
                "Emergency Report Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _buildDetailItem("Address", data["address"]),
              _buildDetailItem("Unit / Precise Location", data["preciseLocation"]),
              _buildDetailItem("Water Level", data["waterLevel"]),
              _buildDetailItem("People Affected", data["peopleAffected"]),
              _buildDetailItem("Victim Status", data["victimStatus"]),
              _buildDetailItem("Priority Level", data["priorityLevel"]),

              const SizedBox(height: 16),

              const Text(
                "📝 Description",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  data["description"] ?? "",
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 24),

              // ACTION BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection("emergencyreports")
                          .doc(doc.id)
                          .update({
                        "rescueStatus": "resolved",
                        "resolvedAt": FieldValue.serverTimestamp(),
                      });

                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Mark as Resolved",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      
                    ),
                  ),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Close",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

}
 Widget _buildDetailItem(String title, dynamic value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value?.toString() ?? "N/A",
          style: const TextStyle(fontSize: 16),
        ),
      ],
    ),
  );

}
