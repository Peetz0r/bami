import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bambu.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAMI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003e00)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Bambu Advanced Monitoring Interface'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;


  @override
  State<MyHomePage> createState() {
    State<MyHomePage> state = _MyHomePageState();
    Bambu.Discover(state);
    return state;
  }
}

class _MyHomePageState extends State<MyHomePage> {

  int _testState = 0;
  bool _tmpAutoConnect = false;
  String _tmpPass = '';

  List<Widget> _discoveredPrinters(BuildContext context) {
    var widget = <Widget>[];

    for (Bambu printer in Bambu.discoveredPrinters) {
      widget.add(
        Card(
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
                printer.connect();
              }

            },
            child: ListTile(
              leading: FlutterLogo(size: 72.0),
              title: Text(printer.name),
              subtitle: Text('Model: ${printer.model}\nIP: ${printer.ip}'),
              trailing: IconButton(
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
                icon: const Icon(Icons.settings),
              ),
            ),
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

  AlertDialog _settingsDialog(Bambu printer, setState, [bool connect = false]) {

    return AlertDialog(
      title: const Text('Settings'),
      content: SingleChildScrollView(
        child: Column(
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
                enableSuggestions: false,
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
            Card(
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
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: Navigator.of(context).pop,

        ),
        ElevatedButton(
          child: Text(connect ? 'Connect' : 'Save'),
          onPressed: ((_testState == 0 && _tmpPass.length == 8) || _testState == 2) ? () {
            printer.save(_tmpPass, _tmpAutoConnect);
            Navigator.of(context).pop();
            if (connect) printer.connect();
          } : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(
        children: _discoveredPrinters(context),
      ),
    );
  }
}
