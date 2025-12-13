import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/gyms_provider.dart';
import '../../models/user_model.dart';

class GymAdminsScreen extends StatefulWidget {
  const GymAdminsScreen({super.key});

  @override
  State<GymAdminsScreen> createState() => _GymAdminsScreenState();
}

class _GymAdminsScreenState extends State<GymAdminsScreen> {
  String? _selectedGymId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAdmins();
    });
  }

  void _fetchAdmins() {
     context.read<UserProvider>().fetchUsers(role: 'admin', gymId: _selectedGymId);
  }

  void _showAddAdminDialog() {
       // Ideally verify Gyms are loaded
       final gyms = context.read<GymsProvider>().gyms;
       if (gyms.isEmpty) {
           context.read<GymsProvider>().fetchGyms();
       }
       
       showDialog(context: context, builder: (ctx) => _AddAdminDialog(gyms: gyms, onSave: _fetchAdmins));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Gym Admins'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddAdminDialog),
        ],
      ),
      body: Column(
        children: [
           // Filter Bar?
           // For now just list
           Expanded(
               child: Consumer<UserProvider>(
                   builder: (context, provider, child) {
                       if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                       
                       // Filter to show only admins? fetchUsers(role: 'admin') should handle it.
                       final admins = provider.students.where((u) => u.role == 'admin').toList();

                       return ListView.builder(
                           itemCount: admins.length,
                           itemBuilder: (context, index) {
                               final admin = admins[index];
                               return ListTile(
                                   title: Text(admin.name),
                                   subtitle: Text(admin.email),
                                   trailing: IconButton(
                                       icon: const Icon(Icons.delete, color: Colors.red),
                                       onPressed: () async {
                                           // Confirm delete
                                           await provider.deleteUser(admin.id);
                                       },
                                   ),
                               );
                           },
                       );
                   },
               ),
           )
        ],
      ),
    );
  }
}

class _AddAdminDialog extends StatefulWidget {
    final List<Gym> gyms;
    final VoidCallback onSave;
    const _AddAdminDialog({required this.gyms, required this.onSave});

    @override
    State<_AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<_AddAdminDialog> {
    final _emailCtrl = TextEditingController();
    final _passCtrl = TextEditingController();
    final _firstCtrl = TextEditingController();
    final _lastCtrl = TextEditingController();
    String? _gymId;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('Add Gym Admin'),
            content: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        DropdownButtonFormField<String>(
                            hint: const Text('Select Gym'),
                            items: widget.gyms.map<DropdownMenuItem<String>>((g) => DropdownMenuItem(value: g.id, child: Text(g.businessName))).toList(),
                            onChanged: (v) => setState(() => _gymId = v),
                        ),
                        TextField(controller: _firstCtrl, decoration: const InputDecoration(labelText: 'First Name')),
                        TextField(controller: _lastCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
                        TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                        TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password')),
                    ],
                ),
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () async {
                        if (_gymId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a Gym')));
                            return;
                        }
                        
                        final provider = context.read<UserProvider>();
                        
                        final success = await provider.addUser(
                            email: _emailCtrl.text,
                            password: _passCtrl.text,
                            firstName: _firstCtrl.text,
                            lastName: _lastCtrl.text,
                            role: 'admin',
                            gymId: _gymId,
                        );

                        if (success) {
                            widget.onSave();
                            Navigator.pop(context);
                        } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create admin')));
                        }
                    },
                    child: const Text('Create'),
                )
            ],
        );
    }
}
