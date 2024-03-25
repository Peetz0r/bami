import 'package:flutter/material.dart';

import 'main.dart';
import 'bambu.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key, required Bambu this.printer});

  final Bambu printer;

  @override
  State<PrinterPage> createState() {

    State<PrinterPage> state = _PrinterPageState();
    printer.onReport = (() {
      state.setState(() { /* updated report */ });
    });
    return state;
  }

}

class _PrinterPageState extends State<PrinterPage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: ListTile(
          title: Text(widget.printer.name),
          subtitle: Text(widget.printer.model),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: widget.printer.progress,
          ),
        ),
      ),
      body: Text(widget.printer.toString()),
    );
  }
}
