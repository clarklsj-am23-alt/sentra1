import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../screens/station_map_screen.dart';

const Color appYellow = Color(0xFFFCEB00);

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  String _selectedTransport = 'All';
  bool _stepFreeOnly = true;

  final List<String> _transportTypes = ['All', 'LRT', 'MRT', 'Rapid Bus', 'KTM'];

  final List<Map<String, dynamic>> _allStations = [
    {
      'name': 'KL Sentral Hub',
      'type': 'LRT',
      'lines': 'LRT Kelana Jaya, MRT Kajang, KTMB',
      'isStepFree': true,
      'distance': '250 m',
    },
    {
      'name': 'Pasar Seni',
      'type': 'MRT',
      'lines': 'MRT Kajang Line, LRT Kelana Jaya',
      'isStepFree': true,
      'distance': '850 m',
    },
    {
      'name': 'Bank Negara',
      'type': 'KTM',
      'lines': 'KTM Komuter Central',
      'isStepFree': false,
      'distance': '1.2 km',
    },
    {
      'name': 'Hab Medan Pasar',
      'type': 'Rapid Bus',
      'lines': 'Rapid Bus Route 600, 602',
      'isStepFree': true,
      'distance': '400 m',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredStations = _allStations.where((station) {
      final matchesTransport =
          _selectedTransport == 'All' || station['type'] == _selectedTransport;
      final matchesStepFree = !_stepFreeOnly || station['isStepFree'] == true;
      return matchesTransport && matchesStepFree;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentra1'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: appYellow),
            tooltip: 'Open Live Google Map',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StationMapScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.grey[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 80, color: Colors.black38),
                  const SizedBox(height: 8),
                  Text(
                    'Map Filtered by: $_selectedTransport',
                    style: GoogleFonts.dmSans(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: appYellow,
                    ),
                    icon: const Icon(Icons.near_me),
                    label: const Text('Launch Interactive GPS Map'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StationMapScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    style: GoogleFonts.dmSans(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search station or route...',
                      hintStyle: GoogleFonts.dmSans(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: appYellow),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _transportTypes.map((type) {
                      final isSelected = _selectedTransport == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
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
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
                FilterChip(
                  selected: _stepFreeOnly,
                  label: Text(
                    'Step-Free Stations Only',
                    style: GoogleFonts.dmSans(
                      color: _stepFreeOnly ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  avatar: Icon(
                    Icons.accessible,
                    size: 18,
                    color: _stepFreeOnly ? Colors.black : appYellow,
                  ),
                  selectedColor: appYellow,
                  backgroundColor: Colors.black,
                  onSelected: (val) => setState(() => _stepFreeOnly = val),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
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
                      '$_selectedTransport Stations (${filteredStations.length})',
                      style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (filteredStations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text('No matching stations found.', style: GoogleFonts.dmSans()),
                        ),
                      )
                    else
                      ...filteredStations.map((station) => Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: station['isStepFree']
                                  ? appYellow.withOpacity(0.3)
                                  : Colors.grey.shade300,
                              child: Icon(
                                station['isStepFree']
                                    ? Icons.accessible
                                    : Icons.not_accessible,
                                color: Colors.black,
                              ),
                            ),
                            title: Text(
                              station['name'],
                              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${station['type']} • ${station['lines']}',
                              style: GoogleFonts.dmSans(),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: station['isStepFree']
                                    ? appYellow
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                station['distance'],
                                style: GoogleFonts.dmSans(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const Divider(),
                        ],
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