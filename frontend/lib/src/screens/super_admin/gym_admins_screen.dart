import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/gyms_provider.dart';

import '../../screens/admin/add_user_screen.dart';

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
      context.read<GymsProvider>().fetchGyms(); // Ensure gyms are loaded for filter
      _fetchAdmins();
    });
  }

  void _fetchAdmins() {
     context.read<UserProvider>().fetchUsers(role: AppRoles.admin, gymId: _selectedGymId);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Gym Admins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add), 
            onPressed: () async {
               await Navigator.push(
                 context, 
                 MaterialPageRoute(builder: (_) => const AddUserScreen(lockedRole: AppRoles.admin))
               );
               _fetchAdmins();
            }
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Consumer<GymsProvider>(
            builder: (ctx, gymsProvider, _) {
              final gyms = gymsProvider.gyms;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Gym',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  ),
                  initialValue: _selectedGymId,
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('All Gyms')),
                    ...gyms.map((g) => DropdownMenuItem<String?>(
                        value: g.id, child: Text(g.businessName)))
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGymId = value;
                    });
                    _fetchAdmins();
                  },
                ),
              );
            },
          ),
           Expanded(
               child: Consumer<UserProvider>(
                   builder: (context, provider, child) {
                       if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                       
                       // Filter to show only admins? fetchUsers(role: 'admin') should handle it.
                       final admins = provider.students.where((u) => u.role == AppRoles.admin).toList();

                       return ListView.builder(
                           itemCount: admins.length,
                           itemBuilder: (context, index) {
                               final admin = admins[index];
                               return ListTile(
                                   title: Text(admin.name),
                                   subtitle: Text('${admin.email}\nGym: ${admin.gymName ?? "N/A"}'),
                                   trailing: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       IconButton(
                                         icon: const Icon(Icons.edit, color: Colors.blue),
                                         onPressed: () async {
                                           await Navigator.push(
                                             context,
                                             MaterialPageRoute(builder: (_) => AddUserScreen(userToEdit: admin, lockedRole: AppRoles.admin)),
                                           );
                                           _fetchAdmins();
                                         },
                                       ),
                                       IconButton(
                                           icon: const Icon(Icons.delete, color: Colors.red),
                                           onPressed: () async {
                                               final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Confirmar Eliminación'),
                                                    content: Text('¿Está seguro que desea eliminar al administrador ${admin.name}?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx, false),
                                                        child: const Text('Cancelar'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx, true),
                                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                        child: const Text('Eliminar'),
                                                      ),
                                                    ],
                                                  ),
                                               );
                                               
                                               if (confirm == true) {
                                                  await provider.deleteUser(admin.id);
                                               }
                                           },
                                       ),
                                     ],
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


