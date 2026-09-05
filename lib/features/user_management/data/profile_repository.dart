import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class ProfileRepository {
  ProfileRepository({required this._client});

  final SupabaseClient _client;

  Future<UserProfile> getOrCreateProfile(User user) async {
    final existing = await _findProfile(user.id);
    if (existing != null) return UserProfile.fromMap(existing);

    try {
      final created = await _client
          .from('profiles')
          .insert({
            'id': user.id,
            'display_name':
                (user.userMetadata?['display_name'] as String?) ?? 'Commuter',
            'requires_step_free': false,
          })
          .select()
          .single();
      return UserProfile.fromMap(created);
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      final createdByAnotherRequest = await _findProfile(user.id);
      if (createdByAnotherRequest == null) rethrow;
      return UserProfile.fromMap(createdByAnotherRequest);
    }
  }

  Future<Map<String, dynamic>?> _findProfile(String userId) {
    return _client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  Future<UserProfile> updateProfile({
    required UserProfile profile,
    required String displayName,
    required bool requiresStepFree,
  }) async {
    final updated = await _client
        .from('profiles')
        .update({
          'display_name': displayName.trim().isEmpty
              ? 'Commuter'
              : displayName.trim(),
          'requires_step_free': requiresStepFree,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', profile.id)
        .select()
        .single();
    return UserProfile.fromMap(updated);
  }

  Future<UserProfile> updateAvatarPath({
    required UserProfile profile,
    required String? avatarPath,
  }) async {
    final updated = await _client
        .from('profiles')
        .update({
          'avatar_path': avatarPath,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', profile.id)
        .select()
        .single();
    return UserProfile.fromMap(updated);
  }
}
