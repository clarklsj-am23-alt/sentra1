import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../database/station_facilities_database.dart';
import '../../live_arrivals/services/gtfs_service.dart';

const Color appYellow = Color(0xFFFCEB00);

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  GoogleMapController? _mapController;
  final _facilityDb = StationFacilitiesDatabase.instance;
  final _gtfsService = GtfsService();

  bool _locationPermissionGranted = false;
  bool _gettingLocation = false;
  String _selectedTransport = 'All';
  bool _stepFreeOnly = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _transportTypes = ['All', 'LRT', 'MRT', 'KTM'];

  final List<Map<String, dynamic>> _stations = [
    {
      'name': 'KL Sentral',
      'type': 'LRT',
      'lines': 'LRT Kelana Jaya, MRT Kajang, KTMB',
      'latLng': const LatLng(3.1343, 101.6861),
      'isStepFree': true,
      'distance': '250 m',
    },
    {
      'name': 'Pasar Seni',
      'type': 'MRT',
      'lines': 'MRT Kajang Line, LRT Kelana Jaya',
      'latLng': const LatLng(3.1424, 101.6953),
      'isStepFree': true,
      'distance': '850 m',
    },
    {
      'name': 'Bukit Bintang',
      'type': 'MRT',
      'lines': 'MRT Kajang Line, KL Monorail',
      'latLng': const LatLng(3.1467, 101.7107),
      'isStepFree': true,
      'distance': '1.2 km',
    },
    {
      'name': 'Muzium Negara',
      'type': 'MRT',
      'lines': 'MRT Kajang Line',
      'latLng': const LatLng(3.1374, 101.6871),
      'isStepFree': true,
      'distance': '600 m',
    },
    {
      'name': 'Masjid Jamek',
      'type': 'LRT',
      'lines': 'LRT Kelana Jaya, LRT Ampang',
      'latLng': const LatLng(3.1492, 101.6966),
      'isStepFree': true,
      'distance': '1.4 km',
    },
    {
      'name': 'Titiwangsa',
      'type': 'MRT',
      'lines': 'MRT Putrajaya Line, LRT Ampang',
      'latLng': const LatLng(3.1735, 101.6954),
      'isStepFree': true,
      'distance': '2.5 km',
    },
    {
      'name': 'Maluri',
      'type': 'MRT',
      'lines': 'MRT Kajang Line, LRT Ampang',
      'latLng': const LatLng(3.1234, 101.7270),
      'isStepFree': true,
      'distance': '3.1 km',
    },
  ];

  List<Map<String, dynamic>> get _filteredStations {
    final query = _searchController.text.trim().toLowerCase();
    return _stations.where((station) {
      final matchesTransport = _selectedTransport == 'All' ||
          station['type'] == _selectedTransport;
      final matchesStepFree = !_stepFreeOnly || station['isStepFree'] == true;
      final matchesQuery = query.isEmpty ||
          station['name'].toString().toLowerCase().contains(query) ||
          station['lines'].toString().toLowerCase().contains(query);
      return matchesTransport && matchesStepFree && matchesQuery;
    }).toList();
  }

  Set<Marker> get _stationMarkers {
    return _filteredStations.map((station) {
      return Marker(
        markerId: MarkerId(station['name']),
        position: station['latLng'] as LatLng,
        infoWindow: InfoWindow(
          title: station['name'],
          snippet: '${station['lines']} • Tap for details',
        ),
        onTap: () => _openStationFacilitiesSheet(station),
      );
    }).toSet();
  }

  IconData _getFacilityIcon(String type) {
    switch (type) {
      case 'Lift':
        return Icons.elevator;
      case 'Ramp':
        return Icons.accessible;
      case 'OKU Toilet':
        return Icons.wc;
      case 'Accessible Gate':
        return Icons.door_front_door;
      case 'Tactile Paving':
        return Icons.accessibility_new;
      case 'Escalator':
        return Icons.escalator;
      case 'Surau':
        return Icons.mosque;
      default:
        return Icons.place;
    }
  }

  Future<void> _goToMyLocation() async {
    if (_gettingLocation) return;
    setState(() => _gettingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')),
        );
        return;
      }

      setState(() => _locationPermissionGranted = true);
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to acquire current location.')),
      );
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  void _openStationFacilitiesSheet(Map<String, dynamic> station) async {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(station['latLng'] as LatLng, 16.5),
    );

    // Fetch both Facilities (SQLite) and Live Departures (GTFS API) concurrently
    final results = await Future.wait([
      _facilityDb.getFacilities(search: station['name'] as String),
      _gtfsService.fetchArrivalsByMode(station['type'] as String),
    ]);

    final facilities = results[0] as List<Map<String, dynamic>>;
    final arrivals = results[1] as List<TransitArrival>;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.90,
          builder: (sheetContext, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              station['name'],
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              station['lines'],
                              style: GoogleFonts.dmSans(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        backgroundColor: appYellow,
                        label: Text(
                          station['type'],
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(
                        avatar: Icon(
                          station['isStepFree']
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: station['isStepFree'] ? Colors.green : Colors.red,
                        ),
                        label: Text(
                          station['isStepFree']
                              ? 'Step-Free Station'
                              : 'Limited Accessibility',
                          style: GoogleFonts.dmSans(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          '${facilities.length} Facilities',
                          style: GoogleFonts.dmSans(fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  // 1. LIVE GTFS TRANSIT DEPARTURES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Upcoming Arrivals',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'GTFS-RT',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (arrivals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No live departure records available.',
                        style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    ...arrivals.take(3).map((arr) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black,
                            child: Text(
                              arr.line.substring(0, 1),
                              style: GoogleFonts.dmSans(
                                color: appYellow,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  arr.line,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'To ${arr.destination} • ${arr.platform}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: appYellow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${arr.arrivalMinutes} min',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                  const Divider(height: 28),

                  // 2. ACCESSIBILITY & STATION FACILITIES
                  Text(
                    'Station Facilities & Accessibility',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (facilities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'No accessibility logs recorded for this station yet.',
                          style: GoogleFonts.dmSans(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...facilities.map((fac) {
                      final isAvailable =
                          fac['status'].toString().toLowerCase() == 'available';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(
                              _getFacilityIcon(fac['facility_type'].toString()),
                              color: Colors.black,
                            ),
                          ),
                          title: Text(
                            fac['facility_type'].toString(),
                            style:
                            GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Location: ${fac['location']}'),
                              if (fac['accessibility_note']
                                  ?.toString()
                                  .isNotEmpty ==
                                  true)
                                Text(
                                  fac['accessibility_note'].toString(),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isAvailable ? Colors.green : Colors.red,
                              ),
                            ),
                            child: Text(
                              fac['status'].toString(),
                              style: TextStyle(
                                color: isAvailable
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentra1 Accessibility Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(3.1450, 101.7000),
              zoom: 13.0,
            ),
            markers: _stationMarkers,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 6,
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.dmSans(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search station or transit line...',
                      hintStyle: GoogleFonts.dmSans(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: appYellow),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._transportTypes.map((type) {
                        final isSelected = _selectedTransport == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Text(
                              type,
                              style: GoogleFonts.dmSans(
                                color: isSelected ? Colors.black : appYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: appYellow,
                            backgroundColor: Colors.black,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedTransport = type);
                              }
                            },
                          ),
                        );
                      }),
                      FilterChip(
                        selected: _stepFreeOnly,
                        label: Text(
                          'Step-Free Only',
                          style: GoogleFonts.dmSans(
                            color: _stepFreeOnly ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        avatar: Icon(
                          Icons.accessible,
                          size: 16,
                          color: _stepFreeOnly ? Colors.black : appYellow,
                        ),
                        selectedColor: appYellow,
                        backgroundColor: Colors.black,
                        onSelected: (val) => setState(() => _stepFreeOnly = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.32,
            child: FloatingActionButton.small(
              backgroundColor: Colors.black,
              foregroundColor: appYellow,
              onPressed: _goToMyLocation,
              child: _gettingLocation
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: appYellow,
                ),
              )
                  : const Icon(Icons.my_location),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.14,
            maxChildSize: 0.70,
            builder: (context, scrollController) {
              final stations = _filteredStations;
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(blurRadius: 10, color: Colors.black26),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Nearby Accessible Stations (${stations.length})',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (stations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'No matching stations found.',
                            style: GoogleFonts.dmSans(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...stations.map((st) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _openStationFacilitiesSheet(st),
                        leading: CircleAvatar(
                          backgroundColor: st['isStepFree']
                              ? appYellow.withValues(alpha: 0.3)
                              : Colors.grey.shade300,
                          child: Icon(
                            st['isStepFree']
                                ? Icons.accessible
                                : Icons.not_accessible,
                            color: Colors.black,
                          ),
                        ),
                        title: Text(
                          st['name'],
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${st['type']} • ${st['lines']}',
                          style: GoogleFonts.dmSans(fontSize: 12),
                        ),
                        trailing: Text(
                          st['distance'],
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}