import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/hotline_service.dart';
import '../models/hotline_area.dart';

class AdvancedFloodHotlinePage extends StatefulWidget {
  const AdvancedFloodHotlinePage({super.key});

  @override
  State<AdvancedFloodHotlinePage> createState() => _AdvancedFloodHotlinePageState();
}

class _AdvancedFloodHotlinePageState extends State<AdvancedFloodHotlinePage> {
  List<HotlineArea> _allAreas = [];
  List<HotlineArea> _filteredAreas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHotlines();
  }

  Future<void> _loadHotlines() async {
    try {
      final areas = await HotlineService.fetchHotlines();

      // Sort: district first, then state
      areas.sort((a, b) {
        if (a.level == 'district' && b.level == 'state') return -1;
        if (a.level == 'state' && b.level == 'district') return 1;
        return a.state.compareTo(b.state);
      });

      setState(() {
        _allAreas = areas;
        _filteredAreas = areas;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      debugPrint("Error loading hotlines: $e");
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;

    final Uri phoneUri = Uri.parse("tel:$phoneNumber");
    await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  }

  void _showNumbers(BuildContext context, HotlineArea area) {
    if (area.phones.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_buildTitle(area)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: area.phones.map((phone) {
            return ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text(phone),
              onTap: () {
                Navigator.pop(context);
                _makePhoneCall(phone);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _buildTitle(HotlineArea area) {
    if (area.level == 'district' && area.district != null && area.district!.isNotEmpty) {
      return "${area.district}, ${area.state}";
    } else {
      return "${area.state} State Hotline";
    }
  }

  void _filterAreas(String query) {
    final filtered = _allAreas.where((area) {
      final title = _buildTitle(area).toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredAreas = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flood Response Hotline")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 Search bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Search by state or district",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _filterAreas,
                  ),
                ),
                // 📜 Hotline list
                Expanded(
                  child: _filteredAreas.isEmpty
                      ? const Center(
                          child: Text(
                            "No hotline data available",
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredAreas.length,
                          itemBuilder: (context, index) {
                            final area = _filteredAreas[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text(_buildTitle(area)),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _showNumbers(context, area),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}