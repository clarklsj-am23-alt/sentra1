import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/compass_source.dart';
import '../data/exit_repository.dart';
import '../data/station_exit_model.dart';

double shortestBearingDelta({
  required double targetBearing,
  required double currentHeading,
}) {
  var delta = (targetBearing - currentHeading) % 360;
  if (delta > 180) delta -= 360;
  if (delta <= -180) delta += 360;
  return delta;
}

class ExitCompassViewModel extends ChangeNotifier {
  ExitCompassViewModel({
    required this._repository,
    required this._compassSource,
  }) {
    _headingSubscription = _compassSource.headings.listen((value) {
      currentHeading = value;
      notifyListeners();
    });
  }

  final ExitRepository _repository;
  final CompassSource _compassSource;
  StreamSubscription<double?>? _headingSubscription;

  String stationId = '';
  String stationName = '';
  List<StationExit> exits = const [];
  StationExit? selectedExit;
  double? currentHeading;
  bool isLoading = false;
  bool isShowingAll = false;
  String? errorMessage;

  bool get hasCompassSignal => currentHeading != null;

  double? get deltaDegrees {
    final exit = selectedExit;
    final heading = currentHeading;
    if (exit == null || heading == null) return null;
    return shortestBearingDelta(
      targetBearing: exit.bearingDegrees,
      currentHeading: heading,
    );
  }

  double? get arrowRadians {
    final delta = deltaDegrees;
    return delta == null ? null : delta * math.pi / 180;
  }

  Future<void> load({
    required String stationId,
    required String stationName,
    required bool requiresStepFree,
  }) async {
    this.stationId = stationId;
    this.stationName = stationName;
    isShowingAll = !requiresStepFree;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      exits = await _repository.getExits(
        stationId,
        stepFreeOnly: requiresStepFree,
      );
      selectedExit = exits.isEmpty ? null : exits.first;
    } catch (_) {
      errorMessage = 'Unable to load exits for this station.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> showAllExits() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      exits = await _repository.getExits(stationId);
      isShowingAll = true;
      selectedExit = exits.isEmpty ? null : exits.first;
    } catch (_) {
      errorMessage = 'Unable to show all exits.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectExit(StationExit exit) {
    selectedExit = exit;
    notifyListeners();
  }

  @override
  void dispose() {
    _headingSubscription?.cancel();
    super.dispose();
  }
}
