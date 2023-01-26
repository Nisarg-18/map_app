import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class Home extends StatefulWidget {
  static const String route = 'latlng_screen_point_test_page';

  const Home({Key? key}) : super(key: key);

  @override
  State createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  late final MapController _mapController;

  CustomPoint _textPos = const CustomPoint(10.0, 10.0);
  Position? currentPosition;
  bool isLoading = true;
  SnackBar errorSnackBar = const SnackBar(
    content: Text('Error, please enable location permission'),
  );

  determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(errorSnackBar);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(errorSnackBar);
    }
    currentPosition = await Geolocator.getCurrentPosition();
    if (currentPosition != null) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    determinePosition();
  }

  void onMapEvent(MapEvent mapEvent) {
    if (mapEvent is! MapEventMove && mapEvent is! MapEventRotate) {
      // do not flood console with move and rotate events
      debugPrint(mapEvent.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Current Location')),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      onMapEvent: onMapEvent,
                      onTap: (tapPos, latLng) {
                        final pt1 = _mapController.latLngToScreenPoint(latLng);
                        _textPos = CustomPoint(pt1!.x, pt1.y);
                        setState(() {});
                      },
                      center: LatLng(currentPosition!.latitude,
                          currentPosition!.longitude),
                      zoom: 11,
                      rotation: 0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'dev.fleaflet.flutter_map.example',
                      ),
                    ],
                  ),
                ),
                Positioned(
                    left: _textPos.x.toDouble(),
                    top: _textPos.y.toDouble(),
                    width: 20,
                    height: 20,
                    child: const FlutterLogo())
              ]));
  }
}
