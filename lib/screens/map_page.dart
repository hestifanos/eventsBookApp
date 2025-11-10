import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;

  // Example: Ontario Tech University coordinates (rough)
  static const _campusCenter = LatLng(43.9449, -78.8964);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Map')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _campusCenter,
          zoom: 15,
        ),
        onMapCreated: (c) => _controller = c,
        markers: {
          const Marker(
            markerId: MarkerId('campus'),
            position: _campusCenter,
            infoWindow: InfoWindow(title: 'Campus'),
          ),
        },
      ),
    );
  }
}
