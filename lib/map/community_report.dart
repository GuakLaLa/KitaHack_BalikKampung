import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FloodDetailsPage extends StatelessWidget {
  final List<QueryDocumentSnapshot> clusterDocs; // Pass cluster docs directly

  const FloodDetailsPage({Key? key, required this.clusterDocs}) : super(key: key);

  // ----------------- Water Level Color -----------------
  Color _getWaterColor(String waterLevel) {
    switch (waterLevel.toLowerCase()) {
      case 'ankle':
        return Colors.yellow;
      case 'knee':
      case 'waist':
        return Colors.orange;
      case 'chest':
      case 'head/above':
        return Colors.red;
      default:
        return Colors.grey.shade400;
    }
  }

  // ----------------- Road Status Color -----------------
  Color _getRoadColor(String roadStatus) {
    if (roadStatus.toLowerCase() == 'passable') return Colors.green;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (clusterDocs.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFA6E3E9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFE6F4F6),
          centerTitle: true,
          title: const Text(
            "Flood Reports",
            style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        ),
        body: const Center(
          child: Text(
            "No flood reports found at this location",
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    // Sort cluster docs by timestamp descending
    final docs = List<QueryDocumentSnapshot>.from(clusterDocs)
      ..sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    return Scaffold(
      backgroundColor: const Color(0xFFA6E3E9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE6F4F6),
        centerTitle: true,
        title: const Text(
          "Flood Reports",
          style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          var data = docs[index];
          List<dynamic> images = data['images'] ?? [];

          String timeString = "";
          if (data['timestamp'] != null) {
            Timestamp ts = data['timestamp'];
            timeString = DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
          }

          String locationName = data['location_name'] ?? 'Unknown Location';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Name
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Color(0xFF4D96FF)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        locationName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Water Level & Road Status Pills
                Row(
                  children: [
                    _buildStatusPill("💧 ${data['water_level']}", _getWaterColor(data['water_level'] ?? "")),
                    const SizedBox(width: 8),
                    _buildStatusPill("🚧 ${data['road_status']}", _getRoadColor(data['road_status'] ?? "")),
                  ],
                ),
                const SizedBox(height: 12),

                // Timestamp
                if (timeString.isNotEmpty)
                  Text(
                    timeString,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                const SizedBox(height: 8),

                // Notes
                if ((data['notes'] ?? "").isNotEmpty)
                  Text(
                    data['notes'],
                    style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                  ),
                const SizedBox(height: 12),

                // Images
                if (images.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: images.map<Widget>((imgBase64) {
                        Uint8List bytes = base64Decode(imgBase64);
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullscreenImagePage(base64Image: imgBase64),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                bytes,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: _getReadableColor(color),
        ),
      ),
    );
  }
}

Color _getReadableColor(Color color) {
  if (color == Colors.yellow) return Colors.orange.shade600;
  return color;
}

class FullscreenImagePage extends StatelessWidget {
  final String base64Image;

  const FullscreenImagePage({Key? key, required this.base64Image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Uint8List bytes = base64Decode(base64Image);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}