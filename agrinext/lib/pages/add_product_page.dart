import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AddProductPage extends StatefulWidget {
  final VoidCallback onProductAdded;

  const AddProductPage({super.key, required this.onProductAdded});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();

  String selectedCategory = 'Produce';
  final categories = [
    'Produce',
    'Tools & Equipment',
    'Seeds & Plants',
    'Fertilizers',
    'Pesticides',
    'Animal Feed & Supplies',
    'Machinery & Rentals',
  ];
  Uint8List? _webImage;
  XFile? _pickedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        _webImage = await picked.readAsBytes();
      }
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return null;

    final String fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      if (kIsWeb) {
        final mimeType = lookupMimeType('', headerBytes: _webImage!);
        await supabase.storage.from('product_images').uploadBinary(
          fileName,
          _webImage!,
          fileOptions: FileOptions(contentType: mimeType ?? 'image/jpeg', upsert: true),
        );
      } else {
        await supabase.storage.from('product_images').upload(
          fileName,
          File(_pickedImage!.path),
          fileOptions: const FileOptions(upsert: true),
        );
      }
      return fileName; // ✅ return only the filename
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    final uploadedFilename = await _uploadImage();

    try {
      final userId = supabase.auth.currentUser?.id;
      await supabase.from('products').insert({
        'user_id': userId,
        'name': _nameController.text.trim(),
        'price': _priceController.text.trim(),
        'location': _locationController.text.trim(),
        'category': selectedCategory,
        'image_url': uploadedFilename ?? '', // ✅ only filename or empty
        'contact': _contactController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      widget.onProductAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Insert error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add product. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Center(
                    child: _webImage != null
                        ? Image.memory(_webImage!, fit: BoxFit.cover, height: 180)
                        : (!kIsWeb && _pickedImage != null)
                            ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover, height: 180)
                            : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => value!.isEmpty ? 'Enter product name' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (value) => value!.isEmpty ? 'Enter price' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) => value!.isEmpty ? 'Enter location' : null,
              ),
              DropdownButtonFormField(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => selectedCategory = value!),
              ),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Seller Contact Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Enter contact number' : null,
              ),
              const SizedBox(height: 20),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Add Product'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

