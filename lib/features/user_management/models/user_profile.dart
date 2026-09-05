class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.requiresStepFree,
    this.avatarPath,
  });

  final String id;
  final String displayName;
  final bool requiresStepFree;
  final String? avatarPath;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      displayName: (map['display_name'] as String?) ?? 'Commuter',
      requiresStepFree: (map['requires_step_free'] as bool?) ?? false,
      avatarPath: map['avatar_path'] as String?,
    );
  }
}
