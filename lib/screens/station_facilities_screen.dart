import 'package:flutter/material.dart';
import '../database/station_facilities_database.dart';

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

    if (!mounted) return;

    setState(() {
      facilities = data;
    });
  }

  Future<void> addFacility() async {
    if (stationController.text.trim().isEmpty ||
        facilityController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        statusController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }

    await db.addFacility(
      stationName: stationController.text.trim(),
      facilityType: facilityController.text.trim(),
      location: locationController.text.trim(),
      status: statusController.text.trim(),
    );

    stationController.clear();
    facilityController.clear();
    locationController.clear();
    statusController.clear();

    await loadFacilities();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facility added successfully'),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }

  Future<void> deleteFacility(int id) async {
    await db.deleteFacility(id);

    await loadFacilities();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facility deleted successfully'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> editFacility(Map<String, dynamic> facility) async {
    stationController.text = facility['station_name'];
    facilityController.text = facility['facility_type'];
    locationController.text = facility['location'];
    statusController.text = facility['status'];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Facility'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                stationController.clear();
                facilityController.clear();
                locationController.clear();
                statusController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (stationController.text.trim().isEmpty ||
                    facilityController.text.trim().isEmpty ||
                    locationController.text.trim().isEmpty ||
                    statusController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                    ),
                  );
                  return;
                }

                await db.updateFacility(
                  id: facility['id'],
                  stationName: stationController.text.trim(),
                  facilityType: facilityController.text.trim(),
                  location: locationController.text.trim(),
                  status: statusController.text.trim(),
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                stationController.clear();
                facilityController.clear();
                locationController.clear();
                statusController.clear();

                await loadFacilities();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Facility updated successfully'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
                        '${facility['station_name']} - '
                            '${facility['facility_type']}',
                      ),
                      subtitle: Text(
                        'Location: ${facility['location']}\n'
                            'Status: ${facility['status']}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              editFacility(facility);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              deleteFacility(facility['id']);
                            },
                          ),
                        ],
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