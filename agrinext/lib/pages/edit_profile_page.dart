import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _contactController = TextEditingController();
  DateTime? _birthdate;
  String? _gender;
  bool _isLoading = true;
  String? _avatarUrl;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      setState(() {
        _usernameController.text = data['username'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _contactController.text = data['contact'] ?? '';
        _avatarUrl = data['avatar_url'];
        _birthdate = data['birthdate'] != null ? DateTime.parse(data['birthdate']) : null;
        _gender = data['gender'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _pickedFile = picked;
      });
    }
  }

  Future<String?> _uploadAvatar(XFile pickedFile) async {
    final userId = _supabase.auth.currentUser!.id;
    final fileExt = pickedFile.path.split('.').last;
    final filePath = 'avatars/$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    final fileBytes = await pickedFile.readAsBytes();

    await _supabase.storage.from('avatars').uploadBinary(
      filePath,
      fileBytes,
      fileOptions: const FileOptions(upsert: true),
    );

    return filePath;
  }

  Future<void> _removeAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Profile Picture"),
        content: const Text("Are you sure you want to remove your profile picture?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      try {
        await _supabase.storage.from('avatars').remove([_avatarUrl!]);
      } catch (e) {
        debugPrint('Error removing avatar from storage: $e');
      }
    }

    try {
      await _supabase.from('profiles').update({'avatar_url': null}).eq('id', _supabase.auth.currentUser!.id);

      setState(() {
        _avatarUrl = null;
        _pickedFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture removed.")));
    } catch (e) {
      debugPrint('Error updating profile to remove avatar: $e');
    }
  }

  Future<void> _pickBirthdate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _birthdate = date);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _birthdate == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete all required fields.")));
      return;
    }
    setState(() => _isLoading = true);

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    String? avatarFilePath = _avatarUrl;
    if (_pickedFile != null) {
      avatarFilePath = await _uploadAvatar(_pickedFile!);
    }

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email, // Required by your schema
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'contact': _contactController.text.trim(),
        'avatar_url': avatarFilePath,
        'birthdate': _birthdate!.toIso8601String(),
        'gender': _gender!,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update profile")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAvatar() {
    if (_pickedFile != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: kIsWeb ? NetworkImage(_pickedFile!.path) : FileImage(File(_pickedFile!.path)) as ImageProvider,
      );
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(_avatarUrl!);
      return CircleAvatar(radius: 50, backgroundImage: NetworkImage(publicUrl));
    } else {
      return const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50), backgroundColor: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), backgroundColor: Colors.green),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          _buildAvatar(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: _pickImage,
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_avatarUrl != null || _pickedFile != null)
                      TextButton.icon(
                        onPressed: _removeAvatar,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text("Remove Photo", style: TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a username' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: 'Contact Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a contact number';
                        final pattern = RegExp(r'^(09\d{9}|\+639\d{9})$');
                        if (!pattern.hasMatch(value)) return 'Enter a valid Philippine mobile number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_birthdate != null
                          ? "Birthdate: ${_birthdate!.toLocal().toString().split(' ')[0]}"
                          : "Select Birthdate"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickBirthdate,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) => setState(() => _gender = value),
                      validator: (value) => value == null || value.isEmpty ? 'Please select gender' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

