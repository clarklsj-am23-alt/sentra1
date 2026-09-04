import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class StationMapScreen extends StatefulWidget {
  const StationMapScreen({super.key});

  @override
  State<StationMapScreen> createState() =>
      _StationMapScreenState();
}

class _StationMapScreenState extends State<StationMapScreen> {
  GoogleMapController? _mapController;

  bool _locationPermissionGranted = false;
  bool _gettingLocation = false;

  // =========================================================
  // STATION LOCATIONS
  // Same station list as Station Facilities
  // =========================================================

  final Map<String, LatLng> stationLocations = {
    'KL Sentral': const LatLng(
      3.1343,
      101.6861,
    ),

    'Pasar Seni': const LatLng(
      3.1424,
      101.6953,
    ),

    'Bukit Bintang': const LatLng(
      3.1467,
      101.7107,
    ),

    'Muzium Negara': const LatLng(
      3.1374,
      101.6871,
    ),

    'Masjid Jamek': const LatLng(
      3.1492,
      101.6966,
    ),

    'Titiwangsa': const LatLng(
      3.1735,
      101.6954,
    ),

    'Maluri': const LatLng(
      3.1234,
      101.7270,
    ),
  };

  // =========================================================
  // MARKERS
  // =========================================================

  Set<Marker> get _stationMarkers {
    return stationLocations.entries.map(
          (station) {
        return Marker(
          markerId: MarkerId(
            station.key,
          ),
          position: station.value,

          infoWindow: InfoWindow(
            title: station.key,
            snippet:
            'Tap to view station location',
          ),

          onTap: () {
            _showStationDetails(
              station.key,
              station.value,
            );
          },
        );
      },
    ).toSet();
  }

  // =========================================================
  // STATION DETAILS
  // =========================================================

  void _showStationDetails(
      String stationName,
      LatLng position,
      ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return Padding(
          padding:
          const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 28,
                child: Icon(
                  Icons.train,
                  size: 30,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                stationName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(
                'Transit Station',
              ),

              const SizedBox(
                height: 20,
              ),

              SizedBox(
                width:
                double.infinity,
                child:
                ElevatedButton.icon(
                  style: ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    Colors.black,
                    foregroundColor:
                    Colors.white,
                  ),

                  onPressed: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    _mapController
                        ?.animateCamera(
                      CameraUpdate
                          .newLatLngZoom(
                        position,
                        17,
                      ),
                    );
                  },

                  icon: const Icon(
                    Icons.location_on,
                  ),

                  label: const Text(
                    'Focus on Station',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // CURRENT LOCATION
  // =========================================================

  Future<void> _goToMyLocation() async {
    if (_gettingLocation) return;

    setState(() {
      _gettingLocation = true;
    });

    try {
      // Check if GPS is enabled
      final bool serviceEnabled =
      await Geolocator
          .isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showErrorSnackBar(
          'Please turn on location services.',
        );

        return;
      }

      // Check permission
      LocationPermission permission =
      await Geolocator
          .checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
        await Geolocator
            .requestPermission();
      }

      if (permission ==
          LocationPermission.denied ||
          permission ==
              LocationPermission
                  .deniedForever) {
        _showErrorSnackBar(
          'Location permission is required.',
        );

        return;
      }

      setState(() {
        _locationPermissionGranted =
        true;
      });

      // Get real current location
      final Position position =
      await Geolocator
          .getCurrentPosition(
        locationSettings:
        const LocationSettings(
          accuracy:
          LocationAccuracy.high,
        ),
      );

      final LatLng currentPosition =
      LatLng(
        position.latitude,
        position.longitude,
      );

      await _mapController
          ?.animateCamera(
        CameraUpdate.newLatLngZoom(
          currentPosition,
          17,
        ),
      );

      if (!mounted) return;

      _showSuccessSnackBar(
        'Current location found.',
      );
    } catch (e) {
      _showErrorSnackBar(
        'Unable to get your location.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  // =========================================================
  // SUCCESS SNACKBAR
  // =========================================================

  void _showSuccessSnackBar(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
        Colors.green,
        behavior:
        SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Text(
                message,
                style:
                const TextStyle(
                  color:
                  Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ERROR SNACKBAR
  // =========================================================

  void _showErrorSnackBar(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
        Colors.red,
        behavior:
        SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Text(
                message,
                style:
                const TextStyle(
                  color:
                  Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text(
          'Station Map',
        ),
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
            const CameraPosition(
              target: LatLng(
                3.1450,
                101.7000,
              ),
              zoom: 12.5,
            ),

            markers:
            _stationMarkers,

            mapType:
            MapType.normal,

            zoomControlsEnabled:
            true,

            myLocationEnabled:
            _locationPermissionGranted,

            myLocationButtonEnabled:
            false,

            onMapCreated:
                (controller) {
              _mapController =
                  controller;
            },
          ),

          // =================================================
          // STATION COUNT
          // =================================================

          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius
                    .circular(
                  20,
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 5,
                    color:
                    Colors.black26,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.train,
                    size: 20,
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Text(
                    '${stationLocations.length} stations',
                    style:
                    const TextStyle(
                      color:
                      Colors.black,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =================================================
          // MY LOCATION BUTTON
          // =================================================

          Positioned(
            right: 16,
            bottom: 30,
            child:
            FloatingActionButton.extended(
              backgroundColor:
              Colors.black,

              foregroundColor:
              Colors.white,

              onPressed:
              _gettingLocation
                  ? null
                  : _goToMyLocation,

              icon: _gettingLocation
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  Colors.white,
                ),
              )
                  : const Icon(
                Icons.my_location,
              ),

              label: Text(
                _gettingLocation
                    ? 'Locating...'
                    : 'My Location',
              ),
            ),
          ),
        ],
      ),
    );
  }
}