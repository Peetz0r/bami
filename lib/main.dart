import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'discovery.dart';
import 'printer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.operatingSystem == 'android') {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    BAMI.isTV = androidInfo.systemFeatures.contains('android.software.leanback');
  }

  runApp(const BAMI());
}

class BAMI extends StatelessWidget {
  const BAMI({super.key});

  static FlutterSecureStorage prefs = FlutterSecureStorage(
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static String title = 'Bambu Advanced Monitoring Interface';
  static bool isTV = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAMI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003e00),
          brightness: Brightness.light,
        ),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003e00),
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
      ),
      themeMode: BAMI.isTV ? ThemeMode.dark : ThemeMode.system,
      home: const DiscoveryPage(),
    );
  }
}

