import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'main.dart';
import 'printer.dart';

class Bambu {

  static final String clientId = "BAMI-${Platform.operatingSystem}";

  final String ip;
  final String usn;
  final String name;
  final String model;
  String? pass;
  bool autoConnect = false;



  Bambu(this.ip, this.usn, this.name, this.model) {

  }

  Future<bool> testConnection(String tmpPass) async {
    final MqttServerClient client = MqttServerClient(ip, clientId);
    client.port = 8883;
    client.secure = true;
    client.onBadCertificate = (Object a) => true;

    print("Testing: $ip - $clientId - bblp - $tmpPass");
    print("Testing: $this");

    try {
      await client.connect('bblp', tmpPass);
    } on Exception catch (e) {
      client.disconnect();
      print("Failed! $e");
      return false;
    }
    print("Success!");
    return true;
    client.disconnect();
  }

  void save(String newPass, bool newAutoConnect) {
    pass = newPass;
    autoConnect = newAutoConnect;

    print("Save printer [$usn]: ${jsonEncode(this)}");
    BAMI.prefs!.setString(usn, jsonEncode(this));
  }

  void connect(BuildContext context) {
    print("CTX: $context ?? 'N/A'");
    print("Pretending to connect to $this");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrinterPage(printer: this)),
    );
  }

  String toString() {
    return "Bambu([$usn] | $model | $ip | $name | Pass: ${pass == null ? 'N/A' : '*'*pass!.length})";
  }

  Map<String, Object?> toJson() {
    return {
      'pass': pass,
      'autoConnect': autoConnect,
    };
  }

}
