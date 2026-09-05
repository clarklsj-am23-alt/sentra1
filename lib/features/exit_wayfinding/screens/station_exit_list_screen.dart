import 'package:flutter/material.dart';

import '../data/exit_repository.dart';
import '../data/station_exit_model.dart';
import '../view_models/station_exit_list_view_model.dart';
import 'exit_compass_screen.dart';

const _wayfindingYellow = Color(0xFFFCEB00);

class StationExitListScreen extends StatefulWidget {
  const StationExitListScreen({super.key, required this.requiresStepFree});

  final bool requiresStepFree;

  @override
  State<StationExitListScreen> createState() => _StationExitListScreenState();
}

class _StationExitListScreenState extends State<StationExitListScreen> {
  late final StationExitListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StationExitListViewModel(repository: ExitRepository());
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        if (_viewModel.isLoading && _viewModel.stations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_viewModel.errorMessage != null && _viewModel.stations.isEmpty) {
          return _MessageState(
            message: _viewModel.errorMessage!,
            action: _viewModel.load,
          );
        }

        return RefreshIndicator(
          onRefresh: _viewModel.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
            children: [
              Text(
                'Station exits',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.requiresStepFree
                    ? 'Step-free exits are prioritised.'
                    : 'Choose a station to see where each exit leads.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              ..._viewModel.stations.map(
                (station) => _StationCard(
                  station: station,
                  requiresStepFree: widget.requiresStepFree,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: _wayfindingYellow.withValues(alpha: 0.28),
                elevation: 0,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Station context: data.gov.my. Exit bearings are approximate app metadata; follow station signage.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station, required this.requiresStepFree});

  final Station station;
  final bool requiresStepFree;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExitCompassScreen(
              stationId: station.id,
              stationName: station.name,
              requiresStepFree: requiresStepFree,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.black,
                foregroundColor: _wayfindingYellow,
                child: const Icon(Icons.location_on),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: station.lines
                          .map(
                            (line) => Chip(
                              label: Text(line),
                              labelStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.action});

  final String message;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: action, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
