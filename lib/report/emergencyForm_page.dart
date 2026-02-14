import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyFormPage extends StatefulWidget {
  const EmergencyFormPage({super.key});

  @override
  State<EmergencyFormPage> createState() => _EmergencyFormPageState();
}

class _EmergencyFormPageState extends State<EmergencyFormPage> {

  String currentStatus = "Trapped";
  double waterLevel = 0;
  double peopleAffected = 0;

  bool elderly = false;
  bool disabled = false;
  bool children = false;

  final TextEditingController descriptionController =
      TextEditingController();

  File? selectedImage;
  bool isLoading = false;

  // ---------------- IMAGE PICKER ----------------

  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  // ---------------- SUBMIT ----------------

  Future<void> submitReport() async {
    setState(() => isLoading = true);

    try {
      // 1️⃣ Get Location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 2️⃣ Upload Image (if any)
      String? imageUrl;

      if (selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("reports")
            .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

        await ref.putFile(selectedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // 3️⃣ Save to Firestore
      await FirebaseFirestore.instance.collection("reports").add({
        "currentStatus": currentStatus,
        "waterLevel": waterLevel,
        "peopleAffected": peopleAffected.toInt(),
        "specialNeeds": {
          "elderly": elderly,
          "disabled": disabled,
          "children": children,
        },
        "description": descriptionController.text,
        "imageUrl": imageUrl,
        "location": GeoPoint(position.latitude, position.longitude),
        "createdAt": FieldValue.serverTimestamp(),
        "status": "active",
        "verified": false,
        "priorityScore": 0,
        "priorityLevel": "Low"
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report submitted successfully")),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      print(e);
    }

    setState(() => isLoading = false);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Form")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("Current status"),
            RadioListTile(
              value: "Trapped",
              groupValue: currentStatus,
              onChanged: (value) {
                setState(() => currentStatus = value.toString());
              },
              title: const Text("Trapped"),
            ),
            RadioListTile(
              value: "Safe but Stranded",
              groupValue: currentStatus,
              onChanged: (value) {
                setState(() => currentStatus = value.toString());
              },
              title: const Text("Safe but Stranded"),
            ),
            RadioListTile(
              value: "Safe",
              groupValue: currentStatus,
              onChanged: (value) {
                setState(() => currentStatus = value.toString());
              },
              title: const Text("Safe"),
            ),

            const SizedBox(height: 15),

            const Text("Water Level"),
            Slider(
              value: waterLevel,
              min: 0,
              max: 100,
              divisions: 10,
              label: waterLevel.round().toString(),
              onChanged: (value) {
                setState(() => waterLevel = value);
              },
            ),

            const SizedBox(height: 15),

            const Text("People affected"),
            Slider(
              value: peopleAffected,
              min: 0,
              max: 10,
              divisions: 10,
              label: peopleAffected.round().toString(),
              onChanged: (value) {
                setState(() => peopleAffected = value);
              },
            ),

            const SizedBox(height: 15),

            const Text("Special needs"),
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

            const SizedBox(height: 15),

            const Text("Situation Description"),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Describe your situation...",
              ),
            ),

            const SizedBox(height: 15),

            const Text("Upload photo"),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Upload Photo"),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8CCCD3),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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
          ],
        ),
      ),
    );
  }
}
