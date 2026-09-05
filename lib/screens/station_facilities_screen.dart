import 'package:flutter/material.dart';

import '../database/station_facilities_database.dart';
import 'station_map_screen.dart';

class StationFacilitiesScreen
    extends StatefulWidget {
  final String? initialStation;

  const StationFacilitiesScreen({
    super.key,
    this.initialStation,
  });

  @override
  State<StationFacilitiesScreen>
  createState() =>
      _StationFacilitiesScreenState();
}

class _StationFacilitiesScreenState
    extends State<StationFacilitiesScreen> {
  final db =
      StationFacilitiesDatabase.instance;

  final searchController =
  TextEditingController();

  List<Map<String, dynamic>> facilities =
  [];

  String selectedType = 'All';
  bool stepFreeOnly = false;

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

    if (widget.initialStation != null) {
      searchController.text =
      widget.initialStation!;
    }

    loadFacilities();
  }

  Future<void> loadFacilities() async {
    try {
      final data =
      await db.getFacilities(
        search:
        searchController.text.trim(),
        facilityType: selectedType,
        stepFreeOnly: stepFreeOnly,
      );

      if (!mounted) return;

      setState(() {
        facilities = data;
      });
    } catch (e) {
      showErrorSnackBar(
        'Unable to load facilities.',
      );
    }
  }

  void showSuccessSnackBar(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        behavior:
        SnackBarBehavior.floating,
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
                style:
                const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showErrorSnackBar(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        behavior:
        SnackBarBehavior.floating,
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
                style:
                const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData getFacilityIcon(
      String type,
      ) {
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
  // PUBLIC FACILITY DETAIL
  // =========================================================

  void showFacilityDetails(
      Map<String, dynamic> facility,
      ) {
    final bool stepFree =
        facility['is_step_free'] == 1;

    final String stationName =
    facility['station_name']
        .toString();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(20),
            child:
            SingleChildScrollView(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor:
                    Colors.black,
                    child: Icon(
                      getFacilityIcon(
                        facility[
                        'facility_type']
                            .toString(),
                      ),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    facility['facility_type']
                        .toString(),
                    style:
                    const TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  Text(
                    stationName,
                    style:
                    const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(
                      Icons.location_on,
                    ),
                    title: const Text(
                      'Location',
                    ),
                    subtitle: Text(
                      facility['location']
                          .toString(),
                    ),
                  ),

                  ListTile(
                    leading: Icon(
                      facility['status']
                          .toString()
                          .toLowerCase() ==
                          'available'
                          ? Icons.check_circle
                          : Icons.warning,
                      color: facility['status']
                          .toString()
                          .toLowerCase() ==
                          'available'
                          ? Colors.green
                          : Colors.red,
                    ),
                    title:
                    const Text(
                      'Status',
                    ),
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
                      'Accessibility',
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
                          : 'No additional accessibility information.',
                    ),
                  ),

                  ListTile(
                    leading: Icon(
                      stepFree
                          ? Icons
                          .check_circle
                          : Icons.cancel,
                      color: stepFree
                          ? Colors.green
                          : Colors.red,
                    ),
                    title:
                    const Text(
                      'Step-free Access',
                    ),
                    subtitle: Text(
                      stepFree
                          ? 'Suitable for a step-free journey'
                          : 'Not marked as step-free',
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // =============================
                  // VIEW ON MAP
                  // =============================

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
                        padding:
                        const EdgeInsets
                            .symmetric(
                          vertical: 14,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(
                          bottomSheetContext,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StationMapScreen(
                                  initialStation:
                                  stationName,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.map,
                      ),
                      label:
                      const Text(
                        'View on Map',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // =============================
                  // REPORT PROBLEM
                  // =============================

                  SizedBox(
                    width:
                    double.infinity,
                    child:
                    OutlinedButton.icon(
                      style:
                      OutlinedButton
                          .styleFrom(
                        foregroundColor:
                        Colors.black,
                        side:
                        const BorderSide(
                          color:
                          Colors.black,
                        ),
                        padding:
                        const EdgeInsets
                            .symmetric(
                          vertical: 14,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(
                          bottomSheetContext,
                        );

                        showSuccessSnackBar(
                          'Report function will connect to cloud reports.',
                        );
                      },
                      icon: const Icon(
                        Icons.report_problem,
                      ),
                      label:
                      const Text(
                        'Report Facility Problem',
                      ),
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
  // MANAGEMENT MENU
  // =========================================================

  void showManageFacilities() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.settings,
                  ),
                  title: Text(
                    'Manage Facilities',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  subtitle: Text(
                    'Maintain local station facility data',
                  ),
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(
                    Icons.add_circle,
                  ),
                  title:
                  const Text(
                    'Add Facility',
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );
                    showFacilityForm();
                  },
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'To edit or delete a facility, open Manage mode below.',
                  style:
                  TextStyle(
                    color:
                    Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 10,
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
                        sheetContext,
                      );

                      _showManagementList();
                    },
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label:
                    const Text(
                      'Open Management Mode',
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

  void _showManagementList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
              context,
              setSheetState,
              ) {
            return SafeArea(
              child:
              FractionallySizedBox(
                heightFactor: 0.85,
                child: Column(
                  children: [
                    const Padding(
                      padding:
                      EdgeInsets.all(
                        16,
                      ),
                      child: Text(
                        'Facility Management',
                        style:
                        TextStyle(
                          fontSize: 22,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ),

                    Expanded(
                      child:
                      ListView.builder(
                        itemCount:
                        facilities
                            .length,
                        itemBuilder:
                            (
                            context,
                            index,
                            ) {
                          final facility =
                          facilities[
                          index];

                          return ListTile(
                            leading:
                            Icon(
                              getFacilityIcon(
                                facility[
                                'facility_type']
                                    .toString(),
                              ),
                            ),
                            title:
                            Text(
                              facility[
                              'station_name']
                                  .toString(),
                            ),
                            subtitle:
                            Text(
                              '${facility['facility_type']} • ${facility['location']}',
                            ),
                            trailing:
                            Row(
                              mainAxisSize:
                              MainAxisSize
                                  .min,
                              children: [
                                IconButton(
                                  icon:
                                  const Icon(
                                    Icons.edit,
                                  ),
                                  onPressed:
                                      () {
                                    Navigator
                                        .pop(
                                      sheetContext,
                                    );

                                    showFacilityForm(
                                      facility:
                                      facility,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon:
                                  const Icon(
                                    Icons.delete,
                                  ),
                                  onPressed:
                                      () async {
                                    Navigator
                                        .pop(
                                      sheetContext,
                                    );

                                    await confirmDelete(
                                      facility,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // ADD / EDIT
  // =========================================================

  Future<void> showFacilityForm({
    Map<String, dynamic>? facility,
  }) async {
    final stationOptions =
    List<String>.from(stations);

    final facilityOptions =
    facilityTypes
        .where(
          (type) =>
      type != 'All',
    )
        .toList();

    String selectedStation =
        facility?['station_name']
            ?.toString() ??
            stationOptions.first;

    String selectedFacilityType =
        facility?['facility_type']
            ?.toString() ??
            facilityOptions.first;

    String selectedStatus =
        facility?['status']
            ?.toString() ??
            'Available';

    final locationController =
    TextEditingController(
      text:
      facility?['location']
          ?.toString() ??
          '',
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
              ),

              content:
              SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<
                        String>(
                      initialValue:
                      selectedStation,
                      isExpanded: true,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Station',
                        border:
                        OutlineInputBorder(),
                      ),
                      items:
                      stationOptions
                          .map(
                            (station) {
                          return DropdownMenuItem<
                              String>(
                            value: station,
                            child:
                            Text(
                              station,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setDialogState(
                              () {
                            selectedStation =
                                value;
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                      selectedFacilityType,
                      isExpanded: true,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Facility Type',
                        border:
                        OutlineInputBorder(),
                      ),
                      items:
                      facilityOptions
                          .map(
                            (type) {
                          return DropdownMenuItem<
                              String>(
                            value: type,
                            child:
                            Text(
                              type,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setDialogState(
                              () {
                            selectedFacilityType =
                                value;
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                      locationController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Location',
                        hintText:
                        'Exit A / Platform 2',
                        border:
                        OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                      selectedStatus,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Status',
                        border:
                        OutlineInputBorder(),
                      ),
                      items:
                      statuses.map(
                            (status) {
                          return DropdownMenuItem<
                              String>(
                            value:
                            status,
                            child:
                            Text(
                              status,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setDialogState(
                              () {
                            selectedStatus =
                                value;
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                      noteController,
                      maxLines: 2,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Accessibility Note',
                        border:
                        OutlineInputBorder(),
                      ),
                    ),

                    SwitchListTile(
                      contentPadding:
                      EdgeInsets.zero,
                      title:
                      const Text(
                        'Step-free Access',
                      ),
                      value:
                      isStepFree,
                      onChanged:
                          (value) {
                        setDialogState(
                              () {
                            isStepFree =
                                value;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                  const Text(
                    'Cancel',
                    style:
                    TextStyle(
                      color:
                      Colors.black,
                    ),
                  ),
                ),

                ElevatedButton(
                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    Colors.black,
                    foregroundColor:
                    Colors.white,
                  ),
                  onPressed:
                      () async {
                    final location =
                    locationController
                        .text
                        .trim();

                    if (location
                        .isEmpty) {
                      showErrorSnackBar(
                        'Please enter facility location.',
                      );
                      return;
                    }

                    try {
                      if (facility ==
                          null) {
                        await db
                            .addFacility(
                          stationName:
                          selectedStation,
                          facilityType:
                          selectedFacilityType,
                          location:
                          location,
                          status:
                          selectedStatus,
                          accessibilityNote:
                          noteController
                              .text
                              .trim(),
                          isStepFree:
                          isStepFree,
                        );
                      } else {
                        await db
                            .updateFacility(
                          id:
                          facility[
                          'id'],
                          stationName:
                          selectedStation,
                          facilityType:
                          selectedFacilityType,
                          location:
                          location,
                          status:
                          selectedStatus,
                          accessibilityNote:
                          noteController
                              .text
                              .trim(),
                          isStepFree:
                          isStepFree,
                        );
                      }

                      if (dialogContext
                          .mounted) {
                        Navigator.pop(
                          dialogContext,
                        );
                      }

                      await loadFacilities();

                      showSuccessSnackBar(
                        facility == null
                            ? 'Facility added successfully.'
                            : 'Facility updated successfully.',
                      );
                    } catch (e) {
                      showErrorSnackBar(
                        'Unable to save facility.',
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

  Future<void> confirmDelete(
      Map<String, dynamic> facility,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          dialogContext,
          ) {
        return AlertDialog(
          title: const Text(
            'Delete Facility',
          ),
          content: Text(
            'Delete ${facility['facility_type']} at '
                '${facility['station_name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              const Text(
                'Cancel',
                style:
                TextStyle(
                  color:
                  Colors.black,
                ),
              ),
            ),
            ElevatedButton(
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
                  dialogContext,
                  true,
                );
              },
              child:
              const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await db.deleteFacility(
        facility['id'],
      );

      await loadFacilities();

      showSuccessSnackBar(
        'Facility deleted successfully.',
      );
    } catch (e) {
      showErrorSnackBar(
        'Unable to delete facility.',
      );
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text(
          'Station Accessibility',
        ),

        actions: [
          IconButton(
            tooltip:
            'Manage Facilities',
            icon:
            const Icon(
              Icons.settings,
            ),
            onPressed:
            showManageFacilities,
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets
                .fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              controller:
              searchController,
              onChanged: (_) {
                setState(() {});
                loadFacilities();
              },
              decoration:
              InputDecoration(
                hintText:
                'Search station or facility...',
                prefixIcon:
                const Icon(
                  Icons.search,
                ),
                suffixIcon:
                searchController
                    .text
                    .isNotEmpty
                    ? IconButton(
                  onPressed:
                      () {
                    searchController
                        .clear();
                    setState(
                          () {},
                    );
                    loadFacilities();
                  },
                  icon:
                  const Icon(
                    Icons.clear,
                  ),
                )
                    : null,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    14,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 50,
            child:
            ListView.separated(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 16,
              ),
              scrollDirection:
              Axis.horizontal,
              itemCount:
              facilityTypes.length,
              separatorBuilder:
                  (
                  context,
                  index,
                  ) =>
              const SizedBox(
                width: 8,
              ),
              itemBuilder:
                  (
                  context,
                  index,
                  ) {
                final type =
                facilityTypes[
                index];

                final selected =
                    selectedType ==
                        type;

                return ChoiceChip(
                  label: Text(
                    type,
                    style:
                    TextStyle(
                      color:
                      selected
                          ? Colors
                          .white
                          : Colors
                          .black,
                    ),
                  ),
                  selected:
                  selected,
                  selectedColor:
                  Colors.black,
                  backgroundColor:
                  Colors.white,
                  checkmarkColor:
                  Colors.white,
                  side:
                  const BorderSide(
                    color:
                    Colors.black,
                  ),
                  onSelected: (_) {
                    setState(() {
                      selectedType =
                          type;
                    });

                    loadFacilities();
                  },
                );
              },
            ),
          ),

          SwitchListTile(
            secondary:
            const Icon(
              Icons.accessible,
            ),
            title:
            const Text(
              'Step-free access only',
              style:
              TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
            subtitle:
            const Text(
              'Show facilities suitable for accessible journeys',
            ),
            value:
            stepFreeOnly,
            onChanged:
                (value) {
              setState(() {
                stepFreeOnly =
                    value;
              });

              loadFacilities();
            },
          ),

          const Divider(
            height: 1,
          ),

          Expanded(
            child:
            facilities.isEmpty
                ? const Center(
              child:
              Column(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  Icon(
                    Icons
                        .accessible_forward,
                    size:
                    60,
                    color:
                    Colors.grey,
                  ),
                  SizedBox(
                    height:
                    12,
                  ),
                  Text(
                    'No matching facilities found',
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets
                  .all(
                12,
              ),
              itemCount:
              facilities
                  .length,
              itemBuilder:
                  (
                  context,
                  index,
                  ) {
                final facility =
                facilities[
                index];

                final bool
                stepFree =
                    facility[
                    'is_step_free'] ==
                        1;

                final String
                status =
                facility[
                'status']
                    .toString();

                final bool
                available =
                    status
                        .toLowerCase() ==
                        'available';

                return Card(
                  margin:
                  const EdgeInsets
                      .only(
                    bottom:
                    10,
                  ),
                  child:
                  InkWell(
                    onTap: () {
                      showFacilityDetails(
                        facility,
                      );
                    },
                    child:
                    Padding(
                      padding:
                      const EdgeInsets
                          .all(
                        14,
                      ),
                      child:
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                            Colors
                                .black,
                            child:
                            Icon(
                              getFacilityIcon(
                                facility['facility_type']
                                    .toString(),
                              ),
                              color:
                              Colors.white,
                            ),
                          ),

                          const SizedBox(
                            width:
                            12,
                          ),

                          Expanded(
                            child:
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  facility['station_name']
                                      .toString(),
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    17,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),

                                Text(
                                  facility['facility_type']
                                      .toString(),
                                ),

                                Text(
                                  facility['location']
                                      .toString(),
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.grey,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                  8,
                                ),

                                Wrap(
                                  spacing:
                                  8,
                                  children: [
                                    Chip(
                                      avatar:
                                      Icon(
                                        available
                                            ? Icons.check_circle
                                            : Icons.warning,
                                        color:
                                        available ? Colors.green : Colors.red,
                                        size:
                                        18,
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
                                          size:
                                          18,
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

                          const Icon(
                            Icons
                                .chevron_right,
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