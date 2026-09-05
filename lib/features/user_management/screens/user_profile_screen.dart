import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../data/profile_repository.dart';
import 'change_password_screen.dart';
import 'display_name_screen.dart';
import 'profile_picture_screen.dart';
import '../view_models/user_profile_view_model.dart';

const _profileYellow = Color(0xFFFCEB00);

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.user,
    required this.onPreferenceChanged,
  });

  final User user;
  final ValueChanged<bool> onPreferenceChanged;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserProfileViewModel _viewModel;
  late final AuthRepository _authRepository;
  bool _requiresStepFree = false;
  String? _savedMessage;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _authRepository = AuthRepository(client: client);
    _viewModel = UserProfileViewModel(
      repository: ProfileRepository(client: client),
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _viewModel.load(widget.user);
    if (!mounted || _viewModel.profile == null) return;
    setState(() => _requiresStepFree = _viewModel.profile!.requiresStepFree);
    widget.onPreferenceChanged(_requiresStepFree);
  }

  Future<void> _save() async {
    setState(() => _savedMessage = null);
    await _viewModel.savePreferences(requiresStepFree: _requiresStepFree);
    if (!mounted) return;
    final profile = _viewModel.profile;
    if (profile != null && _viewModel.errorMessage == null) {
      widget.onPreferenceChanged(profile.requiresStepFree);
      setState(() => _savedMessage = 'Profile updated.');
    }
  }

  Future<void> _logOut() => _authRepository.signOut();

  Future<void> _openProfilePicture() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProfilePictureScreen(user: widget.user),
      ),
    );
    if (mounted) await _loadProfile();
  }

  Future<void> _openDisplayName() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => DisplayNameScreen(user: widget.user)),
    );
    if (mounted) await _loadProfile();
  }

  Future<void> _openChangePassword() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
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
        if (_viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final avatarPath = _viewModel.profile?.avatarPath;
        final avatarImage = avatarPath == null
            ? null
            : Supabase.instance.client.storage
                  .from('profile-photos')
                  .getPublicUrl(avatarPath);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black,
                  backgroundImage: avatarImage == null
                      ? null
                      : NetworkImage(avatarImage),
                  child: avatarImage == null
                      ? const Icon(
                          Icons.person,
                          color: _profileYellow,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Account and accessibility settings',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.user.email ?? 'Signed-in commuter',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _requiresStepFree,
                    activeThumbColor: _profileYellow,
                    activeTrackColor: Colors.black,
                    onChanged: (value) {
                      setState(() => _requiresStepFree = value);
                      widget.onPreferenceChanged(value);
                    },
                    title: const Text(
                      'Prioritise step-free exits',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Show wheelchair-accessible exits first.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ProfileActionTile(
                    icon: Icons.person_outline,
                    title: 'Display name',
                    subtitle:
                        _viewModel.profile?.displayName ??
                        'Set your display name.',
                    onTap: _openDisplayName,
                  ),
                  const Divider(height: 1),
                  _ProfileActionTile(
                    icon: Icons.account_circle_outlined,
                    title: 'Profile picture',
                    subtitle: 'Upload or remove your profile photo.',
                    onTap: _openProfilePicture,
                  ),
                  const Divider(height: 1),
                  _ProfileActionTile(
                    icon: Icons.lock_outline,
                    title: 'Change password',
                    subtitle: 'Update the password used to sign in.',
                    onTap: _openChangePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_viewModel.errorMessage != null)
              _ProfileMessage(
                text: _viewModel.errorMessage!,
                color: Colors.red,
              ),
            if (_savedMessage != null)
              _ProfileMessage(text: _savedMessage!, color: Colors.green),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: _profileYellow,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _viewModel.isSaving ? null : _save,
                icon: _viewModel.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _viewModel.isSaving ? 'Saving...' : 'Save preferences',
                ),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              onPressed: _logOut,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: Colors.black,
        child: Icon(icon, color: _profileYellow),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
