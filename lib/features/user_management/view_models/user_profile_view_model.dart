import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_repository.dart';
import '../models/user_profile.dart';

class UserProfileViewModel extends ChangeNotifier {
  UserProfileViewModel({required this._repository});

  final ProfileRepository _repository;
  UserProfile? profile;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> load(User user) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _repository.getOrCreateProfile(user);
    } catch (_) {
      errorMessage = 'Unable to load your profile.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save({
    required String displayName,
    required bool requiresStepFree,
  }) async {
    final current = profile;
    if (current == null) return;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _repository.updateProfile(
        profile: current,
        displayName: displayName,
        requiresStepFree: requiresStepFree,
      );
    } catch (_) {
      errorMessage = 'Unable to save your profile.';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> savePreferences({required bool requiresStepFree}) async {
    final current = profile;
    if (current == null) return;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _repository.updateProfile(
        profile: current,
        displayName: current.displayName,
        requiresStepFree: requiresStepFree,
      );
    } catch (_) {
      errorMessage = 'Unable to save your preferences.';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
