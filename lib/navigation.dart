import 'package:floodsense/home/home_page.dart';
import 'package:floodsense/map/map_page.dart';
import 'package:floodsense/profile/profile_page.dart';
import 'package:floodsense/report/report_page.dart';
import 'package:flutter/material.dart';

class NavigationPage extends StatefulWidget{
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<NavigationPage> {
  //this keep track of the selected index
  int _selectedIndex = 0;

  //this method updates the new selected index
  void _navigateBottomBar(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  //the pages we have in the app
  final List _pages = [
    //home page
    HomePage(),

    //map page
    MapPage(),

    //report page
    ReportPage(),

    //profile page
    ProfilePage()

  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      
      appBar: AppBar(
          title: Text("My App Bar"),
          backgroundColor: Color(0xFFA6E3E9),
          elevation: 0,
          leading: Icon(Icons.menu),
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.people),
),
          ],
        ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Color.fromARGB(255, 165, 165, 165),
        selectedItemColor: Color(0xFFA6E3E9),
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar, 
        items: [
        //home
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

      ]),  
    );
  }
}