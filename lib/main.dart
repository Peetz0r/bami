import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:macos_window_utils/macos/ns_window_button_type.dart';

import 'discovery.dart';
import 'printer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.operatingSystem == 'android') {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    BAMI.isTV = androidInfo.systemFeatures.contains('android.software.leanback');
  }

  if (Platform.isMacOS) {
    await WindowManipulator.initialize(enableWindowDelegate: true);

    WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.closeButton,
      offset: const Offset(20, 20)
    );
    WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.miniaturizeButton,
      offset: const Offset(40, 20)
    );
    WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.zoomButton,
      offset: const Offset(60, 20)
    );
  }

  runApp(const BAMI());

  if (BAMI.isDesktop) {
    doWhenWindowReady(() {
      appWindow.size = const Size(600, 600);
      appWindow.minSize = const Size(320, 320);
      appWindow.show();
    });
  }
}

class BAMI extends StatelessWidget {
  const BAMI({super.key});

  static FlutterSecureStorage prefs = FlutterSecureStorage(
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static bool isTV = false;
  static bool isMobile = !isTV && ['ios', 'android'].contains(Platform.operatingSystem);
  static bool isDesktop = !isTV && !isMobile;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAMI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003e00),
          brightness: Brightness.light,
        ),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003e00),
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
      ),
      themeMode: BAMI.isTV ? ThemeMode.dark : ThemeMode.system,
      home: const DiscoveryPage(),
    );
  }

  static AppBar bar(BuildContext context, [Widget? titleWidget, PreferredSizeWidget? bottomWidget]) {
    ColorScheme cs = Theme.of(context).colorScheme;

    if (titleWidget == null) {
      titleWidget = ListTile(
        title: Text('BAMI', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Bambu Advanced Monitoring Interface'),
        contentPadding: Platform.isMacOS ? const EdgeInsets.only(left: 80.0) : null,
      );
    }

    if (!isDesktop) {
      return AppBar(
        backgroundColor: cs.inversePrimary,
        title: titleWidget,
        bottom: bottomWidget,
      );
    }

    final buttonColors = WindowButtonColors(
      iconNormal: cs.inverseSurface,
      mouseOver: cs.inverseSurface,
      mouseDown: cs.inverseSurface,
      iconMouseOver: cs.inversePrimary,
      iconMouseDown: cs.onPrimary,
    );

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          appWindow.startDragging();
        },
        onDoubleTap: () => appWindow.maximizeOrRestore(),
        child: titleWidget,
      ),
      bottom: bottomWidget,
      actions: <Widget>[
        Container(
          alignment: Alignment.topRight,
          child: Row(
            children: <Widget>[
              MinimizeWindowButton(colors: buttonColors, animate: true),
              MaximizeWindowButton(colors: buttonColors, animate: true),
              CloseWindowButton(colors: buttonColors, animate: true),
            ],
          ),
        ),
      ],
    );
  }

  static Widget border(BuildContext context, Widget child) {
    ColorScheme cs = Theme.of(context).colorScheme;

    if (!isDesktop) return child;
    return WindowBorder(
      color: cs.outline,
      width: 1,
      child: child,
    );
  }
}
