import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StationMapScreen extends StatefulWidget {
  const StationMapScreen({super.key});

  @override
  State<StationMapScreen> createState() => _StationMapScreenState();
}

class _StationMapScreenState extends State<StationMapScreen> {
  // KL Sentral coordinates
  static const LatLng klSentral = LatLng(
    3.1343,
    101.6861,
  );

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('kl_sentral'),
      position: klSentral,
      infoWindow: InfoWindow(
        title: 'KL Sentral',
        snippet: 'Transit Station',
      ),
    ),

    const Marker(
      markerId: MarkerId('pasar_seni'),
      position: LatLng(3.1424, 101.6953),
      infoWindow: InfoWindow(
        title: 'Pasar Seni',
        snippet: 'LRT / MRT Station',
      ),
    ),

    const Marker(
      markerId: MarkerId('bukit_bintang'),
      position: LatLng(3.1467, 101.7107),
      infoWindow: InfoWindow(
        title: 'Bukit Bintang',
        snippet: 'MRT Station',
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station Map'),
      ),

      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: klSentral,
          zoom: 13,
        ),

        markers: _markers,

        mapType: MapType.normal,

        zoomControlsEnabled: true,

        myLocationButtonEnabled: false,
      ),
    );
  }
}