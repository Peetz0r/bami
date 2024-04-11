import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:wakelock_plus/wakelock_plus.dart';

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

      if (newPosition > 0 && (diff < 500 || diff > 2000)) {
        print('Stream borken, diff is $diff ms. Restarting...');
        _videoRestartCounter++;
        await _videoController.pause();
        await _videoController.seekTo(_videoController.value.position + const Duration(minutes: 1));
        await _videoController.play();
        print('Done restarting, hopefully.');
      }
      _videoPositionMS = newPosition;
    });
  }

  @override
  void deactivate() {
    _videoWatchdogTimer.cancel();
    _videoController.dispose();
    widget.printer.disconnect();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {

    return BAMI.border(
      context,
      Scaffold(
        appBar: BAMI.bar(
          context,
          ListTile(
            title: Text(widget.printer.name),
            subtitle: Text(widget.printer.model),
          ),
          PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: widget.printer.progress,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (BAMI.isTV) return _buildTV(constraints);
            if (constraints.maxWidth > 768) return _buildDesktop(constraints);
            return _buildMobile(constraints);
          },
        ),
      ),
    );
  }

  Widget _buildTV(BoxConstraints constraints) {
    WakelockPlus.enable();

    double sidePanelWidth = constraints.maxWidth - (constraints.maxHeight * 1760/1080);

    return Row(
      children: <Widget> [
        Container(
          child: Card(
            clipBehavior: Clip.hardEdge,
            elevation: 24,
            child: AspectRatio(
              aspectRatio: 1760/1080, // hardcoded, because _videoController.value.aspectRatio is not fast enough
              child: VideoPlayer(_videoController),
            ),
          ),
        ),

        Container(
          constraints: BoxConstraints.tightFor(width: sidePanelWidth),
          child: ListView(
            padding: const EdgeInsets.all(4),
            children: <Widget> [
              Text("Printer: ${widget.printer.toString()}"),
              Text("Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}"),
              Text("Video position: ${_videoController.value.position}"),
              Text("Video restarts: ${_videoRestartCounter}"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktop(BoxConstraints constraints) {
    return ListView(
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
    );
  }

  Widget _buildMobile(BoxConstraints constraints) {
    return ListView(
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
    );
  }

}
