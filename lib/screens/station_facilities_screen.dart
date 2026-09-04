import 'package:flutter/material.dart';
import '../database/station_facilities_database.dart';

class StationFacilitiesScreen extends StatefulWidget {
  const StationFacilitiesScreen({super.key});

  @override
  State<StationFacilitiesScreen> createState() =>
      _StationFacilitiesScreenState();
}

class _StationFacilitiesScreenState
    extends State<StationFacilitiesScreen> {
  final db = StationFacilitiesDatabase.instance;

  final searchController = TextEditingController();

  List<Map<String, dynamic>> facilities = [];

  String selectedType = 'All';
  bool stepFreeOnly = false;

  final List<String> facilityTypes = [
    'All',
    'Lift',
    'Ramp',
    'OKU Toilet',
    'Accessible Gate',
    'Tactile Paving',
    'Escalator',
    'Surau',
  ];

  @override
  void initState() {
    super.initState();
    loadFacilities();
  }

  Future<void> loadFacilities() async {
    final data = await db.getFacilities(
      search: searchController.text,
      facilityType: selectedType,
      stepFreeOnly: stepFreeOnly,
    );

    if (!mounted) return;

    setState(() {
      facilities = data;
    });
  }

  IconData getFacilityIcon(String type) {
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
        return Icons.blind;
      case 'Escalator':
        return Icons.escalator;
      case 'Surau':
        return Icons.mosque;
      default:
        return Icons.place;
    }
  }

  void showFacilityDetails(
      Map<String, dynamic> facility,
      ) {
    final bool stepFree =
        facility['is_step_free'] == 1;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            runSpacing: 14,
            children: [
              Row(
                children: [
                  Icon(
                    getFacilityIcon(
                      facility['facility_type'],
                    ),
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      facility['facility_type'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.train),
                title: const Text('Station'),
                subtitle: Text(
                  facility['station_name'],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location'),
                subtitle: Text(
                  facility['location'],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Status'),
                subtitle: Text(
                  facility['status'],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.accessible),
                title: const Text('Accessibility'),
                subtitle: Text(
                  facility['accessibility_note']
                      ?.toString()
                      .isNotEmpty ==
                      true
                      ? facility['accessibility_note']
                      : 'No additional information',
                ),
              ),

              ListTile(
                leading: Icon(
                  stepFree
                      ? Icons.check_circle
                      : Icons.cancel,
                ),
                title: const Text('Step-free Access'),
                subtitle: Text(
                  stepFree ? 'Yes' : 'No',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> showFacilityForm({
    Map<String, dynamic>? facility,
  }) async {
    final stationController =
    TextEditingController(
      text: facility?['station_name'] ?? '',
    );

    final typeController =
    TextEditingController(
      text: facility?['facility_type'] ?? '',
    );

    final locationController =
    TextEditingController(
      text: facility?['location'] ?? '',
    );

    final statusController =
    TextEditingController(
      text: facility?['status'] ?? 'Available',
    );

    final noteController =
    TextEditingController(
      text: facility?['accessibility_note'] ?? '',
    );

    bool isStepFree =
        facility?['is_step_free'] == 1;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                facility == null
                    ? 'Add Facility'
                    : 'Edit Facility',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: stationController,
                      decoration:
                      const InputDecoration(
                        labelText: 'Station Name',
                      ),
                    ),
                    TextField(
                      controller: typeController,
                      decoration:
                      const InputDecoration(
                        labelText: 'Facility Type',
                      ),
                    ),
                    TextField(
                      controller: locationController,
                      decoration:
                      const InputDecoration(
                        labelText: 'Location',
                      ),
                    ),
                    TextField(
                      controller: statusController,
                      decoration:
                      const InputDecoration(
                        labelText: 'Status',
                      ),
                    ),
                    TextField(
                      controller: noteController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Accessibility Note',
                      ),
                    ),

                    const SizedBox(height: 12),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title:
                      const Text('Step-free Access'),
                      value: isStepFree,
                      onChanged: (value) {
                        setDialogState(() {
                          isStepFree = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (stationController.text
                        .trim()
                        .isEmpty ||
                        typeController.text
                            .trim()
                            .isEmpty ||
                        locationController.text
                            .trim()
                            .isEmpty ||
                        statusController.text
                            .trim()
                            .isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill in all required fields',
                          ),
                        ),
                      );
                      return;
                    }

                    if (facility == null) {
                      await db.addFacility(
                        stationName:
                        stationController.text.trim(),
                        facilityType:
                        typeController.text.trim(),
                        location:
                        locationController.text.trim(),
                        status:
                        statusController.text.trim(),
                        accessibilityNote:
                        noteController.text.trim(),
                        isStepFree: isStepFree,
                      );
                    } else {
                      await db.updateFacility(
                        id: facility['id'],
                        stationName:
                        stationController.text.trim(),
                        facilityType:
                        typeController.text.trim(),
                        location:
                        locationController.text.trim(),
                        status:
                        statusController.text.trim(),
                        accessibilityNote:
                        noteController.text.trim(),
                        isStepFree: isStepFree,
                      );
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    await loadFacilities();

                    if (!mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          facility == null
                              ? 'Facility added successfully'
                              : 'Facility updated successfully',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    facility == null
                        ? 'Add'
                        : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> confirmDelete(
      Map<String, dynamic> facility,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Facility'),
          content: Text(
            'Delete ${facility['facility_type']} '
                'at ${facility['station_name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await db.deleteFacility(
      facility['id'],
    );

    await loadFacilities();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Facility deleted successfully',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Station Facilities'),
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: () {
          showFacilityForm();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),

      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              controller: searchController,
              onChanged: (_) {
                loadFacilities();
              },
              decoration: InputDecoration(
                hintText:
                'Search station or facility...',
                prefixIcon:
                const Icon(Icons.search),
                suffixIcon:
                searchController.text.isNotEmpty
                    ? IconButton(
                  icon:
                  const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    loadFacilities();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 48,
            child: ListView.separated(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: facilityTypes.length,
              separatorBuilder:
                  (context, index) =>
              const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type =
                facilityTypes[index];

                return ChoiceChip(
                  label: Text(type),
                  selected:
                  selectedType == type,
                  onSelected: (_) {
                    setState(() {
                      selectedType = type;
                    });

                    loadFacilities();
                  },
                );
              },
            ),
          ),

          SwitchListTile(
            title: const Text(
              'Step-free access only',
            ),
            subtitle: const Text(
              'Show facilities suitable for a step-free journey',
            ),
            secondary:
            const Icon(Icons.accessible),
            value: stepFreeOnly,
            onChanged: (value) {
              setState(() {
                stepFreeOnly = value;
              });

              loadFacilities();
            },
          ),

          const Divider(height: 1),

          Expanded(
            child: facilities.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No matching facilities found',
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.all(12),
              itemCount:
              facilities.length,
              itemBuilder:
                  (context, index) {
                final facility =
                facilities[index];

                final bool stepFree =
                    facility[
                    'is_step_free'] ==
                        1;

                final bool available =
                    facility['status']
                        .toString()
                        .toLowerCase() ==
                        'available';

                return Card(
                  margin:
                  const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    onTap: () {
                      showFacilityDetails(
                        facility,
                      );
                    },
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Icon(
                              getFacilityIcon(
                                facility[
                                'facility_type'],
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  facility[
                                  'station_name'],
                                  style:
                                  const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 3,
                                ),

                                Text(
                                  facility[
                                  'facility_type'],
                                ),

                                Text(
                                  '📍 ${facility['location']}',
                                ),

                                const SizedBox(
                                  height: 6,
                                ),

                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(
                                      avatar: Icon(
                                        available
                                            ? Icons
                                            .check_circle
                                            : Icons
                                            .warning,
                                        size: 18,
                                      ),
                                      label: Text(
                                        facility[
                                        'status'],
                                      ),
                                    ),

                                    if (stepFree)
                                      const Chip(
                                        avatar: Icon(
                                          Icons
                                              .accessible,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Step-free',
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Column(
                            children: [
                              IconButton(
                                tooltip:
                                'Edit',
                                icon:
                                const Icon(
                                  Icons.edit,
                                ),
                                onPressed: () {
                                  showFacilityForm(
                                    facility:
                                    facility,
                                  );
                                },
                              ),

                              IconButton(
                                tooltip:
                                'Delete',
                                icon:
                                const Icon(
                                  Icons.delete,
                                ),
                                onPressed: () {
                                  confirmDelete(
                                    facility,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}