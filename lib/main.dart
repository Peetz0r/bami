import 'package:flutter/material.dart';
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

  List<Widget> _discoveredPrinters() {
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
                print("Settings for $printer");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(
        children: _discoveredPrinters(),
      ),
    );
  }
}
