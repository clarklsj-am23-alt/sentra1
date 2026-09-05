import 'package:flutter/foundation.dart';

import '../data/exit_repository.dart';
import '../data/station_exit_model.dart';

class StationExitListViewModel extends ChangeNotifier {
  StationExitListViewModel({required this._repository});

  final ExitRepository _repository;
  List<Station> stations = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      stations = await _repository.getStations();
    } catch (_) {
      errorMessage = 'Unable to load station exits.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
