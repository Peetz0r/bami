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

  List<Widget> _discoveredPrinters(BuildContext context) {
    var widget = <Widget>[];

    for (Bambu printer in Bambu.discoveredPrinters) {
      widget.add(
        Card(
          child: ListTile(
            leading: FlutterLogo(size: 72.0),
            title: Text(printer.name),
            subtitle: Text('Model: ${printer.model}\nIP: ${printer.ip}'),
            trailing: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return _settingsDialog(printer);
                  },
                );
              },
              icon: const Icon(Icons.settings),
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

  AlertDialog _settingsDialog(Bambu printer) {

    return AlertDialog(
      // Retrieve the text that the user has entered by using the
      // TextEditingController.
      title: const Text('Settings'),
      content: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(),
        //~ maxWidth: 0.5,
        child: Column(
          children: <Widget>[
            Card(
              child: ListTile(
                leading: FlutterLogo(size: 72.0),
                title: Text(printer.name),
                subtitle: Text('Model: ${printer.model}\nIP: ${printer.ip}'),
              ),
            ),
            Text("You can only connect locally to a Bambu Labs 3D printer in Lan Only mode. To do this you'll need to enable LAN Only mode on the screen on your printer, and use the Access Code from the display in the app."),
            ElevatedButton(
              onPressed: () {
                launchUrl(Uri.parse('https://wiki.bambulab.com/en/knowledge-sharing/enable-lan-mode'));
              },
              child: Text("More details om Bambu Lab Wiki"),
            ),
            TextFormField(
              decoration: InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Access Code',
                hintText: 'On the printers display',
              ),
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Test'),
          onPressed: () {
            printer.testConnection("foo");
          },
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            Navigator.of(context).pop();
          },
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
