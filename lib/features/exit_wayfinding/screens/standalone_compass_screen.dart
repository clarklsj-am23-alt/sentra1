import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/compass_source.dart';

const _standaloneCompassYellow = Color(0xFFFCEB00);

class StandaloneCompassScreen extends StatefulWidget {
  const StandaloneCompassScreen({super.key, this.compassSource});

  final CompassSource? compassSource;

  @override
  State<StandaloneCompassScreen> createState() =>
      _StandaloneCompassScreenState();
}

class _StandaloneCompassScreenState extends State<StandaloneCompassScreen> {
  late final CompassSource _compassSource;
  StreamSubscription<double?>? _headingSubscription;
  double? _heading;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _compassSource = widget.compassSource ?? FlutterCompassSource();
    _headingSubscription = _compassSource.headings.listen((value) {
      if (!mounted) return;
      setState(() => _heading = value);
    });
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (!mounted) return;
    setState(() => _permissionDenied = !status.isGranted);
  }

  @override
  void dispose() {
    _headingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
      children: [
        Text(
          'Digital compass',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'A simple heading tool for finding your way around a station.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),
        if (_permissionDenied) const _CompassPermissionNotice(),
        Center(child: _CompassDial(heading: heading)),
        const SizedBox(height: 20),
        Card(
          color: Colors.black,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Semantics(
                  liveRegion: true,
                  label: heading == null
                      ? 'Waiting for compass signal'
                      : 'Current heading ${heading.round()} degrees',
                  child: Text(
                    heading == null ? '—' : '${heading.round()}°',
                    style: const TextStyle(
                      color: _standaloneCompassYellow,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  heading == null
                      ? 'Waiting for compass signal'
                      : _cardinalDirection(heading),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Keep the phone level and move it slowly if the direction is unstable. Follow station signs for final wayfinding.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class _CompassDial extends StatelessWidget {
  const _CompassDial({required this.heading});

  final double? heading;

  @override
  Widget build(BuildContext context) {
    final rotation = heading == null ? 0.0 : -heading! * math.pi / 180;
    return Semantics(
      label: heading == null
          ? 'Compass direction unavailable'
          : 'Compass facing ${_cardinalDirection(heading!)}',
      child: SizedBox.square(
        dimension: 270,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 8),
                boxShadow: const [
                  BoxShadow(blurRadius: 8, color: Colors.black26),
                ],
              ),
            ),
            Transform.rotate(
              angle: rotation,
              child: const Stack(
                children: [
                  Positioned(
                    top: 18,
                    left: 0,
                    right: 0,
                    child: _DirectionLabel('N', Colors.red),
                  ),
                  Positioned(
                    bottom: 18,
                    left: 0,
                    right: 0,
                    child: _DirectionLabel('S', Colors.black),
                  ),
                  Positioned(
                    left: 20,
                    top: 0,
                    bottom: 0,
                    child: _DirectionLabel('W', Colors.black),
                  ),
                  Positioned(
                    right: 20,
                    top: 0,
                    bottom: 0,
                    child: _DirectionLabel('E', Colors.black),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_upward,
              size: 110,
              color: _standaloneCompassYellow,
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionLabel extends StatelessWidget {
  const _DirectionLabel(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompassPermissionNotice extends StatelessWidget {
  const _CompassPermissionNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _standaloneCompassYellow.withValues(alpha: 0.28),
      elevation: 0,
      child: const ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('Compass permission was not granted.'),
        subtitle: Text(
          'Enable location access to receive a heading, then follow station signs.',
        ),
      ),
    );
  }
}

String _cardinalDirection(double heading) {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final index = ((heading / 45).round()) % directions.length;
  return directions[index];
}
