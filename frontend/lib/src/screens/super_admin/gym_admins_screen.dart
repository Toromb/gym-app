import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/gyms_provider.dart';
import '../../models/user_model.dart';
import '../../models/gym_model.dart';
import '../../services/auth_service.dart';
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
      context.read<GymsProvider>().fetchGyms();
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
                       
                       final admins = provider.students.where((u) => u.role == AppRoles.admin).toList();

                       return ListView.builder(
                           itemCount: admins.length,
                           itemBuilder: (context, index) {
                               final admin = admins[index];
                               return ListTile(
                                    title: Row(
                                      children: [
                                        Text(admin.name),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (admin.isActive == true) ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: (admin.isActive == true) ? Colors.green : Colors.orange, width: 0.5),
                                          ),
                                          child: Text(
                                            (admin.isActive == true) ? 'Activo' : 'Pendiente',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: (admin.isActive == true) ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text('${admin.email}\nGym: ${admin.gymName ?? "N/A"}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: 'Editar',
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => AddUserScreen(userToEdit: admin, lockedRole: AppRoles.admin)),
                                            );
                                            _fetchAdmins();
                                          },
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.vpn_key),
                                          tooltip: 'Opciones de Cuenta',
                                          onSelected: (value) async {
                                             final authService = AuthService();
                                             String? token;
                                             String path = '';
                                             
                                             if (value == 'activation') {
                                                token = await authService.generateActivationToken(admin.id);
                                             } else if (value == 'reset') {
                                                token = await authService.generateResetToken(admin.id);
                                             }

                                             if (token != null && context.mounted) {
                                                final String link = (value == 'activation')
                                                    ? authService.getActivationUrl(token)
                                                    : authService.getResetUrl(token);
                                                
                                                await Clipboard.setData(ClipboardData(text: link));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Enlace copiado al portapapeles')),
                                                );
                                             } else if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Error al generar enlace'), backgroundColor: Colors.red),
                                                );
                                             }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(value: 'activation', child: Text('Copiar Link Activación')),
                                            const PopupMenuItem(value: 'reset', child: Text('Copiar Link Recuperación')),
                                          ],
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



