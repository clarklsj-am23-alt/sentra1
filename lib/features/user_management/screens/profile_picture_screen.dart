import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_repository.dart';
import '../models/user_profile.dart';

const _profilePictureYellow = Color(0xFFFCEB00);
const _profilePhotosBucket = 'profile-photos';

class ProfilePictureScreen extends StatefulWidget {
  const ProfilePictureScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfilePictureScreen> createState() => _ProfilePictureScreenState();
}

class _ProfilePictureScreenState extends State<ProfilePictureScreen> {
  late final ProfileRepository _repository;
  final _picker = ImagePicker();
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;
  int _imageVersion = 0;

  @override
  void initState() {
    super.initState();
    _repository = ProfileRepository(client: Supabase.instance.client);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _repository.getOrCreateProfile(widget.user);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your profile picture.';
      });
    }
  }

  String _publicUrl(String path) {
    final url = Supabase.instance.client.storage
        .from(_profilePhotosBucket)
        .getPublicUrl(path);
    return _imageVersion == 0 ? url : '$url?v=$_imageVersion';
  }

  Future<void> _choosePicture() async {
    XFile? image;
    try {
      image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
    } on PlatformException {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Photo picker unavailable. Stop the app and run it again after a full rebuild.',
      );
      return;
    }
    if (image == null || !mounted) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final currentProfile = _profile;
      if (currentProfile == null) return;

      final bytes = await image.readAsBytes();
      final extension = _fileExtension(image.name);
      final path = '${widget.user.id}/avatar.$extension';
      final contentType = image.mimeType ?? _contentType(extension);

      await Supabase.instance.client.storage
          .from(_profilePhotosBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final updatedProfile = await _repository.updateAvatarPath(
        profile: currentProfile,
        avatarPath: path,
      );

      final previousPath = currentProfile.avatarPath;
      if (previousPath != null && previousPath != path) {
        await Supabase.instance.client.storage
            .from(_profilePhotosBucket)
            .remove([previousPath]);
      }

      if (!mounted) return;
      setState(() {
        _profile = updatedProfile;
        _imageVersion = DateTime.now().millisecondsSinceEpoch;
        _successMessage = 'Profile picture updated.';
      });
    } on StorageException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to update your profile picture.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removePicture() async {
    final profile = _profile;
    final path = profile?.avatarPath;
    if (profile == null || path == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await Supabase.instance.client.storage.from(_profilePhotosBucket).remove([
        path,
      ]);
      final updatedProfile = await _repository.updateAvatarPath(
        profile: profile,
        avatarPath: null,
      );
      if (!mounted) return;
      setState(() {
        _profile = updatedProfile;
        _imageVersion = 0;
        _successMessage = 'Profile picture removed.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to remove your profile picture.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _fileExtension(String name) {
    final extension = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : 'jpg';
    return {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)
        ? extension
        : 'jpg';
  }

  String _contentType(String extension) {
    if (extension == 'png') return 'image/png';
    if (extension == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final path = _profile?.avatarPath;
    final imageUrl = path == null ? null : _publicUrl(path);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile picture')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 58,
                          backgroundColor: Colors.black,
                          backgroundImage: imageUrl == null
                              ? null
                              : NetworkImage(imageUrl),
                          child: imageUrl == null
                              ? const Icon(
                                  Icons.person,
                                  color: _profilePictureYellow,
                                  size: 58,
                                )
                              : null,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Choose a clear photo that helps you recognise your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: _profilePictureYellow,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isUploading ? null : _choosePicture,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_library_outlined),
                            label: Text(
                              _isUploading ? 'Updating...' : 'Choose a photo',
                            ),
                          ),
                        ),
                        if (path != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _isUploading ? null : _removePicture,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove photo'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  _PictureMessage(text: _errorMessage!, color: Colors.red),
                if (_successMessage != null)
                  _PictureMessage(
                    text: _successMessage!,
                    color: Colors.green.shade700,
                  ),
              ],
            ),
    );
  }
}

class _PictureMessage extends StatelessWidget {
  const _PictureMessage({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, left: 4, right: 4),
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
