import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class StationMapScreen extends StatefulWidget {
  const StationMapScreen({super.key});

  @override
  State<StationMapScreen> createState() =>
      _StationMapScreenState();
}

class _StationMapScreenState extends State<StationMapScreen> {
  GoogleMapController? _mapController;

  final TextEditingController _searchController =
  TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;

  static const String _placesApiKey =
  String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
  );

  bool _locationPermissionGranted = false;
  bool _gettingLocation = false;
  bool _searchingPlaces = false;

  List<_PlaceSuggestion> _suggestions = [];

  Marker? _searchedPlaceMarker;

  // =========================================================
  // STATION LOCATIONS
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
  // STATION MARKERS
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
  // ALL MARKERS
  // Station markers + searched Google Place
  // =========================================================

  Set<Marker> get _allMarkers {
    final markers = <Marker>{
      ..._stationMarkers,
    };

    if (_searchedPlaceMarker != null) {
      markers.add(
        _searchedPlaceMarker!,
      );
    }

    return markers;
  }

  // =========================================================
  // GOOGLE PLACES AUTOCOMPLETE
  // =========================================================

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _searchingPlaces = false;
      });

      return;
    }

    _debounce = Timer(
      const Duration(
        milliseconds: 500,
      ),
          () {
        _searchPlaces(query);
      },
    );
  }

  Future<void> _searchPlaces(
      String query,
      ) async {
    if (_placesApiKey.isEmpty) {
      _showErrorSnackBar(
        'Google Places API key is not configured.',
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      _searchingPlaces = true;
    });

    try {
      final Uri url = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type':
          'application/json',
          'X-Goog-Api-Key':
          _placesApiKey,

          // Only request the fields
          // needed for autocomplete.
          'X-Goog-FieldMask':
          'suggestions.placePrediction.placeId,'
              'suggestions.placePrediction.text.text',
        },
        body: jsonEncode({
          'input': query,

          // Only Malaysia results
          'includedRegionCodes': [
            'my',
          ],

          'languageCode': 'en',

          // Prefer Kuala Lumpur area
          'locationBias': {
            'circle': {
              'center': {
                'latitude': 3.1390,
                'longitude': 101.6869,
              },
              'radius': 60000.0,
            },
          },
        }),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        debugPrint(
          'Places autocomplete error: '
              '${response.statusCode}',
        );

        debugPrint(
          response.body,
        );

        if (!mounted) return;

        setState(() {
          _suggestions = [];
        });

        _showErrorSnackBar(
          'Unable to search places.',
        );

        return;
      }

      final Map<String, dynamic> data =
      jsonDecode(
        response.body,
      );

      final dynamic rawSuggestions =
      data['suggestions'];

      final List<_PlaceSuggestion>
      newSuggestions = [];

      if (rawSuggestions is List) {
        for (final item
        in rawSuggestions) {
          if (item
          is! Map<String, dynamic>) {
            continue;
          }

          final dynamic prediction =
          item['placePrediction'];

          if (prediction
          is! Map<String, dynamic>) {
            continue;
          }

          final String placeId =
              prediction['placeId']
                  ?.toString() ??
                  '';

          String description = '';

          final dynamic text =
          prediction['text'];

          if (text
          is Map<String, dynamic>) {
            description =
                text['text']
                    ?.toString() ??
                    '';
          }

          if (placeId.isNotEmpty &&
              description.isNotEmpty) {
            newSuggestions.add(
              _PlaceSuggestion(
                placeId: placeId,
                description:
                description,
              ),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _suggestions =
            newSuggestions;
      });
    } catch (e) {
      debugPrint(
        'Places search error: $e',
      );

      if (!mounted) return;

      setState(() {
        _suggestions = [];
      });

      _showErrorSnackBar(
        'Unable to search places.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _searchingPlaces = false;
        });
      }
    }
  }

  // =========================================================
  // SELECT GOOGLE PLACE
  // =========================================================

  Future<void> _selectPlace(
      _PlaceSuggestion suggestion,
      ) async {
    if (_placesApiKey.isEmpty) {
      _showErrorSnackBar(
        'Google Places API key is not configured.',
      );

      return;
    }

    setState(() {
      _searchingPlaces = true;
      _suggestions = [];
    });

    _searchFocusNode.unfocus();

    try {
      final Uri url = Uri.parse(
        'https://places.googleapis.com/v1/places/'
            '${suggestion.placeId}',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type':
          'application/json',

          'X-Goog-Api-Key':
          _placesApiKey,

          'X-Goog-FieldMask':
          'location,displayName,formattedAddress',
        },
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        debugPrint(
          'Place details error: '
              '${response.statusCode}',
        );

        debugPrint(
          response.body,
        );

        _showErrorSnackBar(
          'Unable to open this place.',
        );

        return;
      }

      final Map<String, dynamic> data =
      jsonDecode(
        response.body,
      );

      final dynamic location =
      data['location'];

      if (location
      is! Map<String, dynamic>) {
        _showErrorSnackBar(
          'Location information is unavailable.',
        );

        return;
      }

      final double? latitude =
      (location['latitude']
      as num?)
          ?.toDouble();

      final double? longitude =
      (location['longitude']
      as num?)
          ?.toDouble();

      if (latitude == null ||
          longitude == null) {
        _showErrorSnackBar(
          'Location information is unavailable.',
        );

        return;
      }

      String displayName =
          suggestion.description;

      final dynamic displayNameData =
      data['displayName'];

      if (displayNameData
      is Map<String, dynamic>) {
        final value =
        displayNameData['text']
            ?.toString();

        if (value != null &&
            value.isNotEmpty) {
          displayName = value;
        }
      }

      final String address =
          data['formattedAddress']
              ?.toString() ??
              '';

      final LatLng placePosition =
      LatLng(
        latitude,
        longitude,
      );

      if (!mounted) return;

      setState(() {
        _searchController.text =
            displayName;

        _searchedPlaceMarker =
            Marker(
              markerId: MarkerId(
                'google_place_'
                    '${suggestion.placeId}',
              ),
              position: placePosition,
              infoWindow: InfoWindow(
                title: displayName,
                snippet: address.isEmpty
                    ? 'Google Place'
                    : address,
              ),
              icon: BitmapDescriptor
                  .defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            );
      });

      await _mapController
          ?.animateCamera(
        CameraUpdate.newLatLngZoom(
          placePosition,
          16,
        ),
      );

      _showSuccessSnackBar(
        '$displayName found.',
      );
    } catch (e) {
      debugPrint(
        'Place details error: $e',
      );

      _showErrorSnackBar(
        'Unable to open this place.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _searchingPlaces = false;
        });
      }
    }
  }

  // =========================================================
  // CLEAR SEARCH
  // =========================================================

  void _clearSearch() {
    _debounce?.cancel();

    _searchController.clear();

    _searchFocusNode.unfocus();

    setState(() {
      _suggestions = [];
      _searchedPlaceMarker = null;
      _searchingPlaces = false;
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(
            3.1450,
            101.7000,
          ),
          zoom: 12.5,
        ),
      ),
    );
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
      builder: (
          bottomSheetContext,
          ) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(
              20,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor:
                  Colors.black,
                  child: Icon(
                    Icons.train,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Text(
                  stationName,
                  style:
                  const TextStyle(
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
                    style:
                    ElevatedButton
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
      final bool serviceEnabled =
      await Geolocator
          .isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showErrorSnackBar(
          'Please turn on location services.',
        );

        return;
      }

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

      if (!mounted) return;

      setState(() {
        _locationPermissionGranted =
        true;
      });

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
  // GREEN SNACKBAR
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
        duration:
        const Duration(
          seconds: 2,
        ),
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
                  color: Colors.white,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // RED SNACKBAR
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
        duration:
        const Duration(
          seconds: 3,
        ),
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
                  color: Colors.white,
                  fontWeight:
                  FontWeight.w600,
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
        title: const Text(
          'Station Map',
        ),
      ),

      body: Stack(
        children: [
          // =================================================
          // GOOGLE MAP
          // =================================================

          GoogleMap(
            initialCameraPosition:
            const CameraPosition(
              target: LatLng(
                3.1450,
                101.7000,
              ),
              zoom: 12.5,
            ),

            markers: _allMarkers,

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
          // GOOGLE PLACES SEARCH BAR
          // =================================================

          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Material(
              elevation: 6,
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              child: TextField(
                controller:
                _searchController,

                focusNode:
                _searchFocusNode,

                onChanged:
                _onSearchChanged,

                decoration:
                InputDecoration(
                  hintText:
                  'Search places in Malaysia...',

                  prefixIcon:
                  const Icon(
                    Icons.search,
                  ),

                  suffixIcon:
                  _searchingPlaces
                      ? const Padding(
                    padding:
                    EdgeInsets
                        .all(
                      14,
                    ),
                    child:
                    SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                      ),
                    ),
                  )
                      : _searchController
                      .text
                      .isNotEmpty
                      ? IconButton(
                    tooltip:
                    'Clear',
                    onPressed:
                    _clearSearch,
                    icon:
                    const Icon(
                      Icons.clear,
                    ),
                  )
                      : null,

                  filled: true,
                  fillColor:
                  Colors.white,

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      14,
                    ),
                    borderSide:
                    BorderSide.none,
                  ),

                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      14,
                    ),
                    borderSide:
                    BorderSide.none,
                  ),

                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      14,
                    ),
                    borderSide:
                    const BorderSide(
                      color:
                      Colors.black,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // =================================================
          // AUTOCOMPLETE RESULTS
          // =================================================

          if (_suggestions.isNotEmpty)
            Positioned(
              top: 78,
              left: 14,
              right: 14,
              child: Material(
                elevation: 8,
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                clipBehavior:
                Clip.antiAlias,
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(
                    maxHeight: 260,
                  ),
                  child:
                  ListView.separated(
                    shrinkWrap: true,
                    padding:
                    EdgeInsets.zero,
                    itemCount:
                    _suggestions
                        .length,
                    separatorBuilder:
                        (
                        context,
                        index,
                        ) =>
                    const Divider(
                      height: 1,
                    ),
                    itemBuilder:
                        (
                        context,
                        index,
                        ) {
                      final suggestion =
                      _suggestions[
                      index];

                      return ListTile(
                        tileColor:
                        Colors.white,
                        leading:
                        const Icon(
                          Icons.place,
                          color:
                          Colors.black,
                        ),
                        title: Text(
                          suggestion
                              .description,
                          style:
                          const TextStyle(
                            color:
                            Colors.black,
                          ),
                        ),
                        onTap: () {
                          _selectPlace(
                            suggestion,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

          // =================================================
          // STATION COUNT
          // Hide while suggestions are open
          // =================================================

          if (_suggestions.isEmpty)
            Positioned(
              top: 78,
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
                  boxShadow:
                  const [
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
                      color:
                      Colors.black,
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
                        FontWeight
                            .w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // =================================================
          // MY LOCATION
          // =================================================

          Positioned(
            right: 16,
            bottom: 30,
            child:
            FloatingActionButton
                .extended(
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

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _debounce?.cancel();

    _searchController.dispose();

    _searchFocusNode.dispose();

    _mapController?.dispose();

    super.dispose();
  }
}

// ===========================================================
// GOOGLE PLACE AUTOCOMPLETE MODEL
// ===========================================================

class _PlaceSuggestion {
  final String placeId;
  final String description;

  const _PlaceSuggestion({
    required this.placeId,
    required this.description,
  });
}