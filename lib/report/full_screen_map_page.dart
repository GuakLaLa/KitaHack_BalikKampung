import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FullScreenMapPage extends StatefulWidget {
  final LatLng? initialLocation;

  const FullScreenMapPage({super.key, this.initialLocation});

  @override
  State<FullScreenMapPage> createState() => _BigMapPageState();
}

class _BigMapPageState extends State<FullScreenMapPage> {
  LatLng? selectedLatLng;

  @override
  void initState() {
    super.initState();
    selectedLatLng = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation ?? const LatLng(3.1390, 101.6869),
          zoom: 16,
        ),
        onTap: (position) {
          setState(() => selectedLatLng = position);
        },
        markers: selectedLatLng == null
            ? {}
            : {
                Marker(
                  markerId: const MarkerId("selected"),
                  position: selectedLatLng!,
                )
              },
      ),


      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 45,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedLatLng == null
                  ? null
                  : () => Navigator.pop(context, selectedLatLng),
              child: const Text(
                "Confirm Location",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
