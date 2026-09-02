import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: DevDashboard()));

class DevDashboard extends StatelessWidget {
  const DevDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sentra1 - Dev Launchpad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () {}, // Navigate to Jia Cheng's GPS screen
            child: const Text('Jia Cheng: Stations Nearby (GPS)'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {}, // Navigate to Clark's GTFS screen
            child: const Text('Clark: Live Arrivals (GTFS API)'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {}, // Navigate to Tham's Places Search screen
            child: const Text('Tham: Destination Search (Places API)'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {}, // Navigate to Cheng Zhe's Compass screen
            child: const Text('Cheng Zhe: Exit Compass (Magnetometer)'),
          ),
        ],
      ),
    );
  }
}