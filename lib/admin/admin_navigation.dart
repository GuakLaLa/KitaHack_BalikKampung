import 'package:flutter/material.dart';
import 'admin_reports_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_profile_page.dart';

class AdminNavigationPage extends StatefulWidget {
  const AdminNavigationPage({super.key});

  @override
  State<AdminNavigationPage> createState() => _AdminNavigationPageState();
}

class _AdminNavigationPageState extends State<AdminNavigationPage> {

  int currentIndex = 0;

  static const Color unselectedColor = Color.fromARGB(255, 116, 114, 114);
  static const Color selectedColor = Color.fromARGB(255, 68, 219, 233);

  final pages = const [
    AdminDashboardPage(),
    AdminReportsPage(),
    AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        unselectedItemColor: unselectedColor,
        selectedItemColor: selectedColor,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
