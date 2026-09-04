import 'package:flutter/material.dart';
import '../../database/station_facilities_database.dart';

class StationFacilitiesScreen extends StatefulWidget {
  const StationFacilitiesScreen({super.key});

  @override
  State<StationFacilitiesScreen> createState() =>
      _StationFacilitiesScreenState();
}

class _StationFacilitiesScreenState extends State<StationFacilitiesScreen> {
  final db = StationFacilitiesDatabase.instance;

  final stationController = TextEditingController();
  final facilityController = TextEditingController();
  final locationController = TextEditingController();
  final statusController = TextEditingController();

  List<Map<String, dynamic>> facilities = [];

  @override
  void initState() {
    super.initState();
    loadFacilities();
  }

  Future<void> loadFacilities() async {
    final data = await db.getFacilities();

    setState(() {
      facilities = data;
    });
  }

  Future<void> addFacility() async {
    if (stationController.text.isEmpty ||
        facilityController.text.isEmpty ||
        locationController.text.isEmpty ||
        statusController.text.isEmpty) {
      return;
    }

    await db.addFacility(
      stationName: stationController.text,
      facilityType: facilityController.text,
      location: locationController.text,
      status: statusController.text,
    );

    stationController.clear();
    facilityController.clear();
    locationController.clear();
    statusController.clear();

    await loadFacilities();
  }

  Future<void> deleteFacility(int id) async {
    await db.deleteFacility(id);
    await loadFacilities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station Facilities'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: stationController,
              decoration: const InputDecoration(
                labelText: 'Station Name',
              ),
            ),
            TextField(
              controller: facilityController,
              decoration: const InputDecoration(
                labelText: 'Facility Type',
              ),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
              ),
            ),
            TextField(
              controller: statusController,
              decoration: const InputDecoration(
                labelText: 'Status',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: addFacility,
              child: const Text('Add Facility'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: facilities.isEmpty
                  ? const Center(
                child: Text('No facilities yet'),
              )
                  : ListView.builder(
                itemCount: facilities.length,
                itemBuilder: (context, index) {
                  final facility = facilities[index];

                  return Card(
                    child: ListTile(
                      title: Text(
                        '${facility['station_name']} - ${facility['facility_type']}',
                      ),
                      subtitle: Text(
                        'Location: ${facility['location']}\n'
                            'Status: ${facility['status']}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          deleteFacility(facility['id']);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    stationController.dispose();
    facilityController.dispose();
    locationController.dispose();
    statusController.dispose();
    super.dispose();
  }
}