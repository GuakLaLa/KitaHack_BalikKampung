import 'package:floodsense/home/app_start_gate.dart';
import 'package:floodsense/navigation.dart';
import 'package:floodsense/home/getStarted_page.dart';
import 'package:floodsense/home/home_page.dart';
import 'package:floodsense/map/map_page.dart';
import 'package:floodsense/profile/profile_page.dart';
import 'package:floodsense/report/report_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:floodsense/firebase_options.dart';

Future<void> main() async {
  //firebase setup
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //just to hide the develop icon
      home: const AppStartGate(),
    ); 
  }
} 