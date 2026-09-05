class Station {
  const Station({
    required this.id,
    required this.name,
    required this.lines,
    required this.sourceName,
    required this.sourceUrl,
    required this.sourceDate,
  });

  final String id;
  final String name;
  final List<String> lines;
  final String sourceName;
  final String sourceUrl;
  final String sourceDate;

  factory Station.fromMap(Map<String, Object?> map) {
    return Station(
      id: map['id']! as String,
      name: map['name']! as String,
      lines: (map['lines']! as String)
          .split('|')
          .where((line) => line.isNotEmpty)
          .toList(growable: false),
      sourceName: map['source_name']! as String,
      sourceUrl: map['source_url']! as String,
      sourceDate: map['source_date']! as String,
    );
  }
}

class StationExit {
  const StationExit({
    required this.id,
    required this.stationId,
    required this.exitCode,
    required this.destination,
    required this.bearingDegrees,
    required this.isStepFree,
    required this.bearingNote,
    required this.verifiedDate,
  });

  final int id;
  final String stationId;
  final String exitCode;
  final String destination;
  final double bearingDegrees;
  final bool isStepFree;
  final String bearingNote;
  final String verifiedDate;

  factory StationExit.fromMap(Map<String, Object?> map) {
    return StationExit(
      id: map['id']! as int,
      stationId: map['station_id']! as String,
      exitCode: map['exit_code']! as String,
      destination: map['destination']! as String,
      bearingDegrees: (map['bearing_degrees']! as num).toDouble(),
      isStepFree: (map['is_step_free']! as int) == 1,
      bearingNote: map['bearing_note']! as String,
      verifiedDate: map['verified_date']! as String,
    );
  }
}
