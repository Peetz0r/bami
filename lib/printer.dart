import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'package:flutter_gstreamer_player/flutter_gstreamer_player.dart';

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

  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    var videoUrl = Uri.parse('rtsps://bblp:${widget.printer.pass}@${widget.printer.ip}:322/streaming/live/1');
    print(videoUrl);

    _controller = VideoPlayerController.networkUrl(videoUrl,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize();
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(BAMI.title),
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Text(widget.printer.toString()),

              Container(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1760/1080,
                  child: GstPlayer(
                    pipeline: "rtspsrc location=rtsps://bblp:${widget.printer.pass}@${widget.printer.ip}:322/streaming/live/1 protocols=tcp tls-validation-flags=G_TLS_CERTIFICATE_NO_FLAGS ! decodebin ! videoconvert ! video/x-raw,format=RGBA ! appsink name=sink",
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1760/1080,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      VideoPlayer(_controller),
                      VideoProgressIndicator(_controller, allowScrubbing: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
