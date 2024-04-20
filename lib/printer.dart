import 'dart:io';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/animation/animation.dart';

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
  late AppLifecycleListener _appLifecycleListener;
  late VideoPlayerController _videoController;
  late Timer _videoWatchdogTimer;

  int _videoPositionMS = 0;
  int _videoRestartCounter = 0;

  @override
  void initState() {
    super.initState();

    _appLifecycleListener = AppLifecycleListener(
      onExitRequested: _onExitRequested,
    );

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

  Future<AppExitResponse> _onExitRequested() async {
    print("Exit requested");
    _videoWatchdogTimer.cancel();
    _videoController.dispose();
    widget.printer.disconnect();
    return AppExitResponse.exit;
  }

  @override
  void deactivate() {
    print("Deactivating");
    _videoWatchdogTimer.cancel();
    _videoController.dispose();
    widget.printer.disconnect();
    super.deactivate();
  }

  Widget _wideButtonsCard() {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  "${(widget.printer.progress*100).floor()}%",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Spacer(),
                Icon(Icons.layers),
                SizedBox(width: 8.0),
                Text("${widget.printer.layer}/${widget.printer.layers}"),
                Spacer(),
                Icon(Icons.av_timer),
                SizedBox(width: 8.0),
                Text("${widget.printer.remainingTimeString}"),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: LinearProgressIndicator(
              value: widget.printer.progress,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _buttonsList(),
          ),
        ],
      ),
    );
  }

  Widget _tallButtonsCard() {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Row(
            children: <Widget> [
              SizedBox(width: 32.0),
          Text(
            "${(widget.printer.progress*100).floor()}%",
            style: Theme.of(context).textTheme.headlineLarge,
          ),
            ],
          ),
          Row(
            children: <Widget> [
              Icon(Icons.layers),
              SizedBox(width: 8.0),
              Text(
                "${widget.printer.layer}/${widget.printer.layers}",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          Row(
            children: <Widget> [
              Icon(Icons.av_timer),
              SizedBox(width: 8.0),
              Text(
                "${widget.printer.remainingTimeString}",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _buttonsList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buttonsList() {
    return <Widget>[
      (widget.printer.isPaused ?
        Padding(
          padding: EdgeInsets.all(8.0),
          child: FilledButton.tonalIcon(
            icon: const Icon(
              Icons.start,
              color: Colors.green,
            ),
            label: const Text('Resume'),
            onPressed: () {
              widget.printer.resume();
            },
          ),
        ):
        Padding(
          padding: EdgeInsets.all(8.0),
          child: FilledButton.tonalIcon(
            icon: const Icon(
              Icons.pause,
              color: Colors.orange,
            ),
            label: const Text('Pause'),
            onPressed: (widget.printer.isRunning ? () {
              widget.printer.pause();
            } : null),
          ),
        )
      ),
      Padding(
        padding: EdgeInsets.all(8.0),
        child: FilledButton.icon(
          icon: const Icon(
            Icons.stop,
            color: Colors.red,
          ),
          label: const Text('Stop'),
          onPressed: (widget.printer.isRunning ? () {
            _stopPrintDialog();
          } : null),
        ),
      ),
    ];
  }

  Widget _videoCard() {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: AspectRatio(
        aspectRatio: 1760/1080, // _videoController.value.aspectRatio is not fast enough
        child: VideoPlayer(_videoController),
      ),
    );
  }

  Widget _amsCard() {
    List<Widget> amsColumn = [];
    for (final ams in widget.printer.amsFilaments) {
      List<Widget> filamentRow = [];
      for (final filament in ams) {
        filamentRow.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
            child: Column(
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints.tightForFinite(width: 20, height: 32),
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: LinearProgressIndicator(
                      value: filament.remain,
                      valueColor: AlwaysStoppedAnimation<Color>(filament.color),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints.tightForFinite(width: 32, height: 32),
                  child: Text(
                    filament.name,
                    maxLines: 2,
                    //~ overflow: TextOverflow.e,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      amsColumn.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: filamentRow,
        ),
      );
    }

    return Card(
      child: Column(
        children: amsColumn,
      ),
    );
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
            subtitle: Text(widget.printer.printName ?? 'Idle'),
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
          child: _videoCard(),
        ),
        Container(
          constraints: BoxConstraints.tightFor(width: sidePanelWidth),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _tallButtonsCard(),
                _amsCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktop(BoxConstraints constraints) {
    return ListView(
      padding: const EdgeInsets.all(4),
      children: <Widget> [
        Text("Desktop"),

        _videoCard(),
        _wideButtonsCard(),
        _amsCard(),

        Text("Printer: ${widget.printer.toString()}\n\nPlatform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}"),
        Text("playbackSpeed: ${_videoController.value.position}"),
        Text("Video restarts: ${_videoRestartCounter}"),
      ],
    );
  }

  Widget _buildMobile(BoxConstraints constraints) {
    return ListView(
      padding: const EdgeInsets.all(4),
      children: <Widget> [
        Text("Mobile"),

        _videoCard(),
        _wideButtonsCard(),
        _amsCard(),

        Text("Printer: ${widget.printer.toString()}\n\nPlatform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}"),
        Text("playbackSpeed: ${_videoController.value.position}"),
        Text("Video restarts: ${_videoRestartCounter}"),
      ],
    );
  }

  void _stopPrintDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stop'),
          content: const Text('Do you really want to stop the print?'),
          actions: <Widget>[
            FilledButton.tonal(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FilledButton.icon(
              icon: const Icon(
                Icons.stop,
                color: Colors.red,
              ),
              label: const Text('Yes'),
              onPressed: () {
                widget.printer.stop();
                Navigator.pop(context);
              },
            ),
          ],
        );
      }
    );
  }

}
