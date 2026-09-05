import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/compass_source.dart';
import '../data/exit_repository.dart';
import '../data/station_exit_model.dart';
import '../view_models/exit_compass_view_model.dart';

const _compassYellow = Color(0xFFFCEB00);

class ExitCompassScreen extends StatefulWidget {
  const ExitCompassScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.requiresStepFree,
    this.viewModel,
  });

  final String stationId;
  final String stationName;
  final bool requiresStepFree;
  final ExitCompassViewModel? viewModel;

  @override
  State<ExitCompassScreen> createState() => _ExitCompassScreenState();
}

class _ExitCompassScreenState extends State<ExitCompassScreen> {
  late final ExitCompassViewModel _viewModel;
  late final bool _ownsViewModel;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel =
        widget.viewModel ??
        ExitCompassViewModel(
          repository: ExitRepository(),
          compassSource: FlutterCompassSource(),
        );
    _viewModel.load(
      stationId: widget.stationId,
      stationName: widget.stationName,
      requiresStepFree: widget.requiresStepFree,
    );
    _requestCompassPermission();
  }

  Future<void> _requestCompassPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (!mounted) return;
    setState(() => _permissionDenied = !status.isGranted);
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.stationName)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            if (_viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_viewModel.errorMessage != null) {
              return Center(child: Text(_viewModel.errorMessage!));
            }
            if (_viewModel.exits.isEmpty) {
              return _NoStepFreeExits(
                onShowAll: _viewModel.isShowingAll
                    ? null
                    : _viewModel.showAllExits,
              );
            }

            final selectedExit = _viewModel.selectedExit;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: [
                _ExitPicker(viewModel: _viewModel),
                const SizedBox(height: 14),
                if (_permissionDenied) const _PermissionNotice(),
                if (selectedExit != null) ...[
                  _CompassPanel(viewModel: _viewModel),
                  const SizedBox(height: 14),
                  _ExitDetails(exit: selectedExit),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExitPicker extends StatelessWidget {
  const _ExitPicker({required this.viewModel});

  final ExitCompassViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
        child: DropdownButtonFormField<StationExit>(
          initialValue: viewModel.selectedExit,
          decoration: const InputDecoration(
            labelText: 'Station exit',
            prefixIcon: Icon(Icons.signpost_outlined),
            border: InputBorder.none,
          ),
          isExpanded: true,
          items: viewModel.exits
              .map(
                (exit) => DropdownMenuItem(
                  value: exit,
                  child: Text('${exit.exitCode} · ${exit.destination}'),
                ),
              )
              .toList(growable: false),
          onChanged: (exit) {
            if (exit != null) viewModel.selectExit(exit);
          },
        ),
      ),
    );
  }
}

class _CompassPanel extends StatelessWidget {
  const _CompassPanel({required this.viewModel});

  final ExitCompassViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final exit = viewModel.selectedExit!;
    final delta = viewModel.deltaDegrees;
    return Card(
      color: Colors.black,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          children: [
            Text(
              exit.destination,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _compassYellow,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Semantics(
              liveRegion: true,
              label: viewModel.arrowRadians == null
                  ? 'Waiting for compass signal'
                  : 'Arrow points toward ${exit.destination}',
              child: viewModel.arrowRadians == null
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Text(
                        'Waiting for compass signal…',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Transform.rotate(
                      angle: viewModel.arrowRadians!,
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 142,
                        color: _compassYellow,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              viewModel.currentHeading == null
                  ? 'Hold your phone flat and move it slowly.'
                  : 'Heading ${viewModel.currentHeading!.round()}° · Target ${exit.bearingDegrees.round()}°',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            if (delta != null) ...[
              const SizedBox(height: 8),
              Text(
                _turnInstruction(delta),
                style: const TextStyle(
                  color: _compassYellow,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _turnInstruction(double delta) {
    if (delta.abs() < 10) return 'You are facing the exit direction';
    final direction = delta > 0 ? 'right' : 'left';
    return 'Turn ${delta.abs().round()}° $direction';
  }
}

class _ExitDetails extends StatelessWidget {
  const _ExitDetails({required this.exit});

  final StationExit exit;

  @override
  Widget build(BuildContext context) {
    final accent = exit.isStepFree ? Colors.green : Colors.orange;
    return Card(
      child: ListTile(
        leading: Icon(
          exit.isStepFree ? Icons.accessible : Icons.stairs,
          color: accent,
          size: 28,
        ),
        title: Text(
          exit.isStepFree ? 'Step-free access available' : 'Stairs-only exit',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${exit.bearingNote}\nVerified: ${exit.verifiedDate}'),
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _compassYellow.withValues(alpha: 0.28),
      elevation: 0,
      child: const ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('Compass permission was not granted.'),
        subtitle: Text(
          'Follow the displayed target bearing and station signs.',
        ),
      ),
    );
  }
}

class _NoStepFreeExits extends StatelessWidget {
  const _NoStepFreeExits({required this.onShowAll});

  final Future<void> Function()? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.accessible_forward, size: 52),
            const SizedBox(height: 12),
            const Text(
              'No step-free exits are recorded for this station.',
              textAlign: TextAlign.center,
            ),
            if (onShowAll != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onShowAll,
                child: const Text('Show all exits'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
