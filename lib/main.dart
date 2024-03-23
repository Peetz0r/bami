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

    print("list of d: ${Bambu.discoveredPrinters}");

    for (Bambu printer in Bambu.discoveredPrinters) {
      widget.add(
        Card(
          child: ListTile(
            leading: FlutterLogo(size: 72.0),
            title: Text(printer.name),
            subtitle: Text('Model: ${printer.model}\nIP: ${printer.ip}'),
            trailing: Icon(printer.pass == null ? Icons.lock : Icons.send),
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
