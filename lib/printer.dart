import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:fvp/fvp.dart' as fvp;

import 'main.dart';
import 'bambu.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key, required Bambu this.printer});

  final Bambu printer;

  @override
  State<PrinterPage> createState() {

    fvp.registerWith(options: {
      // yes, the platform-specific decoders are recommended, but they
      // don't seem to work reliably with the Bambu Labs ipcam streams
      'video.decoders': ['FFmpeg'],
    });

    State<PrinterPage> state = _PrinterPageState();
    printer.onReport = (() {
      state.setState(() { /* updated report */ });
    });
    return state;
  }

}

class _PrinterPageState extends State<PrinterPage> {
  late VideoPlayerController _videoController;
  late Timer _videoWatchdogTimer;

  int _videoPositionMS = 0;
  int _videoRestartCounter = 0;

  @override
  void initState() {
    super.initState();
    print("Starting video player with URL ${widget.printer.videoStreamUri}");
    _videoController = VideoPlayerController.network(widget.printer.videoStreamUri);

    _videoController.addListener(() {
      setState(() {});
    });
    _videoController.initialize().then((_) => setState(() {}));
    _videoController.play();

    _videoPositionMS = _videoController.value.position.inMilliseconds;

    _videoWatchdogTimer = Timer.periodic(Duration(seconds: 1), (Timer t) async {

      // No, this will not overflow. `int` can be 2^63-1, which in
      // milliseconds is over 290 million years. I think we're fine
      int newPosition = _videoController.value.position.inMilliseconds;

      int diff = newPosition - _videoPositionMS;
      print("$newPosition - $_videoPositionMS = ${diff}");
      if (newPosition > 0 && (diff < 500 || diff > 2000)) {
        print('Stream borken, diff is $diff ms. Restarting...');
        _videoRestartCounter++;
        await _videoController.pause();
        await _videoController.play();
        print('Done restarting, hopefully.');
      }
      _videoPositionMS = newPosition;
    });
  }

  @override
  void dispose() {
    print("Dispose videoController");
    _videoController.dispose();
    super.dispose();
  }



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
      body: ListView(
        padding: const EdgeInsets.all(4),
        children: <Widget> [
          Text("Printer: ${widget.printer.toString()}\n\nPlatform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}"),

          Card(
            clipBehavior: Clip.hardEdge,
            child: AspectRatio(
              aspectRatio: 1760/1080, // _videoController.value.aspectRatio is not fast enough
              child: VideoPlayer(_videoController),
            ),
          ),

          Text("playbackSpeed: ${_videoController.value.position}"),
          Text("Video restarts: ${_videoRestartCounter}"),
        ],
      ),



    );
  }
}
