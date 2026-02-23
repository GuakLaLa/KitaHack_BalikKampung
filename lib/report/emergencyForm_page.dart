import 'dart:io';
import 'package:floodsense/report/report_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:floodsense/report/full_screen_map_page.dart';
import 'package:floodsense/services/ai_priority_service.dart';

class EmergencyFormPage extends StatefulWidget {
  const EmergencyFormPage({super.key});

  @override
  State<EmergencyFormPage> createState() => _EmergencyFormPageState();
}

class _EmergencyFormPageState extends State<EmergencyFormPage> {

  String victimStatus = "Trapped";
  String waterLevel = "";

  int? waterLevelIndex;
  double? peopleAffected;

  bool elderly = false;
  bool disabled = false;
  bool children = false;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController preciseLocationController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  File? selectedImage;
  bool isLoading = false;

  LatLng? selectedLatLng;
  GoogleMapController? mapController;

  // -----------For water level----------------
  final List<String> waterLevels = [
    "Foot",
    "Knee",
    "Waist",
    "Chest",
    "Head / Above Head"
  ];

  // ---------------- LOCATION ----------------

Future<void> _getCurrentLocation() async {

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if(!serviceEnabled) return;

  LocationPermission permission = await Geolocator.checkPermission();
  if(permission == LocationPermission.denied){
    permission = await Geolocator.requestPermission();
    if(permission == LocationPermission.denied) return;
  }

  if (permission == LocationPermission.deniedForever) {
    return;
  }

  Position position = await Geolocator.getCurrentPosition();

  final latLng = LatLng(position.latitude, position.longitude);

  setState(() => selectedLatLng = latLng);

  mapController?.animateCamera(
    CameraUpdate.newLatLng(latLng),
  );

  _fillAddressFromLatLng(latLng);
}

Future<void> _fillAddressFromLatLng(LatLng latLng) async {
  try {
    final placemarks = await placemarkFromCoordinates(
      latLng.latitude,
      latLng.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;

      final street = place.thoroughfare ?? "";
      final residential = place.subLocality ?? "";
      final postcode = place.postalCode?? "";
      final state = place.administrativeArea ?? ""; 

      addressController.text = [
        street,
        residential,
        postcode,
        state,
      ].where((e) => e.isNotEmpty).join(", ");
    }
  } catch (e) {
    debugPrint("Geocoding error: $e");
  }
}

  // ---------------- IMAGE ----------------

  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  // ---------------- VALIDATION ----------------

    bool _validateForm() {
      List<String> missing = [];

      if (selectedLatLng == null) missing.add("Location");
      if (victimStatus.isEmpty) missing.add("Current Status");
      if (waterLevel.isEmpty) missing.add("Water Level");
      if (peopleAffected == null) missing.add("People Affected");
      if (descriptionController.text.trim().isEmpty) {
        missing.add("Situation Description");
      }

      if (missing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill: ${missing.join(", ")}")),
        );
        return false;
      }

