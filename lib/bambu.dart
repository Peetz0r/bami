import 'dart:io';
import 'dart:convert';
import 'package:upnp2/upnp.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class Bambu {

  static final String clientId = "BAMI-${Platform.operatingSystem}";

  static List<Bambu> discoveredPrinters = [];

  static SharedPreferences? prefs;

  final String ip;
  final String usn;
  final String name;
  final String model;
  String? pass;
  bool autoConnect = false;

  static Discover(State<MyHomePage> state) async {
    prefs = await SharedPreferences.getInstance();

    DeviceDiscoverer discoverer = DeviceDiscoverer();
    discoverer.start(port: 2021);

    Stream<DiscoveredClient> discoverStream = discoverer.quickDiscoverClients(timeout: null);
    // I would love to add `query: "urn:bambulab-com:device:3dprinter:1"`
    // but it sends that over a hardcoded port 1900, while it needs to be 2021
    // because Bambu uses a nonstandard variation of uPnP/SSDP
    // so we'll just wait until the printer sends it's own broadcast packet
    // it's once every 5 seconds, not too bad

    discoverStream.listen((DiscoveredClient client) {
      if(client.headers?['USN'] == null) return;
      if (client.headers?['NT'] == "urn:bambulab-com:device:3dprinter:1") {

        Bambu printer = new Bambu(
          client.headers?['LOCATION'] ?? "",
          client.headers!['USN']!,
          client.headers?['DEVNAME.BAMBU.COM'] ?? "",
          client.headers?['DEVMODEL.BAMBU.COM'] ?? "",
        );

        if (prefs!.containsKey(printer.usn)) {
          Map<String, Object?> json = jsonDecode(prefs!.getString(printer.usn)!);
          printer.pass = json['pass'] as String?;
          printer.autoConnect = json['autoConnect'] as bool;
        }
        print("discovered $printer");

        state.setState(() {
          discoveredPrinters.add(printer);
        });

        if (printer.autoConnect) printer.connect();

      }
    });
  }

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
    prefs!.setString(usn, jsonEncode(this));
  }

  void connect() {
    print("Pretending to connect to $this");
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
