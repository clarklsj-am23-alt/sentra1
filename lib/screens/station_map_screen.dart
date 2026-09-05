import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class StationMapScreen extends StatefulWidget {
  final String? initialStation;

  const StationMapScreen({super.key, this.initialStation});

  @override
  State<StationMapScreen> createState() => _StationMapScreenState();
}

class _StationMapScreenState extends State<StationMapScreen> {
  GoogleMapController? _mapController;

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;

  static const String _placesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
  );

  bool _locationPermissionGranted = false;
  bool _gettingLocation = false;
  bool _searchingPlaces = false;

  List<_PlaceSuggestion> _suggestions = [];

  Marker? _searchedPlaceMarker;

  final Map<String, LatLng> stationLocations = {
    'KL Sentral': const LatLng(3.1343, 101.6861),
    'Pasar Seni': const LatLng(3.1424, 101.6953),
    'Bukit Bintang': const LatLng(3.1467, 101.7107),
    'Muzium Negara': const LatLng(3.1374, 101.6871),
    'Masjid Jamek': const LatLng(3.1492, 101.6966),
    'Titiwangsa': const LatLng(3.1735, 101.6954),
    'Maluri': const LatLng(3.1234, 101.7270),
  };

  @override
  void initState() {
    super.initState();
  }

  Set<Marker> get _stationMarkers {
    return stationLocations.entries.map((station) {
      return Marker(
        markerId: MarkerId(station.key),
        position: station.value,
        infoWindow: InfoWindow(
          title: station.key,
          snippet: 'Tap marker to view station',
        ),
        onTap: () {
          _showStationDetails(station.key, station.value);
        },
      );
    }).toSet();
  }

  Set<Marker> get _allMarkers {
    final markers = <Marker>{..._stationMarkers};

    if (_searchedPlaceMarker != null) {
      markers.add(_searchedPlaceMarker!);
    }

    return markers;
  }

  void _focusInitialStation() {
    final stationName = widget.initialStation;

    if (stationName == null) return;

    final position = stationLocations[stationName];

    if (position == null) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 17));

      if (mounted) {
        _showSuccessSnackBar('$stationName shown on map.');
      }
    });
  }

  // =========================================================
  // GOOGLE PLACES
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

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (_placesApiKey.isEmpty) {
      _showErrorSnackBar('Google Places API key is not configured.');
      return;
    }

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
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _placesApiKey,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,'
              'suggestions.placePrediction.text.text',
        },
        body: jsonEncode({
          'input': query,
          'includedRegionCodes': ['my'],
          'languageCode': 'en',
          'locationBias': {
            'circle': {
              'center': {'latitude': 3.1390, 'longitude': 101.6869},
              'radius': 60000.0,
            },
          },
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Places autocomplete error: ${response.statusCode}');
        debugPrint(response.body);

        _showErrorSnackBar('Unable to search places.');
        return;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      final dynamic rawSuggestions = data['suggestions'];

      final List<_PlaceSuggestion> results = [];

      if (rawSuggestions is List) {
        for (final item in rawSuggestions) {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final prediction = item['placePrediction'];

          if (prediction is! Map<String, dynamic>) {
            continue;
          }

          final String placeId = prediction['placeId']?.toString() ?? '';

          final dynamic text = prediction['text'];

          String description = '';

          if (text is Map<String, dynamic>) {
            description = text['text']?.toString() ?? '';
          }

          if (placeId.isNotEmpty && description.isNotEmpty) {
            results.add(
              _PlaceSuggestion(placeId: placeId, description: description),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _suggestions = results;
      });
    } catch (e) {
      debugPrint('Places search error: $e');

      _showErrorSnackBar('Unable to search places.');
    } finally {
      if (mounted) {
        setState(() {
          _searchingPlaces = false;
        });
      }
    }
  }

  Future<void> _selectPlace(_PlaceSuggestion suggestion) async {
    if (_placesApiKey.isEmpty) {
      _showErrorSnackBar('Google Places API key is not configured.');
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
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _placesApiKey,
          'X-Goog-FieldMask': 'location,displayName,formattedAddress',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Place details error: ${response.statusCode}');
        debugPrint(response.body);

        _showErrorSnackBar('Unable to open this place.');
        return;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      final dynamic location = data['location'];

      if (location is! Map<String, dynamic>) {
        _showErrorSnackBar('Location information unavailable.');
        return;
      }

      final double? latitude = (location['latitude'] as num?)?.toDouble();

      final double? longitude = (location['longitude'] as num?)?.toDouble();

      if (latitude == null || longitude == null) {
        _showErrorSnackBar('Location information unavailable.');
        return;
      }

      String displayName = suggestion.description;

      final dynamic displayNameData = data['displayName'];

      if (displayNameData is Map<String, dynamic>) {
        final value = displayNameData['text']?.toString();

        if (value != null && value.isNotEmpty) {
          displayName = value;
        }
      }

      final String address = data['formattedAddress']?.toString() ?? '';

      final LatLng placePosition = LatLng(latitude, longitude);

      if (!mounted) return;

      setState(() {
        _searchController.text = displayName;

        _searchedPlaceMarker = Marker(
          markerId: MarkerId('searched_${suggestion.placeId}'),
          position: placePosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(title: displayName, snippet: address),
        );
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(placePosition, 16),
      );

      _showSuccessSnackBar('$displayName found.');
    } catch (e) {
      debugPrint('Place details error: $e');

      _showErrorSnackBar('Unable to open this place.');
    } finally {
      if (mounted) {
        setState(() {
          _searchingPlaces = false;
        });
      }
    }
  }

  void _clearSearch() {
    _debounce?.cancel();

    _searchController.clear();
    _searchFocusNode.unfocus();

    setState(() {
      _suggestions = [];
      _searchedPlaceMarker = null;
    });
  }

  // =========================================================
  // STATION DETAILS
  // =========================================================

  void _showStationDetails(String stationName, LatLng position) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.train, color: Colors.white, size: 32),
                ),

                const SizedBox(height: 12),

                Text(
                  stationName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                const Text('Transit Station'),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(bottomSheetContext);

                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(position, 17),
                      );
                    },
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Focus on Station'),
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
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showErrorSnackBar('Please turn on location services.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permission is required.');
        return;
      }

      if (!mounted) return;

      setState(() {
        _locationPermissionGranted = true;
      });

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final LatLng currentPosition = LatLng(
        position.latitude,
        position.longitude,
      );

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentPosition, 17),
      );

      _showSuccessSnackBar('Current location found.');
    } catch (e) {
      _showErrorSnackBar('Unable to get your location.');
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Stations')),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(3.1450, 101.7000),
              zoom: 12.5,
            ),

            markers: _allMarkers,

            myLocationEnabled: _locationPermissionGranted,

            myLocationButtonEnabled: false,

            onMapCreated: (controller) {
              _mapController = controller;

              _focusInitialStation();
            },
          ),

          // SEARCH BAR
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search places in Malaysia...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchingPlaces
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          if (_suggestions.isNotEmpty)
            Positioned(
              top: 78,
              left: 14,
              right: 14,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];

                      return ListTile(
                        tileColor: Colors.white,
                        leading: const Icon(Icons.place, color: Colors.black),
                        title: Text(
                          suggestion.description,
                          style: const TextStyle(color: Colors.black),
                        ),
                        onTap: () {
                          _selectPlace(suggestion);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

          if (_suggestions.isEmpty)
            Positioned(
              top: 78,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(blurRadius: 5, color: Colors.black26),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.train, color: Colors.black),
                    const SizedBox(width: 7),
                    Text(
                      '${stationLocations.length} stations',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            right: 16,
            bottom: 30,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              onPressed: _gettingLocation ? null : _goToMyLocation,
              icon: _gettingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_gettingLocation ? 'Locating...' : 'My Location'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}

class _PlaceSuggestion {
  final String placeId;
  final String description;

  const _PlaceSuggestion({required this.placeId, required this.description});
}
