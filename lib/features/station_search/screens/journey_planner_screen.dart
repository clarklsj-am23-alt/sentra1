import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../screens/station_facilities_screen.dart';
import '../../../screens/station_map_screen.dart';

const Color appYellow = Color(0xFFFCEB00);

class JourneyPlannerScreen extends StatefulWidget {
  const JourneyPlannerScreen({super.key});

  @override
  State<JourneyPlannerScreen> createState() =>
      _JourneyPlannerScreenState();
}

class _JourneyPlannerScreenState
    extends State<JourneyPlannerScreen> {
  final List<String> stations = [
    'KL Sentral',
    'Pasar Seni',
    'Bukit Bintang',
    'Muzium Negara',
    'Masjid Jamek',
    'Titiwangsa',
    'Maluri',
  ];

  String _origin = 'KL Sentral';
  String _destination = 'Bukit Bintang';

  bool _preferStepFree = true;
  bool _routeGenerated = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _findRoute() {
    if (_origin == _destination) {
      _showError(
        'Origin and destination cannot be the same.',
      );
      return;
    }

    setState(() {
      _routeGenerated = true;
    });
  }

  int _estimatedMinutes() {
    final fromIndex = stations.indexOf(_origin);
    final toIndex = stations.indexOf(_destination);

    final distance =
    (fromIndex - toIndex).abs();

    return 6 + (distance * 4);
  }

  List<String> _buildSimpleRoute() {
    final fromIndex = stations.indexOf(_origin);
    final toIndex = stations.indexOf(_destination);

    if (fromIndex == -1 || toIndex == -1) {
      return [];
    }

    if (fromIndex < toIndex) {
      return stations.sublist(
        fromIndex,
        toIndex + 1,
      );
    } else {
      return stations
          .sublist(
        toIndex,
        fromIndex + 1,
      )
          .reversed
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _buildSimpleRoute();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Planner'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // =================================================
            // QUICK LINKS
            // =================================================

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.black,
                      foregroundColor:
                      appYellow,
                    ),
                    icon: const Icon(
                      Icons.accessible,
                      size: 18,
                    ),
                    label: const Text(
                      'Station Accessibility',
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const StationFacilitiesScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton.icon(
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.black,
                      foregroundColor:
                      appYellow,
                    ),
                    icon: const Icon(
                      Icons.map,
                      size: 18,
                    ),
                    label: const Text(
                      'Station Map',
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const StationMapScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // =================================================
            // ORIGIN / DESTINATION CARD
            // =================================================

            Card(
              color: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<
                        String>(
                      initialValue: _origin,
                      dropdownColor:
                      Colors.black,
                      style:
                      GoogleFonts.dmSans(
                        color:
                        Colors.white,
                      ),
                      decoration:
                      InputDecoration(
                        labelText:
                        'From (Origin)',
                        labelStyle:
                        GoogleFonts.dmSans(
                          color:
                          appYellow,
                        ),
                        prefixIcon:
                        const Icon(
                          Icons.my_location,
                          color:
                          appYellow,
                        ),
                        enabledBorder:
                        const OutlineInputBorder(
                          borderSide:
                          BorderSide(
                            color:
                            Colors.white54,
                          ),
                        ),
                        focusedBorder:
                        const OutlineInputBorder(
                          borderSide:
                          BorderSide(
                            color:
                            appYellow,
                            width: 2,
                          ),
                        ),
                      ),
                      items: stations.map(
                            (station) {
                          return DropdownMenuItem<
                              String>(
                            value: station,
                            child: Text(
                              station,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _origin = value;
                          _routeGenerated =
                          false;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                      _destination,
                      dropdownColor:
                      Colors.black,
                      style:
                      GoogleFonts.dmSans(
                        color:
                        Colors.white,
                      ),
                      decoration:
                      InputDecoration(
                        labelText:
                        'To (Destination)',
                        labelStyle:
                        GoogleFonts.dmSans(
                          color:
                          appYellow,
                        ),
                        prefixIcon:
                        const Icon(
                          Icons.location_on,
                          color:
                          appYellow,
                        ),
                        enabledBorder:
                        const OutlineInputBorder(
                          borderSide:
                          BorderSide(
                            color:
                            Colors.white54,
                          ),
                        ),
                        focusedBorder:
                        const OutlineInputBorder(
                          borderSide:
                          BorderSide(
                            color:
                            appYellow,
                            width: 2,
                          ),
                        ),
                      ),
                      items: stations.map(
                            (station) {
                          return DropdownMenuItem<
                              String>(
                            value: station,
                            child: Text(
                              station,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _destination =
                              value;
                          _routeGenerated =
                          false;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Require Step-Free Journey',
                            style:
                            GoogleFonts.dmSans(
                              color:
                              Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Switch(
                          value:
                          _preferStepFree,
                          activeThumbColor:
                          appYellow,
                          onChanged:
                              (value) {
                            setState(() {
                              _preferStepFree =
                                  value;
                              _routeGenerated =
                              false;
                            });
                          },
                        ),
                      ],
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
                          appYellow,
                          foregroundColor:
                          Colors.black,
                        ),
                        onPressed:
                        _findRoute,
                        icon:
                        const Icon(
                          Icons.alt_route,
                        ),
                        label:
                        const Text(
                          'Find Route',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // ROUTE RESULT
            // =================================================

            Text(
              'Recommended Journey',
              style:
              GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (!_routeGenerated)
              Card(
                child: Padding(
                  padding:
                  const EdgeInsets
                      .all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.route,
                        size: 32,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Text(
                          'Choose your origin and destination, then tap Find Route.',
                          style:
                          GoogleFonts
                              .dmSans(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                color: Colors.white,
                elevation: 3,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets
                      .all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              appYellow,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                6,
                              ),
                            ),
                            child: Text(
                              '${_estimatedMinutes()} Mins Estimated',
                              style:
                              GoogleFonts
                                  .dmSans(
                                fontWeight:
                                FontWeight
                                    .bold,
                                color:
                                Colors.black,
                              ),
                            ),
                          ),

                          if (_preferStepFree)
                            Chip(
                              avatar:
                              const Icon(
                                Icons.accessible,
                                size: 16,
                              ),
                              label: Text(
                                'Step-Free',
                                style:
                                GoogleFonts
                                    .dmSans(
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const Divider(
                        height: 26,
                      ),

                      _buildRouteStep(
                        number: 1,
                        icon:
                        Icons.trip_origin,
                        title:
                        'Start at $_origin',
                        subtitle:
                        'Begin your journey from $_origin.',
                      ),

                      for (int i = 1;
                      i <
                          route.length -
                              1;
                      i++) ...[
                        const SizedBox(
                          height: 14,
                        ),
                        _buildRouteStep(
                          number: i + 1,
                          icon:
                          Icons.train,
                          title:
                          route[i],
                          subtitle:
                          _preferStepFree
                              ? 'Continue through this station using step-free access where available.'
                              : 'Continue through this station.',
                        ),
                      ],

                      const SizedBox(
                        height: 14,
                      ),

                      _buildRouteStep(
                        number:
                        route.length,
                        icon:
                        Icons.location_on,
                        title:
                        'Arrive at $_destination',
                        subtitle:
                        'You have reached your destination.',
                      ),

                      const Divider(
                        height: 26,
                      ),

                      if (_preferStepFree)
                        Container(
                          padding:
                          const EdgeInsets
                              .all(12),
                          decoration:
                          BoxDecoration(
                            color:
                            appYellow
                                .withOpacity(
                              0.15,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              8,
                            ),
                            border:
                            Border.all(
                              color:
                              appYellow,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.accessible,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Step-free preference enabled. Check station accessibility information for lift, ramp and accessible gate availability.',
                                  style:
                                  GoogleFonts
                                      .dmSans(
                                    fontSize:
                                    12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(
                        height: 12,
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
                            appYellow,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StationMapScreen(
                                      initialStation:
                                      _destination,
                                    ),
                              ),
                            );
                          },
                          icon:
                          const Icon(
                            Icons.map,
                          ),
                          label:
                          const Text(
                            'View Destination on Map',
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

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
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StationFacilitiesScreen(
                                      initialStation:
                                      _destination,
                                    ),
                              ),
                            );
                          },
                          icon:
                          const Icon(
                            Icons.accessible,
                          ),
                          label:
                          const Text(
                            'Check Destination Accessibility',
                          ),
                        ),
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

  Widget _buildRouteStep({
    required int number,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor:
          Colors.black,
          child: Text(
            number.toString(),
            style:
            GoogleFonts.dmSans(
              color:
              Colors.white,
              fontSize: 12,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Icon(
          icon,
          size: 22,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                GoogleFonts.dmSans(
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                subtitle,
                style:
                GoogleFonts.dmSans(
                  color:
                  Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}