      return true;
    }

  // ---------------- SUBMIT ----------------

  Future<void> submitReport() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
      }
      return;
    }   

    final userDoc = await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .get();

    if (!userDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User profile missing")),
        );
      }
      return;
    }

    final Map<String, dynamic>? userData = userDoc.data();

    if (!_validateForm()) return;

    setState(() => isLoading = true);

    try {
      String? imageUrl;

      if (selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("reports")
            .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

        await ref.putFile(selectedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      final priority = await AIPriorityService.evaluatePriority(
        victimStatus: victimStatus,
        waterLevel: waterLevel,
        peopleAffected: peopleAffected!.toInt(),
        elderly: elderly,
        disabled: disabled,
        children: children,
        description: descriptionController.text,
      );

      await FirebaseFirestore.instance.collection("emergencyreports").add({
        "uid": user.uid,
        "email": user.email,
        "reporterName": userData?['name'],
        "reporterNumber": userData?['phoneNumber'],
        
        "victimStatus": victimStatus,
        "waterLevel": waterLevel,
        "peopleAffected": peopleAffected!.toInt(),
        "specialNeeds": {
          "elderly": elderly,
          "disabled": disabled,
          "children": children,
        },
        "description": descriptionController.text,
        "preciseLocation": preciseLocationController.text,
        "unit": preciseLocationController.text,
        "address": addressController.text,
        "imageUrl": imageUrl,
        "location": GeoPoint(
            selectedLatLng!.latitude,
            selectedLatLng!.longitude),
        "createdAt": FieldValue.serverTimestamp(),
        "rescueStatus": "active",
        "priorityScore": priority["priorityScore"],
        "priorityLevel": priority["priorityLevel"],
        "aiReason": priority["reason"],
      });

      if (mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Report Submitted"),
          content: const Text(
            "Your emergency report was submitted successfully.\n\n"
            "Our response team will take quick action.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );

      //Navigate AFTER dialog closes
      Navigator.pop(context);
    }

    } catch (e) {
      debugPrint("Submit error: $e");
    }

    setState(() => isLoading = false);
  }

   // ---------------- INFO TITLE ----------------

  Widget _sectionTitle(String title, String info) {
    return Row(
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(title),
                content: Text(info),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  )
                ],
              ),
            );
          },
          child: const Icon(Icons.help_outline, size: 18),
        )
      ],
    );
  }
  


  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Form"),
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16,16,16,100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 📍 MAP SECTION
            _sectionTitle(
              "Your current location", 
              "Tap the map to select your exact emergency location.",
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenMapPage(initialLocation: selectedLatLng),
                  ),
                );

                if (result != null && result is LatLng) {
                  setState(() => selectedLatLng = result);
                  _fillAddressFromLatLng(result);
                }
              },
              child: SizedBox(
                height: 200,
                child: AbsorbPointer( // prevents interaction
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(3.1390, 101.6869),
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      mapController = controller;
                      _getCurrentLocation();
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
                ),
              ),
            ),


            const SizedBox(height: 10),

            TextField(
              controller: preciseLocationController,
              decoration: const InputDecoration(
                labelText: "Unit / Floor / Block (Precise Location)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "Address",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            // 🚨 STATUS
            _sectionTitle(
              "Current status", 
              "Tell us your safety condition.",
              ),

            RadioListTile(
              value: "Trapped",
              groupValue: victimStatus,
              onChanged: (val) =>
                  setState(() => victimStatus = val.toString()),
              title: const Text("Trapped"),
            ),
            RadioListTile(
              value: "Safe but Stranded",
              groupValue: victimStatus,
              onChanged: (val) =>
                  setState(() =>victimStatus = val.toString()),
              title: const Text("Safe but Stranded"),
            ),
            RadioListTile(
              value: "Safe",
              groupValue: victimStatus,
              onChanged: (val) =>
                  setState(() => victimStatus = val.toString()),
              title: const Text("Safe"),
            ),

            const SizedBox(height: 20),

            // 🌊 WATER LEVEL
            _sectionTitle(
              "Water Level",
              "Indicate flood severity.",
            ),

            const SizedBox(height: 10),

            Slider(
              value: waterLevelIndex?.toDouble() ?? 0,
              activeColor: waterLevelIndex == null ? Colors.grey : null,
              min: 0,
              max: 4,
              divisions: 4,
              label: waterLevelIndex == null 
                ? null
                : waterLevels[waterLevelIndex!],
              onChanged: (value) {
                setState(() {
                  waterLevelIndex = value.toInt();
                  waterLevel = waterLevels[waterLevelIndex!];
                });
              },
            ),

            const SizedBox(height: 20),

            // 👥 PEOPLE
            _sectionTitle(
              "People Affected",
              "Number of people needing help.",
            ),

            Slider(
              value: peopleAffected ?? 1,
              activeColor: peopleAffected == null ? Colors.grey : null,
              min: 1,
              max: 20,
              divisions: 19,
              label: peopleAffected?.round().toString(),
              onChanged: (val) =>
                  setState(() => peopleAffected = val),
            ),

            const SizedBox(height: 20),

            // SPECIAL NEEDS
            _sectionTitle(
              "Special Needs",
              "Choose is there any special needs.",
            ),
            
            CheckboxListTile(
              value: children,
              onChanged: (val) => setState(() => children = val!),
              title: const Text("Children"),
            ),
            CheckboxListTile(
              value: elderly,
              onChanged: (val) => setState(() => elderly = val!),
              title: const Text("Elderly"),
            ),
            CheckboxListTile(
              value: disabled,
              onChanged: (val) => setState(() => disabled = val!),
              title: const Text("Disabled"),
            ),

            const SizedBox(height: 20),

            _sectionTitle(
              "Situation Description",
              "Describe your emergency.",
            ),

            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle(
              "Upload photo",
              "Upload your surroundings photo for better analysis",
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Upload Photo"),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
            
            
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8CCCD3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Submit",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}
