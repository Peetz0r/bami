import 'package:flutter/material.dart';

import 'main.dart';
import 'bambu.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key, required Bambu this.printer});

  final Bambu printer;

  @override
  State<PrinterPage> createState() {

    State<PrinterPage> state = _PrinterPageState();

    return state;
  }

}

class _PrinterPageState extends State<PrinterPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(BAMI.title),
      ),
      body: Text(widget.printer.toString()),
    );
  }
}
