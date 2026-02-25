import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'community_report.dart';
import '../services/rainfall_service.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

// Local mapping of supported districts to coordinates
final Map<String, LatLng> supportedDistrictCoordinates = {
  'Kota_Bharu_Kelantan': LatLng(6.125, 102.238),
  'Kota_Tinggi_Johor': LatLng(1.737, 103.918),
  'Kuantan_Pahang': LatLng(3.807, 103.327),
  'Pekan_Nanas_Johor': LatLng(1.528, 103.531),
  'Penang_Island': LatLng(5.416, 100.332),
  'Rantau_Panjang_Kelantan': LatLng(6.190, 102.092),
  'Segamat_Johor': LatLng(2.496, 102.833),
  'Serian_Sarawak': LatLng(1.214, 110.332),
  'Shah_Alam_Selangor': LatLng(3.073, 101.518),
};

// Load the warning marker icon with border
Future<BitmapDescriptor> loadWarningMarker() async {
  const double size = 120;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final paintFill = Paint()..color = const Color(0xFFFBC02D);
  final paintStroke = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;

  final path = Path();
  path.moveTo(size / 2, 0);
  path.lineTo(size, size);
  path.lineTo(0, size);
  path.close();

  canvas.drawPath(path, paintFill);
  canvas.drawPath(path, paintStroke);

  final textPainter = TextPainter(
    text: const TextSpan(
      text: "!",
      style: TextStyle(
        fontSize: 60,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      size / 2 - textPainter.width / 2,
      size / 2 - textPainter.height / 2,
    ),
  );

  final image =
  await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}

// Fetch flood risk level
Future<String?> fetchFloodRisk(double lat, double lng) async {
  try {
    String? nearestDistrict;
    double nearestDistance = double.infinity;

    // Find nearest supported district
    supportedDistrictCoordinates.forEach((district, coords) {
      final distance = Geolocator.distanceBetween(
        lat,
        lng,
        coords.latitude,
        coords.longitude,
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestDistrict = district;
      }
    });

    // Skip if too far (e.g., >20 km)
    if (nearestDistance > 20000 || nearestDistrict == null) return null;

    // Fetch flood risk from the API
    final response = await http.post(
      Uri.parse('https://predict-flood-453491805144.asia-southeast1.run.app'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'district': nearestDistrict}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['riskLevel'] as String?;
    } else {
      return null;
    }
  } catch (e) {
    print("Flood risk fetch error at $lat, $lng: $e");
    return null;
  }
}

//Build clustered markers within 5km of user's location
Future<void> buildClusteredMarkers(
    List<QueryDocumentSnapshot> docs,
    Position userPosition, {
      required void Function(Set<Marker> newMarkers) onUpdateMarkers,
      required BuildContext context,
      required String selectedDistrict,
      double clusterRadiusMeters = 200,
      double maxDistanceMeters = 5000,
      void Function(List<QueryDocumentSnapshot> deletedCluster)? onClusterDeleted,
    }) async {
  Set<Marker> newMarkers = {};
  final RainfallAnomalyService rainfallService = RainfallAnomalyService();
  final BitmapDescriptor warningIcon = await loadWarningMarker();

  // ---------------- DISTANCE-BASED CLUSTERING ----------------
  List<List<QueryDocumentSnapshot>> clusters = [];

  for (var doc in docs) {
    final double lat = doc['latitude'];
    final double lng = doc['longitude'];

    bool addedToCluster = false;

    for (var cluster in clusters) {
      final double clusterLat = cluster.first['latitude'];
      final double clusterLng = cluster.first['longitude'];

      double distance = Geolocator.distanceBetween(
        lat,
        lng,
        clusterLat,
        clusterLng,
      );

      if (distance <= clusterRadiusMeters) {
        cluster.add(doc);
        addedToCluster = true;
        break;
      }
    }

    if (!addedToCluster) {
      clusters.add([doc]);
    }
  }

  // ---------------- PROCESS EACH CLUSTER ----------------
  for (var cluster in clusters) {
    // -------- Compute cluster center (average lat/lng) --------
    double avgLat = 0;
    double avgLng = 0;

    for (var doc in cluster) {
      avgLat += doc['latitude'];
      avgLng += doc['longitude'];
    }

    avgLat /= cluster.length;
    avgLng /= cluster.length;

    // -------- Distance filter (5km from user) --------
    double distanceToUser = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      avgLat,
      avgLng,
    );

    if (distanceToUser > maxDistanceMeters) continue;

    // -------- Sort by newest --------
    cluster.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    final Timestamp newestTimestamp = cluster.first['timestamp'];
    final DateTime newestDate = newestTimestamp.toDate();

    // -------- EXACT 72 HOUR CHECK --------
    final Duration age = DateTime.now().difference(newestDate);

    if (age >= const Duration(days: 3)) {
      WriteBatch batch = firestore.batch();
      for (var doc in cluster) {
        batch.delete(firestore.collection('floodreports').doc(doc.id));
      }

      try {
        await batch.commit();
        print("Deleted ${cluster.length} old reports at $avgLat, $avgLng");
      } catch (e) {
        print("Batch delete error: $e");
      }

      if (onClusterDeleted != null) {
        onClusterDeleted(cluster);
      }

      continue; // Skip marker creation
    }

    // -------- Marker Display Logic --------
    bool showMarker = false;

    // Condition 1: 3 or more reports
    if (cluster.length >= 3) {
      showMarker = true;
    } else {
      try {
        // Condition 2: Rainfall anomaly
        final anomaly = await rainfallService.fetchAndAnalyze(selectedDistrict);

        if (anomaly.riskLevel.contains('HIGH') ||
            anomaly.riskLevel.contains('EXTREME')) {
          showMarker = true;
        } else {
          // Condition 3: Flood risk
          final floodRisk = await fetchFloodRisk(avgLat, avgLng);

          if (floodRisk != null &&
              (floodRisk.toUpperCase() == 'HIGH' ||
                  floodRisk.toUpperCase() == 'MEDIUM')) {
            showMarker = true;
          }
        }
      } catch (e) {
        print("Rainfall/flood fetch error at $avgLat, $avgLng: $e");
      }
    }

    if (!showMarker) continue;

    // -------- Add Marker --------
    newMarkers.add(
      Marker(
        markerId: MarkerId("cluster_${avgLat}_${avgLng}_${cluster.length}"),
        position: LatLng(avgLat, avgLng),
        icon: warningIcon,
        infoWindow: InfoWindow(
          title: "Flood Reports",
          snippet: "${cluster.length} reports at this area",
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FloodDetailsPage(clusterDocs: cluster),
            ),
          );
        },
      ),
    );
  }

  // -------- Update Map --------
  onUpdateMarkers(newMarkers);
}
