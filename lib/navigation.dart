import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floodsense/home/home_page.dart';
import 'package:floodsense/map/map_page.dart';
import 'package:floodsense/profile/profile_page.dart';
import 'package:floodsense/report/report_page.dart';
import 'package:flutter/material.dart';
import 'package:floodsense/auth/app_user.dart';
import 'package:floodsense/services/flood_service.dart';
import 'package:floodsense/auth/login_page.dart';

class NavigationPage extends StatefulWidget{
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<NavigationPage> {
  //this keep track of the selected index
  int _selectedIndex = 0;

  // Lifted district state — shared between HomePage and MapPage
  String _selectedDistrict = FloodService.supportedDistricts.first;

  final User? user = FirebaseAuth.instance.currentUser;

  static const Color unselectedColor = Color.fromARGB(255, 116, 114, 114);
  static const Color selectedColor = Color.fromARGB(255, 68, 219, 233);

  //this method updates the new selected index
  void _navigateBottomBar(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  // Use a getter so pages rebuild with updated _selectedDistrict
  List<Widget> get _pages => [
        HomePage(
          selectedDistrict: _selectedDistrict,
          onDistrictChanged: (district) {
            setState(() => _selectedDistrict = district);
          },
        ),
        MapPage(selectedDistrict: _selectedDistrict),
        ReportPage(),
        ProfilePage(),
      ];

  final List<String> _titles = [
    "Home",
    "Map",
    "Report",
    "Profile",
  ];


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Color(0xFFA6E3E9),
        centerTitle: true,
        elevation: 0,
      ),

      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: unselectedColor,
        selectedItemColor: selectedColor,
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar, 
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ]
      ),  
    );
  }

  // ================= DRAWER =================

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser; //NOT stored in state

    return Drawer(
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data =
                snapshot.data!.data() as Map<String, dynamic>;
            final appUser = AppUser.fromJson(data);

            return ListView(
              padding: EdgeInsets.zero,
              children: [

                UserAccountsDrawerHeader(
                  margin: EdgeInsets.zero,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA6E3E9),
                  ),

                  accountName: Text(
                    appUser.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  accountEmail: Text(
                    appUser.email,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),

                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: appUser.photoUrl != null
                        ? NetworkImage(appUser.photoUrl!)
                        : null,
                    child: appUser.photoUrl == null
                        ? const Icon(Icons.person, size: 35)
                        : null,
                  ),
                ),

                _buildDrawerItem(Icons.home, "Home", 0),
                _buildDrawerItem(Icons.map, "Map", 1),
                _buildDrawerItem(Icons.list_alt, "Report", 2),
                _buildDrawerItem(Icons.person, "Profile", 3),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () async {
                    Navigator.pop(context); // close drawer

                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                const Icon(
                                  Icons.logout,
                                  size: 60,
                                  color: Color(0xFF44DBE9),
                                ),

                                const SizedBox(height: 16),

                                const Text(
                                  "Logout",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  "Are you sure you want to logout?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15),
                                ),

                                const SizedBox(height: 24),

                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                        child: const Text("Cancel"),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF44DBE9),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                        child: const Text("Logout"),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    if (shouldLogout == true) {
                      await FirebaseAuth.instance.signOut();

                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ================= DRAWER ITEMS =================

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final bool isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? selectedColor : unselectedColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? selectedColor : unselectedColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}