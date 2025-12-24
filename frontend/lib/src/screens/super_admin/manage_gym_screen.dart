import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gyms_provider.dart';
import '../../models/gym_model.dart';

class ManageGymScreen extends StatefulWidget {
  final Gym? gym;

  const ManageGymScreen({super.key, this.gym});

  @override
  State<ManageGymScreen> createState() => _ManageGymScreenState();
}

class _ManageGymScreenState extends State<ManageGymScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _maxProfilesController;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.gym?.businessName ?? '');
    _addressController = TextEditingController(text: widget.gym?.address ?? '');
    _emailController = TextEditingController(text: widget.gym?.email ?? '');
    _maxProfilesController = TextEditingController(text: widget.gym?.maxProfiles.toString() ?? '50');
    _status = widget.gym?.status ?? 'active';
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _maxProfilesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
       final gymData = Gym(
           id: widget.gym?.id ?? '', // ID handled by backend on create
           businessName: _businessNameController.text,
           address: _addressController.text,
           email: _emailController.text,
           status: _status,
           maxProfiles: int.tryParse(_maxProfilesController.text) ?? 50,
       );

       try {
           if (widget.gym == null) {
               await context.read<GymsProvider>().createGym(gymData);
           } else {
               await context.read<GymsProvider>().updateGym(widget.gym!.id, gymData);
           }
           if (mounted) Navigator.pop(context);
       } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.gym == null ? 'Create Gym' : 'Edit Gym')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: 'Business Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _maxProfilesController,
                decoration: const InputDecoration(labelText: 'Max Profiles'),
                keyboardType: TextInputType.number,
                 validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  ],
                  onChanged: (v) => setState(() => _status = v!)
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
              if (widget.gym != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _delete,
                  child: const Text('Delete Gym'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Gym?'),
        content: const Text(
          'WARNING: This will permanently delete the gym and ALL associated data (Users, Plans, Exercises). This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<GymsProvider>().deleteGym(widget.gym!.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting gym: $e')));
        }
      }
    }
  }
}
