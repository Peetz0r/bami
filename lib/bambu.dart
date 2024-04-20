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
  int _sequence_id = 42;

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
      _client.subscribe('device/$usn/report', MqttQos.atMostOnce);
    } on Exception catch (e) {
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
                child: const Text('OK'),
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
            if (tmpReport!['print']['command'] == 'push_status') {
              report = tmpReport!['print'];
              onReport?.call();
            }
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

  void disconnect() {
    onReport = null;
    _client.disconnect();
  }

  void _sendCommand(String command, String param) {
    _client.publishMessage(
      "device/$usn/request",
      MqttQos.exactlyOnce,
      MqttClientPayloadBuilder().addString(
        jsonEncode({
          'print': {
            'command': command,
            'param': param,
            'sequence_id': _sequence_id,
          }
        })
      ).payload!
    );

    _sequence_id++;
  }

  double   get progress       => (report?['mc_percent'] ?? 0)/100;
  int      get layer          => report?['layer_num'] ?? 0;
  int      get layers         => report?['total_layer_num'] ?? 0;
  String   get printName      => report?['subtask_name'] ?? '';
  bool     get isRunning      => report?['gcode_state'] == 'RUNNING';
  bool     get isPaused       => report?['gcode_state'] == 'PAUSE';
  Duration get remainingTime  => Duration(minutes: report?['mc_remaining_time'] ?? 0);

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

  String get remainingTimeString {
    String out = "";
    if (remainingTime.inHours >= 24) {
      out += "${(remainingTime.inHours/24).floor()}d ";
    }

    out += (remainingTime.inHours % 60).toString().padLeft(2, "0");
    out += ":";
    out += (remainingTime.inMinutes % 60).toString().padLeft(2, "0");
    return out;
  }

  void pause() {
    _sendCommand('pause', '');
  }

  void resume() {
    _sendCommand('resume', '');
  }

  void stop() {
    _sendCommand('stop', '');
  }

  String toString() {
    return "Bambu([$usn] | $model | $ip | $name | Pass: ${pass == null ? 'N/A' : '*'*pass!.length})";
  }

  List<List<Filament>> get amsFilaments {
    List<List<Filament>> allAmsfilaments = [];

    for (final ams in report?['ams']['ams']) {
      List<Filament> thisAmsFilaments = [];
      for (final item in ams['tray']) {
        int c = int.tryParse(item['tray_color'], radix: 16) ?? 0;
        // Bambu provides RGBA, flutter needs ARGB
        c = (c >> 8) | ((c & 0xff) << 24);
        Filament filament = Filament(
          Color(c),
          item['tray_sub_brands'],
          item['remain']/100,
        );
        thisAmsFilaments.add(filament);
      }
    allAmsfilaments.add(thisAmsFilaments);
    }

    return allAmsfilaments;
  }

  Map<String, Object?> toJson() {
    return {
      'pass': pass,
      'autoConnect': autoConnect,
    };
  }

}

class Filament {
  Color color;
  String name;
  double remain;

  Filament(this.color, this.name, this.remain);

  String toString() {
    return "Filament($name (${(remain*100).floor()}%) RGB(${color.red}, ${color.green}, ${color.blue})";
  }
}
