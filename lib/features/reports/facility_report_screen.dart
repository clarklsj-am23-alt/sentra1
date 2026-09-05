import 'package:flutter/material.dart';

import 'report_service.dart';

class FacilityReportScreen extends StatefulWidget {
  final String? initialStation;
  final String? initialFacilityType;

  const FacilityReportScreen({
    super.key,
    this.initialStation,
    this.initialFacilityType,
  });

  @override
  State<FacilityReportScreen> createState() =>
      _FacilityReportScreenState();
}

class _FacilityReportScreenState
    extends State<FacilityReportScreen> {
  final ReportService _reportService =
  ReportService();

  final TextEditingController
  _descriptionController =
  TextEditingController();

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
    'Lift',
    'Ramp',
    'OKU Toilet',
    'Accessible Gate',
    'Tactile Paving',
    'Escalator',
    'Surau',
  ];

  final List<String> issueTypes = [
    'Out of Service',
    'Damaged',
    'Blocked',
    'Dirty',
    'Safety Issue',
    'Other',
  ];

  String? _selectedStation;
  String? _selectedFacilityType;
  String _selectedIssueType =
      'Out of Service';

  bool _submitting = false;
  bool _loadingReports = true;

  List<Map<String, dynamic>>
  _reports = [];

  @override
  void initState() {
    super.initState();

    _selectedStation =
        widget.initialStation ??
            stations.first;

    _selectedFacilityType =
        widget.initialFacilityType ??
            facilityTypes.first;

    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loadingReports = true;
    });

    try {
      final data =
      await _reportService
          .getFacilityReports();

      if (!mounted) return;

      setState(() {
        _reports = data;
      });
    } catch (e) {
      _showError(
        'Unable to load facility reports.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingReports = false;
        });
      }
    }
  }

  Future<void> _submitReport() async {
    if (_submitting) return;

    final description =
    _descriptionController.text
        .trim();

    if (_selectedStation == null ||
        _selectedFacilityType == null) {
      _showError(
        'Please select station and facility.',
      );
      return;
    }

    if (description.isEmpty) {
      _showError(
        'Please describe the facility problem.',
      );
      return;
    }

    if (description.length < 5) {
      _showError(
        'Please provide a clearer description.',
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _reportService
          .addFacilityReport(
        stationName:
        _selectedStation!,
        facilityType:
        _selectedFacilityType!,
        issueType:
        _selectedIssueType,
        description:
        description,
      );

      _descriptionController
          .clear();

      _showSuccess(
        'Facility report submitted successfully.',
      );

      await _loadReports();
    } catch (e) {
      _showError(
        'Unable to submit report. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _deleteReport(
      Map<String, dynamic> report,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
          const Text(
            'Delete Report',
          ),
          content:
          const Text(
            'Are you sure you want to delete this report?',
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
      await _reportService
          .deleteFacilityReport(
        report['id'],
      );

      _showSuccess(
        'Report deleted successfully.',
      );

      await _loadReports();
    } catch (e) {
      _showError(
        'Unable to delete report.',
      );
    }
  }

  void _showSuccess(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
        Colors.green,
        behavior:
        SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                message,
                style:
                const TextStyle(
                  color:
                  Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
        Colors.red,
        behavior:
        SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                message,
                style:
                const TextStyle(
                  color:
                  Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text(
          'Report Facility Problem',
        ),
      ),

      body:
      RefreshIndicator(
        onRefresh:
        _loadReports,

        child:
        ListView(
          padding:
          const EdgeInsets.all(
            16,
          ),
          children: [
            Card(
              child:
              Padding(
                padding:
                const EdgeInsets
                    .all(
                  16,
                ),
                child:
                Column(
                  children: [
                    DropdownButtonFormField<
                        String>(
                      initialValue:
                      _selectedStation,
                      isExpanded:
                      true,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Station',
                        prefixIcon:
                        Icon(
                          Icons.train,
                        ),
                        border:
                        OutlineInputBorder(),
                      ),
                      items:
                      stations.map(
                            (station) {
                          return DropdownMenuItem<
                              String>(
                            value:
                            station,
                            child:
                            Text(
                              station,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged:
                          (value) {
                        setState(() {
                          _selectedStation =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                      _selectedFacilityType,
                      isExpanded:
                      true,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Facility Type',
                        prefixIcon:
                        Icon(
                          Icons.accessible,
                        ),
                        border:
                        OutlineInputBorder(),
                      ),
                      items:
                      facilityTypes.map(
                            (type) {
                          return DropdownMenuItem<
                              String>(
                            value:
                            type,
                            child:
                            Text(
                              type,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged:
                          (value) {
                        setState(() {
                          _selectedFacilityType =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                      _selectedIssueType,
                      isExpanded:
                      true,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Issue Type',
                        prefixIcon:
                        Icon(
                          Icons.warning,
                        ),
                        border:
                        OutlineInputBorder(),
                      ),
                      items:
                      issueTypes.map(
                            (issue) {
                          return DropdownMenuItem<
                              String>(
                            value:
                            issue,
                            child:
                            Text(
                              issue,
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

                        setState(() {
                          _selectedIssueType =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextField(
                      controller:
                      _descriptionController,
                      maxLines: 4,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Description',
                        hintText:
                        'Example: Lift near Exit A is not working.',
                        prefixIcon:
                        Icon(
                          Icons.description,
                        ),
                        border:
                        OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
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
                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical:
                            14,
                          ),
                        ),
                        onPressed:
                        _submitting
                            ? null
                            : _submitReport,
                        icon:
                        _submitting
                            ? const SizedBox(
                          width:
                          20,
                          height:
                          20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                            color:
                            Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.send,
                        ),
                        label:
                        Text(
                          _submitting
                              ? 'Submitting...'
                              : 'Submit Report',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Recent Facility Reports',
              style:
              TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            if (_loadingReports)
              const Center(
                child:
                Padding(
                  padding:
                  EdgeInsets
                      .all(
                    24,
                  ),
                  child:
                  CircularProgressIndicator(),
                ),
              )
            else if (_reports.isEmpty)
              const Card(
                child:
                Padding(
                  padding:
                  EdgeInsets
                      .all(
                    24,
                  ),
                  child:
                  Center(
                    child:
                    Text(
                      'No facility reports yet.',
                    ),
                  ),
                ),
              )
            else
              ..._reports.map(
                    (report) {
                  return Card(
                    margin:
                    const EdgeInsets
                        .only(
                      bottom:
                      10,
                    ),
                    child:
                    ListTile(
                      leading:
                      const CircleAvatar(
                        backgroundColor:
                        Colors.black,
                        child:
                        Icon(
                          Icons
                              .report_problem,
                          color:
                          Colors.white,
                        ),
                      ),
                      title:
                      Text(
                        '${report['station_name']} • ${report['facility_type']}',
                      ),
                      subtitle:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            'Issue: ${report['issue_type']}',
                          ),
                          Text(
                            report['description']
                                ?.toString() ??
                                '',
                          ),
                          Text(
                            'Status: ${report['report_status']}',
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                        ],
                      ),
                      trailing:
                      IconButton(
                        tooltip:
                        'Delete Report',
                        icon:
                        const Icon(
                          Icons.delete,
                        ),
                        onPressed:
                            () {
                          _deleteReport(
                            report,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController
        .dispose();

    super.dispose();
  }
}