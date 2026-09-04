import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =========================================================
  // GET CURRENT USER
  // =========================================================

  String _getCurrentUserId() {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User must be logged in first');
    }

    return user.id;
  }

  // =========================================================
  // FACILITY REPORT
  // =========================================================

  // CREATE facility report
  Future<void> addFacilityReport({
    required String stationName,
    required String facilityType,
    required String issueType,
    required String description,
  }) async {
    final userId = _getCurrentUserId();

    await _supabase.from('facility_reports').insert({
      'user_id': userId,
      'station_name': stationName,
      'facility_type': facilityType,
      'issue_type': issueType,
      'description': description,
      'report_status': 'Pending',
    });
  }

  // READ facility reports
  Future<List<Map<String, dynamic>>> getFacilityReports() async {
    final response = await _supabase
        .from('facility_reports')
        .select()
        .order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // UPDATE facility report
  Future<void> updateFacilityReport({
    required int id,
    required String stationName,
    required String facilityType,
    required String issueType,
    required String description,
  }) async {
    final userId = _getCurrentUserId();

    await _supabase
        .from('facility_reports')
        .update({
      'station_name': stationName,
      'facility_type': facilityType,
      'issue_type': issueType,
      'description': description,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', id)
        .eq('user_id', userId);
  }

  // DELETE facility report
  Future<void> deleteFacilityReport(int id) async {
    final userId = _getCurrentUserId();

    await _supabase
        .from('facility_reports')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  // =========================================================
  // DELAY REPORT
  // =========================================================

  // CREATE delay report
  Future<void> addDelayReport({
    required String stationName,
    required String lineName,
    required int delayMinutes,
    required String description,
  }) async {
    final userId = _getCurrentUserId();

    await _supabase.from('delay_reports').insert({
      'user_id': userId,
      'station_name': stationName,
      'line_name': lineName,
      'delay_minutes': delayMinutes,
      'description': description,
      'report_status': 'Active',
    });
  }

  // READ delay reports
  Future<List<Map<String, dynamic>>> getDelayReports() async {
    final response = await _supabase
        .from('delay_reports')
        .select()
        .order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(response);
  }

  // UPDATE delay report
  Future<void> updateDelayReport({
    required int id,
    required String stationName,
    required String lineName,
    required int delayMinutes,
    required String description,
  }) async {
    final userId = _getCurrentUserId();

    await _supabase
        .from('delay_reports')
        .update({
      'station_name': stationName,
      'line_name': lineName,
      'delay_minutes': delayMinutes,
      'description': description,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', id)
        .eq('user_id', userId);
  }

  // DELETE delay report
  Future<void> deleteDelayReport(int id) async {
    final userId = _getCurrentUserId();

    await _supabase
        .from('delay_reports')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
}