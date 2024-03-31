import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:dart_casing/dart_casing.dart';

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
  Function? onReport;

  late final MqttServerClient _client;
  Map<String, dynamic>? report;

  Bambu(this.ip, this.usn, this.name, this.model) {
    _client = MqttServerClient(ip, clientId);
    _client.port = 8883;
    _client.secure = true;
    _client.onBadCertificate = (Object a) => true;
    _client.autoReconnect = true;
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

  void connect(BuildContext context) async {
    try {
      await _client.connect('bblp', pass);
      _client.subscribe('device/+/report', MqttQos.atMostOnce);
    } on ConnectionException catch (e) {
      _client.disconnect();
      print("Failed! ${_client.connectionStatus?.returnCode}");
      String error = Casing.titleCase(_client.connectionStatus!.returnCode.toString().split('.')[1]);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Connection failure'),
            content: Text("Error while connecting to $name: $error."),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('Cancel'),
                onPressed: Navigator.of(context).pop,
              ),
            ],
          );
        },
      );
      return;
    } on Exception catch (e) {
      _client.disconnect();
      print("Unknown exception (other than ConnectionException)!\n$e");
      return;
    }

    print("Connected and subscribed to $this");

    PrinterPage printerPage = PrinterPage(printer: this);

    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (MqttReceivedMessage message in messages) {
          Map<String, dynamic> tmpReport = jsonDecode(
            MqttPublishPayload.bytesToStringAsString(
              message.payload.payload.message
            )
          );
          if (tmpReport!['print'] != null) {
            report = tmpReport!['print'];
            onReport?.call();
          }
        }
      }
    );

    await _client.updates?.first;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => printerPage),
    );
  }

  double? get progress {
    if (report?['mc_percent'] != null) {
      return report!['mc_percent']/100;
    }
  }

  double get layer => report?['layer_num'] ?? 0;
  double get layers => report?['total_layer_num'] ?? 0;

  String get videoStreamUri {
    if (report?['ipcam']['rtsp_url'] == null) return '';

    Uri uri = Uri.parse(report?['ipcam']['rtsp_url']);
    return Uri.new(
      scheme: uri.scheme,
      userInfo: 'bblp:$pass',
      host: uri.host,
      port: uri.port,
      path: uri.path,
    ).toString();
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
