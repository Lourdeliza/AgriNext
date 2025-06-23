import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class AddFarmPage extends StatefulWidget {
  final VoidCallback onFarmAdded;
  final String userRole;

  const AddFarmPage({super.key, required this.onFarmAdded, required this.userRole});

  @override
  State<AddFarmPage> createState() => _AddFarmPageState();
}

class _AddFarmPageState extends State<AddFarmPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  XFile? _selectedImage;
  bool _isLoading = false;

  Future<String?> _uploadImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final mimeType = lookupMimeType(file.path);

      await _supabase.storage.from('farm-images').uploadBinary(
        filename,
        bytes,
        fileOptions: FileOptions(contentType: mimeType),
      );

      return filename;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _createAdminNotifications(String farmName) async {
    try {
      await _supabase.from('notifications').insert({
        'title': 'New Farm Submission',
        'body': 'A new farm "$farmName" has been submitted and requires your approval.',
        'type': 'farm_submission',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  Future<void> _saveFarm() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  String? uploadedImageFilename;
  if (_selectedImage != null) {
    uploadedImageFilename = await _uploadImage(_selectedImage!);
  }

  final farmName = _nameController.text.trim();

  final newFarm = {
    'user_id': _supabase.auth.currentUser?.id,
    'name': farmName,
    'location': _locationController.text.trim(),
    'description': _descriptionController.text.trim(),
    'contact': _contactController.text.trim(),
    'image_url': uploadedImageFilename,
    'status': widget.userRole == 'admin' ? 'approved' : 'pending',
    'created_at': DateTime.now().toIso8601String(),
  };

  try {
    await _supabase.from('farms').insert(newFarm);

    widget.onFarmAdded();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.userRole == 'admin'
              ? 'Farm added successfully.'
              : 'Farm submitted for approval.'),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error saving farm: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding farm.')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Farm'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Farm Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter farm name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) => value!.isEmpty ? 'Please enter location' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact Info'),
                ),
                const SizedBox(height: 16),
                _selectedImage != null
                    ? Column(
                        children: [
                          FutureBuilder<Uint8List>(
                            future: _selectedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done &&
                                  snapshot.hasData) {
                                return Image.memory(snapshot.data!, height: 150);
                              } else {
                                return const CircularProgressIndicator();
                              }
                            },
                          ),
                          TextButton(
                            onPressed: () => setState(() => _selectedImage = null),
                            child: const Text('Remove Image'),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Select Image'),
                      ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _saveFarm,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: Text(widget.userRole == 'admin'
                            ? 'Add Farm'
                            : 'Submit for Approval'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}



