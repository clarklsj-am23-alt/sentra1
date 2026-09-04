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

  // =========================================================
  // OPTIONS
  // =========================================================

  final List<String> stations = [
    'KL Sentral',
    'Pasar Seni',
    'Bukit Bintang',
    'Muzium Negara',
    'Masjid Jamek',
    'Titiwangsa',
    'Maluri',
  ];

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

  final List<String> statuses = [
    'Available',
    'Maintenance',
    'Out of Service',
  ];

  @override
  void initState() {
    super.initState();
    loadFacilities();
  }

  // =========================================================
  // GREEN SUCCESS SNACKBAR
  // =========================================================

  void showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // RED ERROR SNACKBAR
  // =========================================================

  void showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUTTON STYLE
  // WHITE normally
  // BLACK when hover / press
  // =========================================================

  ButtonStyle getInteractiveButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return Colors.black;
          }

          return Colors.white;
        },
      ),

      foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return Colors.white;
          }

          return Colors.black;
        },
      ),

      overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.grey.shade700;
          }

          return null;
        },
      ),

      side: WidgetStateProperty.resolveWith<BorderSide>(
            (states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return const BorderSide(
              color: Colors.black,
              width: 2,
            );
          }

          return const BorderSide(
            color: Colors.black,
            width: 1,
          );
        },
      ),

      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // =========================================================
  // CANCEL BUTTON STYLE
  // =========================================================

  ButtonStyle getCancelButtonStyle() {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.white;
          }

          return Colors.black;
        },
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.black;
          }

          return Colors.transparent;
        },
      ),
    );
  }

  // =========================================================
  // ICON BUTTON STYLE
  // =========================================================

  ButtonStyle getIconButtonStyle() {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.white;
          }

          return Colors.black;
        },
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.black;
          }

          return Colors.transparent;
        },
      ),
    );
  }

  // =========================================================
  // LOAD / SEARCH / FILTER
  // =========================================================

  Future<void> loadFacilities() async {
    try {
      final data = await db.getFacilities(
        search: searchController.text.trim(),
        facilityType: selectedType,
        stepFreeOnly: stepFreeOnly,
      );

      if (!mounted) return;

      setState(() {
        facilities = data;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        facilities = [];
      });

      showErrorSnackBar(
        'Unable to load facilities.',
      );
    }
  }

  // =========================================================
  // FACILITY ICON
  // =========================================================

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
        return Icons.accessibility_new;

      case 'Escalator':
        return Icons.escalator;

      case 'Surau':
        return Icons.mosque;

      default:
        return Icons.place;
    }
  }

  // =========================================================
  // VIEW FACILITY DETAILS
  // =========================================================

  void showFacilityDetails(
      Map<String, dynamic> facility,
      ) {
    final bool stepFree =
        facility['is_step_free'] == 1;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor:
                        Colors.grey.shade200,
                        child: Icon(
                          getFacilityIcon(
                            facility['facility_type']
                                .toString(),
                          ),
                          color: Colors.black,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              facility['facility_type']
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            Text(
                              facility['station_name']
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Divider(),

                  ListTile(
                    leading:
                    const Icon(Icons.train),
                    title:
                    const Text('Station'),
                    subtitle: Text(
                      facility['station_name']
                          .toString(),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.location_on,
                    ),
                    title:
                    const Text('Location'),
                    subtitle: Text(
                      facility['location']
                          .toString(),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                    ),
                    title:
                    const Text('Status'),
                    subtitle: Text(
                      facility['status']
                          .toString(),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.accessible,
                    ),
                    title: const Text(
                      'Accessibility Note',
                    ),
                    subtitle: Text(
                      facility['accessibility_note']
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                          true
                          ? facility[
                      'accessibility_note']
                          .toString()
                          : 'No additional information',
                    ),
                  ),

                  ListTile(
                    leading: Icon(
                      stepFree
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: stepFree
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: const Text(
                      'Step-free Access',
                    ),
                    subtitle: Text(
                      stepFree ? 'Yes' : 'No',
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style:
                      getInteractiveButtonStyle(),
                      onPressed: () {
                        Navigator.pop(
                          bottomSheetContext,
                        );

                        showFacilityForm(
                          facility: facility,
                        );
                      },
                      icon:
                      const Icon(Icons.edit),
                      label:
                      const Text('Edit Facility'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // ADD / EDIT FACILITY
  // =========================================================

  Future<void> showFacilityForm({
    Map<String, dynamic>? facility,
  }) async {
    final List<String> stationOptions =
    List<String>.from(stations);

    final List<String> facilityOptions =
    facilityTypes
        .where(
          (type) => type != 'All',
    )
        .toList();

    final List<String> statusOptions =
    List<String>.from(statuses);

    // Allow old/custom records to still be edited
    if (facility != null) {
      final oldStation =
      facility['station_name'].toString();

      final oldFacility =
      facility['facility_type'].toString();

      final oldStatus =
      facility['status'].toString();

      if (!stationOptions.contains(oldStation)) {
        stationOptions.add(oldStation);
      }

      if (!facilityOptions.contains(oldFacility)) {
        facilityOptions.add(oldFacility);
      }

      if (!statusOptions.contains(oldStatus)) {
        statusOptions.add(oldStatus);
      }
    }

    String selectedStation =
        facility?['station_name']?.toString() ??
            stationOptions.first;

    String selectedFacilityType =
        facility?['facility_type']?.toString() ??
            facilityOptions.first;

    String selectedStatus =
        facility?['status']?.toString() ??
            'Available';

    final locationController =
    TextEditingController(
      text:
      facility?['location']?.toString() ?? '',
    );

    final noteController =
    TextEditingController(
      text:
      facility?['accessibility_note']
          ?.toString() ??
          '',
    );

    bool isStepFree =
        facility?['is_step_free'] == 1;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              title: Text(
                facility == null
                    ? 'Add Facility'
                    : 'Edit Facility',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      // =========================
                      // STATION
                      // =========================

                      DropdownButtonFormField<String>(
                        initialValue:
                        selectedStation,
                        isExpanded: true,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Station Name',
                          prefixIcon:
                          Icon(Icons.train),
                          border:
                          OutlineInputBorder(),
                        ),
                        items: stationOptions
                            .map(
                              (station) =>
                              DropdownMenuItem<
                                  String>(
                                value: station,
                                child:
                                Text(station),
                              ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedStation =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      // =========================
                      // FACILITY TYPE
                      // =========================

                      DropdownButtonFormField<String>(
                        initialValue:
                        selectedFacilityType,
                        isExpanded: true,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Facility Type',
                          prefixIcon: Icon(
                            Icons.accessible,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                        items: facilityOptions
                            .map(
                              (type) =>
                              DropdownMenuItem<
                                  String>(
                                value: type,
                                child: Text(type),
                              ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedFacilityType =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      // =========================
                      // LOCATION
                      // =========================

                      TextField(
                        controller:
                        locationController,
                        decoration:
                        const InputDecoration(
                          labelText: 'Location',
                          hintText:
                          'Example: Exit A / Platform 2',
                          prefixIcon: Icon(
                            Icons.location_on,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================
                      // STATUS
                      // =========================

                      DropdownButtonFormField<String>(
                        initialValue:
                        selectedStatus,
                        isExpanded: true,
                        decoration:
                        const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(
                            Icons.info_outline,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                        items: statusOptions
                            .map(
                              (status) =>
                              DropdownMenuItem<
                                  String>(
                                value: status,
                                child:
                                Text(status),
                              ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedStatus =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      // =========================
                      // NOTE
                      // =========================

                      TextField(
                        controller:
                        noteController,
                        maxLines: 2,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Accessibility Note',
                          hintText:
                          'Example: Suitable for wheelchair users',
                          prefixIcon:
                          Icon(Icons.notes),
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // =========================
                      // STEP FREE
                      // =========================

                      SwitchListTile(
                        contentPadding:
                        EdgeInsets.zero,
                        secondary: const Icon(
                          Icons.accessible,
                        ),
                        title: const Text(
                          'Step-free Access',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Suitable for wheelchair users',
                        ),
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
              ),

              actions: [
                TextButton(
                  style: getCancelButtonStyle(),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                  const Text('Cancel'),
                ),

                ElevatedButton(
                  style:
                  getInteractiveButtonStyle(),

                  onPressed: () async {
                    final String location =
                    locationController.text
                        .trim();

                    // =========================
                    // VALIDATION
                    // =========================

                    if (location.isEmpty) {
                      showErrorSnackBar(
                        'Please enter the facility location.',
                      );
                      return;
                    }

                    if (location.length < 2) {
                      showErrorSnackBar(
                        'Please enter a valid location.',
                      );
                      return;
                    }

                    try {
                      // =========================
                      // CREATE
                      // =========================

                      if (facility == null) {
                        await db.addFacility(
                          stationName:
                          selectedStation,
                          facilityType:
                          selectedFacilityType,
                          location: location,
                          status:
                          selectedStatus,
                          accessibilityNote:
                          noteController.text
                              .trim(),
                          isStepFree:
                          isStepFree,
                        );
                      }

                      // =========================
                      // UPDATE
                      // =========================

                      else {
                        await db.updateFacility(
                          id: facility['id'],
                          stationName:
                          selectedStation,
                          facilityType:
                          selectedFacilityType,
                          location: location,
                          status:
                          selectedStatus,
                          accessibilityNote:
                          noteController.text
                              .trim(),
                          isStepFree:
                          isStepFree,
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(
                          dialogContext,
                        );
                      }

                      await loadFacilities();

                      if (!mounted) return;

                      // =========================
                      // GREEN SUCCESS
                      // =========================

                      if (facility == null) {
                        showSuccessSnackBar(
                          'Facility added successfully.',
                        );
                      } else {
                        showSuccessSnackBar(
                          'Facility updated successfully.',
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;

                      showErrorSnackBar(
                        'Unable to save facility. Please try again.',
                      );
                    }
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

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> confirmDelete(
      Map<String, dynamic> facility,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
          const Text('Delete Facility'),

          content: Text(
            'Are you sure you want to delete '
                '${facility['facility_type']} at '
                '${facility['station_name']}?',
          ),

          actions: [
            TextButton(
              style: getCancelButtonStyle(),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),

            ElevatedButton(
              style:
              getInteractiveButtonStyle(),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
              const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await db.deleteFacility(
        facility['id'],
      );

      await loadFacilities();

      if (!mounted) return;

      showSuccessSnackBar(
        'Facility deleted successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      showErrorSnackBar(
        'Unable to delete facility.',
      );
    }
  }

  // =========================================================
  // MAIN UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Station Facilities'),
      ),

      // =====================================================
      // ADD BUTTON
      // =====================================================

      floatingActionButton:
      FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          showFacilityForm();
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Facility',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Column(
        children: [
          // =================================================
          // SEARCH
          // =================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              controller: searchController,
              onChanged: (_) {
                setState(() {});

                loadFacilities();
              },
              decoration: InputDecoration(
                hintText:
                'Search station or facility...',
                prefixIcon:
                const Icon(Icons.search),

                suffixIcon:
                searchController
                    .text
                    .isNotEmpty
                    ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                  ),
                  onPressed: () {
                    searchController
                        .clear();

                    setState(() {});

                    loadFacilities();
                  },
                )
                    : null,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),

          // =================================================
          // FILTER CHIPS
          // =================================================

          SizedBox(
            height: 50,
            child: ListView.separated(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              scrollDirection:
              Axis.horizontal,
              itemCount:
              facilityTypes.length,
              separatorBuilder:
                  (context, index) =>
              const SizedBox(
                width: 8,
              ),
              itemBuilder:
                  (context, index) {
                final type =
                facilityTypes[index];

                final bool isSelected =
                    selectedType == type;

                return ChoiceChip(
                  label: Text(
                    type,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.black,
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),

                  selected: isSelected,

                  selectedColor:
                  Colors.black,

                  backgroundColor:
                  Colors.white,

                  side: const BorderSide(
                    color: Colors.black,
                  ),

                  checkmarkColor:
                  Colors.white,

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

          // =================================================
          // STEP FREE FILTER
          // =================================================

          SwitchListTile(
            secondary:
            const Icon(Icons.accessible),
            title: const Text(
              'Step-free access only',
              style: TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Show facilities suitable for a step-free journey',
            ),
            value: stepFreeOnly,
            onChanged: (value) {
              setState(() {
                stepFreeOnly = value;
              });

              loadFacilities();
            },
          ),

          const Divider(height: 1),

          // =================================================
          // LIST
          // =================================================

          Expanded(
            child: facilities.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color:
                    Colors.grey,
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
              const EdgeInsets.all(
                12,
              ),
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

                final String status =
                facility['status']
                    .toString();

                final bool available =
                    status
                        .toLowerCase() ==
                        'available';

                return Card(
                  elevation: 2,
                  margin:
                  const EdgeInsets
                      .only(
                    bottom: 10,
                  ),
                  child: InkWell(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                    onTap: () {
                      showFacilityDetails(
                        facility,
                      );
                    },
                    child: Padding(
                      padding:
                      const EdgeInsets
                          .all(
                        12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                            Colors.grey
                                .shade200,
                            child: Icon(
                              getFacilityIcon(
                                facility[
                                'facility_type']
                                    .toString(),
                              ),
                              color:
                              Colors.black,
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
                                  'station_name']
                                      .toString(),
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    17,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  facility[
                                  'facility_type']
                                      .toString(),
                                ),

                                Text(
                                  'Location: '
                                      '${facility['location']}',
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Wrap(
                                  spacing: 8,
                                  runSpacing:
                                  4,
                                  children: [
                                    Chip(
                                      avatar:
                                      Icon(
                                        available
                                            ? Icons.check_circle
                                            : Icons.warning,
                                        size:
                                        18,
                                        color: available
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      label:
                                      Text(
                                        status,
                                      ),
                                    ),

                                    if (stepFree)
                                      const Chip(
                                        avatar:
                                        Icon(
                                          Icons.accessible,
                                          size: 18,
                                        ),
                                        label:
                                        Text(
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
                                style:
                                getIconButtonStyle(),
                                icon:
                                const Icon(
                                  Icons.edit,
                                ),
                                onPressed:
                                    () {
                                  showFacilityForm(
                                    facility:
                                    facility,
                                  );
                                },
                              ),

                              IconButton(
                                tooltip:
                                'Delete',
                                style:
                                getIconButtonStyle(),
                                icon:
                                const Icon(
                                  Icons.delete,
                                ),
                                onPressed:
                                    () {
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