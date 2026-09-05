import 'package:flutter/material.dart';

import 'report_service.dart';

class DelayReportScreen extends StatefulWidget {
  const DelayReportScreen({
    super.key,
  });

  @override
  State<DelayReportScreen> createState() =>
      _DelayReportScreenState();
}

class _DelayReportScreenState
    extends State<DelayReportScreen> {
  final ReportService _reportService =
  ReportService();

  final TextEditingController
  _delayController =
  TextEditingController();

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

  final List<String> lines = [
    'MRT Kajang Line',
    'MRT Putrajaya Line',
    'LRT Kelana Jaya Line',
    'LRT Ampang Line',
    'LRT Sri Petaling Line',
    'KL Monorail',
    'KTM Komuter',
  ];

  String _selectedStation =
      'KL Sentral';

  String _selectedLine =
      'MRT Kajang Line';

  bool _submitting = false;
  bool _loadingReports = true;

  List<Map<String, dynamic>>
  _reports = [];

  @override
  void initState() {
    super.initState();

    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loadingReports = true;
    });

    try {
      final data =
      await _reportService
          .getDelayReports();

      if (!mounted) return;

      setState(() {
        _reports = data;
      });
    } catch (e) {
      _showError(
        'Unable to load delay reports.',
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

    final delayText =
    _delayController.text
        .trim();

    final description =
    _descriptionController.text
        .trim();

    final int? delayMinutes =
    int.tryParse(
      delayText,
    );

    if (delayMinutes == null ||
        delayMinutes <= 0) {
      _showError(
        'Please enter a valid delay time.',
      );
      return;
    }

    if (delayMinutes > 300) {
      _showError(
        'Delay time looks too high.',
      );
      return;
    }

    if (description.isEmpty) {
      _showError(
        'Please describe the delay.',
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _reportService
          .addDelayReport(
        stationName:
        _selectedStation,
        lineName:
        _selectedLine,
        delayMinutes:
        delayMinutes,
        description:
        description,
      );

      _delayController.clear();
      _descriptionController
          .clear();

      _showSuccess(
        'Delay report submitted successfully.',
      );

      await _loadReports();
    } catch (e) {
      _showError(
        'Unable to submit delay report.',
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
            'Are you sure you want to delete this delay report?',
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
          .deleteDelayReport(
        report['id'],
      );

      _showSuccess(
        'Delay report deleted successfully.',
      );

      await _loadReports();
    } catch (e) {
      _showError(
        'Unable to delete delay report.',
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
          'Report Delay',
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
                        if (value ==
                            null) {
                          return;
                        }

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
                      _selectedLine,
                      isExpanded:
                      true,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Transit Line',
                        prefixIcon:
                        Icon(
                          Icons.alt_route,
                        ),
                        border:
                        OutlineInputBorder(),
                      ),
                      items:
                      lines.map(
                            (line) {
                          return DropdownMenuItem<
                              String>(
                            value:
                            line,
                            child:
                            Text(
                              line,
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
                          _selectedLine =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextField(
                      controller:
                      _delayController,
                      keyboardType:
                      TextInputType.number,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Delay Minutes',
                        hintText:
                        'Example: 15',
                        prefixIcon:
                        Icon(
                          Icons.timer,
                        ),
                        suffixText:
                        'min',
                        border:
                        OutlineInputBorder(),
                      ),
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
                        'Example: Train has been stopped for about 15 minutes.',
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
                              : 'Submit Delay Report',
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
              'Recent Delay Reports',
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
                      'No delay reports yet.',
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
                          Icons.timer,
                          color:
                          Colors.white,
                        ),
                      ),
                      title:
                      Text(
                        '${report['station_name']} • ${report['line_name']}',
                      ),
                      subtitle:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            'Delay: ${report['delay_minutes']} minutes',
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
    _delayController.dispose();
    _descriptionController
        .dispose();

    super.dispose();
  }
}