import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'flood_report_dialog.dart';
import 'nearest_shelter.dart';
import 'marker.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

class MapPage extends StatefulWidget {
  final String selectedDistrict;

  const MapPage({super.key, required this.selectedDistrict});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  StreamSubscription? _floodSubscription;

  Position? _currentPosition;
  bool _loading = true;
  String? _locationError;

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getLocation();
    _listenFloodReports();
  }

  @override
  void dispose() {
    _floodSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
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

      _currentPosition = await Geolocator.getCurrentPosition();

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        _currentPosition = position;
        if (mounted) {
          setState(() {});
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
            );
          }
        }
      });

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _locationError = e.toString();
      });
    }
  }

  // ---------------- Clustering ----------------
  void _listenFloodReports() {
    _floodSubscription =
        firestore.collection('floodreports').snapshots().listen((
            snapshot) async {
          if (_currentPosition == null) return;

          await buildClusteredMarkers(
            snapshot.docs,
            _currentPosition!,
            context: context,
            selectedDistrict: widget.selectedDistrict,
            onUpdateMarkers: (newMarkers) {
              if (!mounted) return;
              setState(() {
                _markers
                  ..clear()
                  ..addAll(newMarkers);
              });
            },
            onClusterDeleted: (deletedCluster) {
              if (!mounted) return;
              setState(() {
                _markers.removeWhere((m) =>
                    deletedCluster.any((doc) =>
                        m.markerId.value.contains(
                            "${doc['latitude']}_${doc['longitude']}")));
              });
            },
          );
        });
  }


  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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

    final initialLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(0, 0);

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialLatLng,
          zoom: 12,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) => _mapController = controller,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0), // space from bottom
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton.extended(
              heroTag: "shelter",
              icon: const Icon(Icons.location_on),
              label: const Text("Shelters Around Me"),
              onPressed: () {
                if (_currentPosition != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ShelterPage(
                            latitude: _currentPosition!.latitude,
                            longitude: _currentPosition!.longitude,
                          ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              heroTag: "report",
              backgroundColor: Colors.pink[200],
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

}