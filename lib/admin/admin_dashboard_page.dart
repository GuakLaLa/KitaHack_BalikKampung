import 'package:floodsense/admin/admin_reports_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("emergencyreports")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          int total = reports.length;
          int high = 0;
          int medium = 0;
          int low = 0;
          int active = 0;
          int resolved = 0;

          for (var doc in reports) {
            final data = doc.data() as Map<String, dynamic>;

            final priority = data["priorityLevel"] ?? "Low";
            final status = data["rescueStatus"] ?? "active";

            if (priority == "High") high++;
            if (priority == "Medium") medium++;
            if (priority == "Low") low++;

            if (status == "active") active++;
            if (status == "resolved") resolved++;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                _statCard(
                  title: "Total Reports",
                  value: total.toString(),
                  color: Colors.blue,
                  icon: Icons.list_alt,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        title: "High Risk",
                        value: high.toString(),
                        color: Colors.red,
                        icon: Icons.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        title: "Medium",
                        value: medium.toString(),
                        color: Colors.orange,
                        icon: Icons.report,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        title: "Low Risk",
                        value: low.toString(),
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        title: "Active",
                        value: active.toString(),
                        color: Colors.purple,
                        icon: Icons.flash_on,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _statCard(
                  title: "Resolved",
                  value: resolved.toString(),
                  color: Colors.grey,
                  icon: Icons.done_all,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminReportsPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8CCCD3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "View Emergency Reports",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          )
        ],
      ),
    );
  }
}
