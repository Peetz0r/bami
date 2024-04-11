import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:upnp2/upnp.dart' hide Icon;
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';
import 'bambu.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() {

    State<DiscoveryPage> state = _DiscoveryPageState();
    Discover(state);
    return state;
  }

  static List<Bambu> discoveredPrinters = [];

  static Discover(State<DiscoveryPage> state) async {
    DeviceDiscoverer discoverer = DeviceDiscoverer();
    discoverer.start(port: 2021);

    Stream<DiscoveredClient> discoverStream = discoverer.quickDiscoverClients(timeout: null, searchInterval: null);
    // I would love to add `query: "urn:bambulab-com:device:3dprinter:1"`
    // but it sends that over a hardcoded port 1900, while it needs to be 2021
    // because Bambu uses a nonstandard variation of uPnP/SSDP
    // so we'll just wait until the printer sends it's own broadcast packet
    // it's once every 5 seconds, not too bad

    discoverStream.listen((DiscoveredClient client) async {
      if (client.headers?['USN'] == null) return;
      if (client.headers?['NT'] == "urn:bambulab-com:device:3dprinter:1") {

        Bambu printer = Bambu(
          client.headers?['LOCATION'] ?? "",
          client.headers!['USN']!,
          client.headers?['DEVNAME.BAMBU.COM'] ?? "",
          client.headers?['DEVMODEL.BAMBU.COM'] ?? "",
        );

        if (await BAMI.prefs.containsKey(key: printer.usn)) {
          Map<String, Object?> json = jsonDecode((await BAMI.prefs.read(key: printer.usn))!);
          printer.pass = json['pass'] as String?;
          printer.autoConnect = json['autoConnect'] as bool;
        }
        print("discovered $printer");

        state.setState(() {
          discoveredPrinters.add(printer);
        });

        if (printer.autoConnect) printer.connect(state.context);

      }
    });
  }
}

class _DiscoveryPageState extends State<DiscoveryPage> {

  int _testState = 0;
  bool _tmpAutoConnect = false;
  String _tmpPass = '';

  List<Widget> _discoveredPrinters(BuildContext context) {
    var widget = <Widget>[];

    for (Bambu printer in DiscoveryPage.discoveredPrinters) {
      widget.add(
        Focus(
          canRequestFocus: false,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              if (node.descendants.last.hasPrimaryFocus) { // if the Card has focus
                if (event.logicalKey == LogicalKeyboardKey.arrowRight) { // and we press arrow Right
                  node.nextFocus(); // move focus to the settings IconButton
                  return KeyEventResult.handled;
                }
              }

              if (node.descendants.first.hasPrimaryFocus) { // if the settings IconButton has focus
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) { // and we press arrow Left
                  node.previousFocus(); // move focus to the Card
                  return KeyEventResult.handled;
                }
              }
            }

            return KeyEventResult.ignored;
          },
          child: Builder(
            builder: (BuildContext context) {
              return Card(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  splashColor: Colors.blue.withAlpha(30),
                  onTap: () {
                    if (printer.pass == null) {
                      showDialog(
                        context: context,
                        builder: (context) {

                          _testState = 0;
                          _tmpAutoConnect = printer.autoConnect;
                          _tmpPass = printer.pass is String ? printer.pass! : '';
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return _settingsDialog(printer, setState, true);
                            },
                          );
                        },
                      );
                    } else {
                      printer.connect(context);
                    }

                  },
                  child: ListTile(
                    leading: FlutterLogo(size: 72.0),
                    title: Text(printer.name),
                    subtitle: Text('Model: ${printer.model}\nIP: ${printer.ip}'),
                    trailing: IconButton.filledTonal(
                      icon: const Icon(Icons.settings),
                      focusColor: Theme.of(context).colorScheme.inversePrimary,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {

                            _testState = 0;
                            _tmpAutoConnect = printer.autoConnect;
                            _tmpPass = printer.pass is String ? printer.pass! : '';
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return _settingsDialog(printer, setState);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    if (widget.length == 0) {
      widget.add(
        Card(
          child: ListTile(
            leading: CircularProgressIndicator(),
            title: const Text('Discovering printers...'),
            subtitle: const Text('This should only take a few seconds'),
          ),
        ),
      );
    }

    return widget;
  }

  Widget? _testDisplay() {
    if (_testState == 1) return Center(
      widthFactor: 1.0,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator()
      )
    );
    if (_testState == 2) return Icon(Icons.check,  size: 20, color: Colors.green);
    if (_testState == 3) return Icon(Icons.report, size: 20, color: Colors.red);
  }

  Dialog _settingsDialog(Bambu printer, setState, [bool connect = false]) {

    return Dialog(
      clipBehavior: Clip.hardEdge,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            print('got: ${event.logicalKey}');
            if ([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.arrowDown].contains(event.logicalKey)) {
              print('nextFocus');
              node.nextFocus();
              return KeyEventResult.handled;
            }

            if ([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowUp].contains(event.logicalKey)) {
              print('previousFocus');
              node.previousFocus();
              return KeyEventResult.handled;
            }
          }

          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              constraints: BoxConstraints.tightFor(width: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Settings',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                child: ListTile(
                                  leading: FlutterLogo(size: 72.0),
                                  title: Text(printer.name),
                                  subtitle: Text('Model: ${printer.model}\nIP: ${printer.ip}'),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Access Code',
                                  suffix: _testDisplay(),
                                ),
                                initialValue: _tmpPass,
                                obscureText: true,
                                enableSuggestions: false,
                                autocorrect: false,
                                keyboardType: TextInputType.visiblePassword,
                                onChanged: (String text) {
                                  _tmpPass = text;
                                  if (_tmpPass.length == 8) {
                                    setState(() { _testState = 1; });
                                    printer.testConnection(_tmpPass).then((e) {
                                      setState(() { _testState = e ? 2 : 3; });
                                    });
                                  } else {
                                    setState(() { _testState = 0; });
                                  }
                                },
                              ),
                            ),
                            SwitchListTile(
                              title: const Text("Auto-connect"),
                              subtitle: const Text("Automatically connect to this printer once detected, skipping the device list"),
                              value: _tmpAutoConnect,
                              onChanged: (bool value) {
                                print("autoConnect: $value");
                                setState(() { _tmpAutoConnect = value; });
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Text("You can only connect locally to a Bambu Labs 3D printer in LAN Only mode. To do this you'll need to enable LAN Only mode on the screen on your printer, and enter the Access Code from the printers display here."),
                                      Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            launchUrl(Uri.parse('https://wiki.bambulab.com/en/knowledge-sharing/enable-lan-mode'));
                                          },
                                          child: Text("More details on Bambu Lab Wiki"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Row (
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: Navigator.of(context).pop,

                        ),
                        ElevatedButton(
                          child: Text(connect ? 'Connect' : 'Save'),
                          onPressed: ((_testState == 0 && _tmpPass.length == 8) || _testState == 2) ? () {
                            printer.save(_tmpPass, _tmpAutoConnect);
                            Navigator.of(context).pop();
                            if (connect) printer.connect(context);
                          } : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BAMI.border(
      context,
      Scaffold(
        appBar: BAMI.bar(context),
        body: ListView(
          padding: const EdgeInsets.all(4),
          children: _discoveredPrinters(context),
        ),
      ),
    );
  }
}
