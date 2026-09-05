import 'exit_database_helper.dart';
import 'station_exit_model.dart';

class ExitRepository {
  ExitRepository({ExitDatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? ExitDatabaseHelper.instance;

  final ExitDatabaseHelper _databaseHelper;

  Future<List<Station>> getStations() async {
    final rows = await _databaseHelper.getStations();
    return rows.map(Station.fromMap).toList(growable: false);
  }

  Future<List<StationExit>> getExits(
    String stationId, {
    bool stepFreeOnly = false,
  }) async {
    final rows = await _databaseHelper.getExitsByStation(stationId);
    final exits = rows.map(StationExit.fromMap);
    if (!stepFreeOnly) return exits.toList(growable: false);
    return exits.where((exit) => exit.isStepFree).toList(growable: false);
  }
}
