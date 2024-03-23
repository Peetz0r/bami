import 'package:flutter/material.dart';
import 'package:upnp2/upnp.dart';
import 'main.dart';

class Bambu {

  static List<Bambu> discoveredPrinters = [];

  String ip;
  String usn;
  String name;
  String model;
  String? pass;

  static Discover(State<MyHomePage> state) {
    print("Bambu discovery starting");

    DeviceDiscoverer discoverer = DeviceDiscoverer();
    discoverer.start(port: 2021);

    Stream<DiscoveredClient> discoverStream = discoverer.quickDiscoverClients(timeout: const Duration(seconds: 15));
    // I would like to add query: "urn:bambulab-com:device:3dprinter:1"
    // but it sends that over a hardcoded port 1900, while it needs to be 2021
    // because Bambu uses a nonstandard variation of uPnP/SSDP
    // so we'll just wait until the printer sends it's own broadcast packet
    // it's once every 5 seconds, not too bad

    discoverStream.listen((DiscoveredClient client) {
      if (client.headers?['NT'] == "urn:bambulab-com:device:3dprinter:1") {

        Bambu newBambu = new Bambu(
          client.headers!['LOCATION']!,
          client.headers!['USN']!,
          client.headers!['DEVNAME.BAMBU.COM']!,
          client.headers!['DEVMODEL.BAMBU.COM']!,
        );
        print("found new $newBambu");
        state.setState(() {
          discoveredPrinters.add(newBambu);
        });
      }
    });
  }

  Bambu(this.ip, this.usn, this.name, this.model) {

  }

  String toString() {
    return "$model($ip | $name | $usn | Pass: ${pass == null ? 'N/A' : '*'*pass!.length})";
  }

}
