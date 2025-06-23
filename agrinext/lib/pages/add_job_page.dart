import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddJobPage extends StatefulWidget {
  final dynamic farmId;

  const AddJobPage({super.key, required this.farmId});

  @override
  State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addJob() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    await _supabase.from('jobs').insert({
      'farm_id': widget.farmId,
      'user_id': _supabase.auth.currentUser!.id, // ✅ Add user_id here
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'salary': double.tryParse(_salaryController.text.trim()), // ✅ Save as numeric, not string
      'created_at': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job added successfully')),
      );
    }
  } catch (e) {
    debugPrint('Error adding job: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add job')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Job'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
                validator: (value) => value!.isEmpty ? 'Please enter a job title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(labelText: 'Salary'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter salary' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _addJob,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Add Job'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    super.dispose();
  }
}

