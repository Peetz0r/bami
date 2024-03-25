import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'discovery.dart';
import 'printer.dart';

void main() async {
  runApp(const BAMI());
}

class BAMI extends StatelessWidget {
  const BAMI({super.key});

  static FlutterSecureStorage prefs= FlutterSecureStorage(
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

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

