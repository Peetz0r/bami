import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'discovery.dart';

void main() async {
  runApp(const BAMI());

  BAMI.prefs = await SharedPreferences.getInstance();
}

class BAMI extends StatelessWidget {
  const BAMI({super.key});

  static SharedPreferences? prefs;
  static String title = 'Bambu Advanced Monitoring Interface';


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAMI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003e00)),
        useMaterial3: true,
      ),
      home: const DiscoveryPage(),
    );
  }
}

