import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_repository.dart';
import '../view_models/user_profile_view_model.dart';

const _displayNameYellow = Color(0xFFFCEB00);

class DisplayNameScreen extends StatefulWidget {
  const DisplayNameScreen({super.key, required this.user});

  final User user;

  @override
  State<DisplayNameScreen> createState() => _DisplayNameScreenState();
}

class _DisplayNameScreenState extends State<DisplayNameScreen> {
  late final UserProfileViewModel _viewModel;
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = UserProfileViewModel(
      repository: ProfileRepository(client: Supabase.instance.client),
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _viewModel.load(widget.user);
    if (!mounted || _viewModel.profile == null) return;
    _nameController.text = _viewModel.profile!.displayName;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _viewModel.save(
      displayName: _nameController.text,
      requiresStepFree: _viewModel.profile?.requiresStepFree ?? false,
    );
    if (!mounted || _viewModel.errorMessage != null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Display name updated.')));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display name')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _viewModel.errorMessage ??
                      'Unable to load your display name.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalise your account',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This name appears in your Sentra1 profile.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a display name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: _displayNameYellow,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _viewModel.isSaving ? null : _save,
                            icon: _viewModel.isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _viewModel.isSaving ? 'Saving...' : 'Save name',
                            ),
                          ),
                        ),
                        if (_viewModel.errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _viewModel.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
