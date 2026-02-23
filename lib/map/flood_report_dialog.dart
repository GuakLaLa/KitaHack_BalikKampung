import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class FloodReportDialog {
  static void show(BuildContext context, Position currentPosition) {
    _showFloodDetailsDialog(context, currentPosition);
  }

  static Future<void> _showFloodDetailsDialog(
      BuildContext context, Position currentPosition) async {
    TextEditingController detailsController = TextEditingController();
    TextEditingController locationController = TextEditingController();

    String waterLevel = 'Ankle';
    String roadStatus = 'Passable';
    List<XFile> selectedImages = [];
    final ImagePicker picker = ImagePicker();

    // Reverse geocode to get the location name
    String locationName = "Fetching location...";
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        currentPosition.latitude,
        currentPosition.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        locationName = place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            place.country ??
            "Nearby area";
      }
    } catch (_) {
      locationName = "Nearby area";
    }

    locationController.text = locationName;

    Future<List<String>> encodeImagesToBase64(List<XFile> images) async {
      List<String> encodedImages = [];
      for (XFile img in images) {
        File file = File(img.path);
        List<int> bytes = await file.readAsBytes();
        encodedImages.add(base64Encode(bytes));
      }
      return encodedImages;
    }

    Future<void> saveFloodReport() async {
      List<String> imageBase64 = [];
      if (selectedImages.isNotEmpty) {
        imageBase64 = await encodeImagesToBase64(selectedImages);
      }

      await FirebaseFirestore.instance.collection('floodreports').add({
        'latitude': currentPosition.latitude,
        'longitude': currentPosition.longitude,
        'location_name': locationController.text,
        'timestamp': DateTime.now(),
        'water_level': waterLevel,
        'road_status': roadStatus,
        'notes': detailsController.text,
        'images': imageBase64,
      });
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFFF4F9FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            "Report Flood",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF1F2937),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location
                _buildTextField(
                  controller: locationController,
                  label: "Location",
                  icon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 16),

                // Water Level
                _buildDropdown(
                  value: waterLevel,
                  label: "Water Level",
                  icon: Icons.water_drop_outlined,
                  items: ['Ankle', 'Knee', 'Waist', 'Chest', 'Head/Above'],
                  onChanged: (val) => setStateDialog(() => waterLevel = val!),
                ),

                const SizedBox(height: 16),

                // Road Status
                _buildDropdown(
                  value: roadStatus,
                  label: "Road Status",
                  icon: Icons.traffic_outlined,
                  items: ['Passable', 'Blocked'],
                  onChanged: (val) => setStateDialog(() => roadStatus = val!),
                ),

                const SizedBox(height: 16),

                // Notes
                _buildTextField(
                  controller: detailsController,
                  label: "Additional Notes",
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),

                const SizedBox(height: 18),

                // Selected Images
                Wrap(
                  spacing: 8,
                  children: selectedImages.map((image) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(image.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                selectedImages.remove(image);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Add Image Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text("Add Image"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DA8DA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: selectedImages.length >= 3
                      ? null
                      : () async {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text("Camera"),
                            onTap: () async {
                              Navigator.pop(context);
                              final XFile? image = await picker.pickImage(
                                  source: ImageSource.camera);
                              if (image != null) {
                                File file = File(image.path);
                                int sizeInBytes = await file.length();
                                double sizeInMb = sizeInBytes / (1024 * 1024);
                                if (sizeInMb > 1) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Image too large! Max allowed size is 1 MB.")),
                                  );
                                } else {
                                  setStateDialog(() => selectedImages.add(image));
                                }
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library_outlined),
                            title: const Text("Gallery"),
                            onTap: () async {
                              Navigator.pop(context);
                              final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (image != null) {
                                File file = File(image.path);
                                int sizeInBytes = await file.length();
                                double sizeInMb = sizeInBytes / (1024 * 1024);
                                if (sizeInMb > 1) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Image too large! Max allowed size is 1 MB.")),
                                  );
                                } else {
                                  setStateDialog(() => selectedImages.add(image));
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 6),
                Text(
                  "${selectedImages.length}/3 images",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // ACTIONS
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                try {
                  await saveFloodReport();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Report submitted successfully"),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to save: $e")),
                  );
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4DA8DA)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4DA8DA)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
