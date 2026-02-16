import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'flood_report_dialog.dart';
import 'nearest_shelter.dart';
import 'community_report.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  StreamSubscription? _floodSubscription;
  final Location _locationService = Location();

  Position? _currentPosition;
  LocationData? _currentLocationData;
  bool _loading = true;
  String? _locationError;

  final Set<Marker> _markers = {};
  BitmapDescriptor? _markerAnkle;
  BitmapDescriptor? _markerKnee;
  BitmapDescriptor? _markerWaist;

  static const double _clusterRadiusMeters = 200;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadMarkerIcons();
    await _getLocation();
    _listenFloodReports();
  }

  @override
  void dispose() {
    _floodSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ---------------- Marker icons ----------------
  Future<void> _loadMarkerIcons() async {
    _markerAnkle = await _createCustomMarker(Colors.green);
    _markerKnee = await _createCustomMarker(Colors.orange);
    _markerWaist = await _createCustomMarker(Colors.red);

    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createCustomMarker(Color color) async {
    const double size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    final textPainter = TextPainter(
      text: const TextSpan(
          text: "!",
          style: TextStyle(fontSize: 70, color: Colors.white, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas,
        Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2));

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // ---------------- Location ----------------
  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services are disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            "Location permission permanently denied. Enable it in settings.");
      }

      _currentLocationData = await _locationService.getLocation();

      // Real-time location updates
      _locationService.onLocationChanged.listen((loc) {
        _currentLocationData = loc;
        if (_currentLocationData != null) {
          _currentPosition = Position(
            latitude: _currentLocationData!.latitude!,
            longitude: _currentLocationData!.longitude!,
            timestamp: DateTime.now(),
            accuracy: _currentLocationData!.accuracy ?? 0.0,
            altitude: _currentLocationData!.altitude ?? 0.0,
            heading: _currentLocationData!.heading ?? 0.0,
            speed: _currentLocationData!.speed ?? 0.0,
            speedAccuracy: _currentLocationData!.speedAccuracy ?? 0.0,
            altitudeAccuracy: _currentLocationData!.verticalAccuracy ?? 0.0,
            headingAccuracy: _currentLocationData!.headingAccuracy ?? 0.0,
          );
          setState(() {});

          // Update camera position when location is updated
          if (_mapController != null && _currentPosition != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              ),
            );
          }
        }
      });

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _locationError = e.toString();
      });
    }
  }

  // ---------------- Firestore clustering ----------------
  void _listenFloodReports() {
    _floodSubscription = firestore.collection('floodreports').snapshots().listen((snapshot) {
      _buildClusteredMarkers(snapshot.docs);
    });
  }

  void _buildClusteredMarkers(List<QueryDocumentSnapshot> docs) {
    List<QueryDocumentSnapshot> unprocessed = List.from(docs);
    Set<Marker> newMarkers = {};

    while (unprocessed.isNotEmpty) {
      final base = unprocessed.removeAt(0);
      final double baseLat = base['latitude'];
      final double baseLng = base['longitude'];
      List<QueryDocumentSnapshot> cluster = [base];

      unprocessed.removeWhere((doc) {
        double distance =
        Geolocator.distanceBetween(baseLat, baseLng, doc['latitude'], doc['longitude']);
        if (distance <= _clusterRadiusMeters) {
          cluster.add(doc);
          return true;
        }
        return false;
      });

      if (cluster.length >= 3) {
        BitmapDescriptor icon = _markerAnkle ?? BitmapDescriptor.defaultMarker;
        if (cluster.any((d) => d['water_level'] == 'Waist')) {
          icon = _markerWaist ?? icon;
        } else if (cluster.any((d) => d['water_level'] == 'Knee')) {
          icon = _markerKnee ?? icon;
        }

        newMarkers.add(Marker(
          markerId: MarkerId("cluster_${baseLat}_${baseLng}_${cluster.length}"),
          position: LatLng(baseLat, baseLng),
          icon: icon,
          infoWindow: InfoWindow(
              title: "Flood Reports", snippet: "${cluster.length} reports in this area"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => FloodDetailsPage(latitude: baseLat, longitude: baseLng)),
            );
          },
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_locationError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                Text(_locationError!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _loading = true);
                    _getLocation();
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Flood Map")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(0, 0), // Default initial position (e.g., somewhere in the ocean)
          zoom: 6,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) => _mapController = controller,
        onCameraMove: (position) {
          // You can use this to get the current camera position if needed
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Shelters button
          FloatingActionButton.extended(
            heroTag: "shelter",
            icon: const Icon(Icons.location_on),
            label: const Text("Shelters Around Me"),
            onPressed: () {
              if (_currentPosition != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShelterPage(
                      latitude: _currentPosition!.latitude,
                      longitude: _currentPosition!.longitude,
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          // Report Flood button
          FloatingActionButton.extended(
            heroTag: "report",
            backgroundColor: Colors.red,
            icon: const Icon(Icons.report),
            label: const Text("Report Flood"),
            onPressed: () {
              if (_currentPosition != null) {
                FloodReportDialog.show(context, _currentPosition!);
              }
            },
          ),
        ],
      ),
    );
  }
}
