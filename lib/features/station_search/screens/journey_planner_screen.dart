import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../screens/station_facilities_screen.dart';
import '../../../screens/station_map_screen.dart';

const Color appYellow = Color(0xFFFCEB00);

class JourneyPlannerScreen extends StatefulWidget {
  const JourneyPlannerScreen({super.key});

  @override
  State<JourneyPlannerScreen> createState() => _JourneyPlannerScreenState();
}

class _JourneyPlannerScreenState extends State<JourneyPlannerScreen> {
  final TextEditingController _originController = TextEditingController(text: 'KL Sentral');
  final TextEditingController _destinationController = TextEditingController(text: 'Bukit Bintang');
  bool _preferStepFree = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Planner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick links to Tham's real implemented modules
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: appYellow,
                    ),
                    icon: const Icon(Icons.accessible, size: 18),
                    label: const Text('Facilities DB'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StationFacilitiesScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: appYellow,
                    ),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Station Map'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StationMapScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Origin / Destination Card
            Card(
              color: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _originController,
                      style: GoogleFonts.dmSans(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'From (Origin)',
                        labelStyle: GoogleFonts.dmSans(color: appYellow),
                        prefixIcon: const Icon(Icons.my_location, color: appYellow),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _destinationController,
                      style: GoogleFonts.dmSans(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'To (Destination)',
                        labelStyle: GoogleFonts.dmSans(color: appYellow),
                        prefixIcon: const Icon(Icons.location_on, color: appYellow),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Require Step-Free Interchange',
                          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                        ),
                        Switch(
                          value: _preferStepFree,
                          activeColor: appYellow,
                          onChanged: (val) => setState(() => _preferStepFree = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Recommended Route Itinerary',
              style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: appYellow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '22 Mins Total',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                        Chip(
                          avatar: const Icon(Icons.accessible, size: 16, color: Colors.black),
                          label: Text(
                            'Step-Free Route',
                            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: appYellow.withOpacity(0.3),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildRouteLeg(
                      stepNumber: '1',
                      action: 'Board MRT Kajang Line',
                      detail: 'KL Sentral station to Pasar Seni',
                      lineColor: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildInterchangeNotice(
                      station: 'Pasar Seni Interchange',
                      instructions: 'Use Platform 1 Elevator to connect to LRT Line.',
                    ),
                    const SizedBox(height: 16),
                    _buildRouteLeg(
                      stepNumber: '2',
                      action: 'Board LRT Kelana Jaya Line',
                      detail: 'Pasar Seni to KLCC',
                      lineColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteLeg({
    required String stepNumber,
    required String action,
    required String detail,
    required Color lineColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: lineColor,
          child: Text(stepNumber, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(action, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(detail, style: GoogleFonts.dmSans(color: Colors.grey[700], fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterchangeNotice({required String station, required String instructions}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: appYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appYellow),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_alt, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(instructions, style: GoogleFonts.dmSans(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}