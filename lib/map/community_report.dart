import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

class FloodDetailsPage extends StatelessWidget {
  final double latitude;
  final double longitude;

  const FloodDetailsPage({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  // Color adjustments from code 1 theme
  Color _getWaterColor(String waterLevel) {
    switch (waterLevel.toLowerCase()) {
      case 'waist':
        return const Color(0xFFFF6B6B);
      case 'knee':
        return const Color(0xFFFFC857);
      case 'ankle':
        return const Color(0xFF4D96FF);
      default:
        return const Color(0xFFCBD5E1);
    }
  }

  Color _getRoadColor(String roadStatus) {
    if (roadStatus.toLowerCase() == 'passable') {
      return const Color(0xFF4D96FF);
    } else {
      return const Color(0xFFFF6B6B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA6E3E9), // Soft Teal
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE6F4F6),
        centerTitle: true,
        title: const Text(
          "Flood Reports",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('floodreports')
            .where('latitude', isEqualTo: latitude)
            .where('longitude', isEqualTo: longitude)
            .orderBy('timestamp', descending: true)  // Sorting reports by timestamp in descending order
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No reports found at this location",
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            );
          }

          var docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index];
              List<dynamic> images = data['images'] ?? [];
              String timeString = "";
              if (data['timestamp'] != null) {
                Timestamp ts = data['timestamp'];
                timeString = DateFormat('dd MMM yyyy, hh:mm a')
                    .format(ts.toDate());
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
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: Color(0xFF4D96FF)),
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

                    Row(
                      children: [
                        _buildStatusPill(
                          "💧 ${data['water_level']}",
                          _getWaterColor(data['water_level'] ?? ""),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusPill(
                          "🚧 ${data['road_status']}",
                          _getRoadColor(data['road_status'] ?? ""),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (timeString.isNotEmpty)
                      Text(
                        timeString,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 8),

                    if ((data['notes'] ?? "").isNotEmpty)
                      Text(
                        data['notes'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    const SizedBox(height: 12),

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
                                      builder: (_) =>
                                          FullscreenImagePage(base64Image: imgBase64),
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
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}

class FullscreenImagePage extends StatelessWidget {
  final String base64Image;

  const FullscreenImagePage({Key? key, required this.base64Image})
      : super(key: key);

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