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

  late final MqttServerClient _client;

  Bambu(this.ip, this.usn, this.name, this.model) {
    _client = MqttServerClient(ip, clientId);
    _client.port = 8883;
    _client.secure = true;
    _client.onBadCertificate = (Object a) => true;

  }

  Future<bool> testConnection(String tmpPass) async {
    print("Testing connection to $this");

    try {
      await _client.connect('bblp', tmpPass);
    } on Exception catch (e) {
      _client.disconnect();
      print("Failed! ${_client.connectionStatus?.returnCode}"); // "null", not a MqttClientConnectionStatus
      return false;
    }

    _client.disconnect();
    print("Success!");
    return true;
  }

  void save(String newPass, bool newAutoConnect) {
    pass = newPass;
    autoConnect = newAutoConnect;

    BAMI.prefs.write(key: usn, value: jsonEncode(this));
  }

  void connect(BuildContext context) {

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
