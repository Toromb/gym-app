import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../../services/auth_service.dart';
import 'package:flutter/services.dart';
import '../../models/plan_model.dart';
import '../../models/user_model.dart'; // Import User model for type checking
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import '../teacher/student_plans_screen.dart';
import '../../widgets/payment_status_badge.dart';
import '../shared/user_detail_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_client.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'paid', 'pending', 'overdue'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers(); // Fetches all accessible users
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.read<AuthProvider>().role;
    final isAdmin = userRole == AppRoles.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Usuarios'),
      ),
      floatingActionButton: isAdmin ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'invite_link',
            onPressed: () => _showInviteLinkDialog(context),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            tooltip: 'Link de Invitación',
            child: Icon(Icons.qr_code_2, color: Theme.of(context).colorScheme.onTertiary),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_user',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddUserScreen()),
              );
            },
            tooltip: 'Crear Usuario',
            child: const Icon(Icons.person_add),
          ),
        ],
      ) : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = userProvider.students; // 'students' contains all users

          // Filter Logic
          final filteredUsers = users.where((u) {
            final matchesSearch = ('${u.firstName} ${u.lastName}').toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                  u.email.toLowerCase().contains(_searchQuery.toLowerCase());
            
            if (!matchesSearch) return false;

            if (_filterStatus == 'all') return true;
            
            final status = u.paymentStatus?.toLowerCase() ?? 'pending';
            return status == _filterStatus;
          }).toList();

          if (isAdmin) {
            final admins = filteredUsers.where((u) => u.role == 'admin').toList();
            final profes = filteredUsers.where((u) => u.role == 'profe').toList();
            final alumnos = filteredUsers.where((u) => u.role == 'alumno').toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchAndFilter(),
                  _buildSectionHeader(context, 'Admins', admins.length),
                  ..._buildUserListWidgets(context, admins, isAdmin, false),
                  
                  _buildSectionHeader(context, 'Profesores', profes.length),
                  ..._buildUserListWidgets(context, profes, isAdmin, false),
                  
                  _buildSectionHeader(context, 'Alumnos', alumnos.length),
                  ..._buildUserListWidgets(context, alumnos, isAdmin, false),
                  
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            );
          } else {
            // Profe View: Show only Alumnos
            // Also apply search for Profe view? Yes.
            final students = filteredUsers.where((u) => u.role == AppRoles.alumno).toList();
            return Column(
              children: [
                 _buildSearchAndFilter(), // Reuse
                _buildSectionHeader(context, 'Alumnos', students.length),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: _buildUserListWidgets(context, students, false, true),
                  ),
                ),
              ],
            );
          }
        },
      ),
        ),
      ),
    );
  }

  void _showInviteLinkDialog(BuildContext context) {
      final user = context.read<AuthProvider>().user;
      final gymId = user?.gymId;
      
      if (gymId == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No se encontró el gimnasio del administrador.')));
         return;
      }

      showDialog(
          context: context,
          builder: (context) => _InviteLinkDialog(gymId: gymId),
      );
  }

  Widget _buildSearchAndFilter() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _filterStatus,
            decoration: InputDecoration(
              labelText: 'Estado de Cuota',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Todos')),
              DropdownMenuItem(value: 'paid', child: Text('Cuota Paga')),
              DropdownMenuItem(value: 'pending', child: Text('Cuota Por Vencer')),
              DropdownMenuItem(value: 'overdue', child: Text('Cuota Vencida')),
            ],
            onChanged: (val) {
                if (val != null) {
                    setState(() {
                        _filterStatus = val;
                    });
                }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.primaryContainer,
               borderRadius: BorderRadius.circular(8),
             ),
             child: Text(
               count.toString(), 
               style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)
             ),
           ),
           const SizedBox(width: 12),
           Text(
             title,
             style: Theme.of(context).textTheme.titleLarge?.copyWith(
               fontWeight: FontWeight.bold,
               color: Theme.of(context).colorScheme.onSurface,
             ),
           ),
        ],
      ),
    );
  }

  List<Widget> _buildUserListWidgets(BuildContext context, List<dynamic> users, bool isAdmin, bool isProfeView) {
    if (users.isEmpty) {
      return [const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('No se encontraron usuarios.', style: TextStyle(fontStyle: FontStyle.italic)),
      )];
    }
    
    final colorScheme = Theme.of(context).colorScheme;

    return users.map((user) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Compact margin
        elevation: 0,
        shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12),
           side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Compact padding
          child: Column(
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.primary,
                          radius: 20, // Smaller avatar
                          child: Text(
                            user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                            style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${user.firstName} ${user.lastName}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (user.isActive == true) ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: (user.isActive == true) ? Colors.green : Colors.orange, width: 0.5),
                                      ),
                                      child: Text(
                                        (user.isActive == true) ? 'Activo' : 'Pendiente',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: (user.isActive == true) ? Colors.green : Colors.orange,
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                               Text(
                                 user.email,
                                 style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                               ),
                            ],
                          ),
                        ),
                     ],
                   ),
                   if (isAdmin && (user.role == 'alumno' || user.role == 'profe')) 
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        alignment: Alignment.centerRight,
                        child: PaymentStatusBadge(
                          status: user.paymentStatus,
                          isEditable: true,
                          onMarkAsPaid: () async {
                               final success = await context.read<UserProvider>().markUserAsPaid(user.id);
                               if (context.mounted) {
                                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                     content: Text(success ? 'Pago actualizado' : 'Error al actualizar'),
                                     backgroundColor: success ? Colors.green : Colors.red,
                                   ));
                               }
                          },
                        ),
                      ),
                 ],
               ),
               if (user.professorName != null) ...[
                 const SizedBox(height: 12),
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Row(
                     children: [
                        Icon(Icons.person_outline, size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('Profe: ${user.professorName}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                     ],
                   ),
                 ),
               ],
               const SizedBox(height: 12),
               const Divider(),
               SingleChildScrollView(
                 scrollDirection: Axis.horizontal,
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                       // View Details
                       IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.visibility_outlined),
                          tooltip: 'Ver Detalles',
                          onPressed: () {
                             Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailScreen(user: user),
                                ),
                              );
                          },
                        ),
                        const SizedBox(width: 12),
                       
                       if ((isProfeView || isAdmin) && user.role == 'alumno') ...[
                          if (isAdmin) ...[
                           IconButton(
                             visualDensity: VisualDensity.compact,
                             iconSize: 20,
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                             icon: const Icon(Icons.person_add_alt),
                             tooltip: 'Asignar Profesor',
                             onPressed: () => _showAssignProfessorDialog(context, user),
                           ),
                           const SizedBox(width: 12),
                          ],
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.assignment_add),
                            tooltip: 'Asignar Plan',
                            onPressed: () => _showAssignPlanDialog(context, user.id),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.list_alt),
                            tooltip: 'Gestionar Planes',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentPlansScreen(student: user),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                       ],
                       
                        if (isAdmin)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.vpn_key),
                            tooltip: 'Opciones de Cuenta',
                            onSelected: (value) async {
                               final authService = AuthService(); // Instantiate locally
                               String? token;
                               String path = '';
                               
                               ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Generando enlace...'), duration: Duration(seconds: 1)),
                               );

                               if (value == 'activation') {
                                  token = await authService.generateActivationToken(user.id);
                               } else if (value == 'reset') {
                                  token = await authService.generateResetToken(user.id);
                               }
  
                               if (token != null && context.mounted) {
                                  final String link = (value == 'activation')
                                      ? authService.getActivationUrl(token)
                                      : authService.getResetUrl(token);
  
                                  await Clipboard.setData(ClipboardData(text: link));
                                  if (context.mounted) {
                                     ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove "Generating..."
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(content: Text('Enlace copiado al portapapeles'), backgroundColor: Colors.green),
                                     );
                                  }
                               } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Error al generar enlace'), backgroundColor: Colors.red),
                                  );
                               }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'activation',
                                child: Text('Copiar Link Activación'),
                              ),
                               const PopupMenuItem(
                                value: 'reset',
                                child: Text('Copiar Link Recuperación'),
                              ),
                            ],
                          ),
  
                       IconButton(
                         visualDensity: VisualDensity.compact,
                         iconSize: 20,
                         padding: EdgeInsets.zero,
                         constraints: const BoxConstraints(),
                         icon: const Icon(Icons.edit_outlined),
                         tooltip: 'Editar',
                         onPressed: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => EditUserScreen(user: user),
                             ),
                           );
                         },
                       ),
                       const SizedBox(width: 12),
                       
                        IconButton(
                         visualDensity: VisualDensity.compact,
                         iconSize: 20,
                         padding: EdgeInsets.zero,
                         constraints: const BoxConstraints(),
                         icon: Icon(Icons.delete_outline, color: colorScheme.error),
                         tooltip: 'Eliminar',
                         onPressed: () async {
                           final confirm = await showDialog<bool>(
                             context: context,
                             builder: (ctx) => AlertDialog(
                               title: const Text('¿Eliminar Usuario?'),
                               content: const Text('Esta acción no se puede deshacer.'),
                               actions: [
                                 TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                 FilledButton(
                                   style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                   onPressed: () => Navigator.of(ctx).pop(true), 
                                   child: const Text('Eliminar')
                                 ),
                               ],
                             ),
                           );
                           
                           if (confirm == true && context.mounted) {
                             context.read<UserProvider>().deleteUser(user.id);
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
                           }
                         },
                       ),
                   ],
                 ),
               )
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showAssignProfessorDialog(BuildContext context, User student) async {
      showDialog(
          context: context,
          builder: (context) {
              return _AssignProfessorDialog(student: student);
          }
      );
  }

  void _showAssignPlanDialog(BuildContext context, String studentId) {
    // Fetch plans first
    context.read<PlanProvider>().fetchPlans();

    showDialog(
      context: context,
      builder: (context) {
        String? selectedPlanId;
        return AlertDialog(
          title: const Text('Asignar Plan'),
          content: Consumer<PlanProvider>(
            builder: (context, planProvider, child) {
              if (planProvider.isLoading) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
              if (planProvider.plans.isEmpty) return const Text('No hay planes disponibles. Crea uno primero.');

              return DropdownButtonFormField<String>(
                items: planProvider.plans.map((plan) {
                  return DropdownMenuItem(
                    value: plan.id,
                    child: Text(plan.name),
                  );
                }).toList(),
                onChanged: (val) => selectedPlanId = val,
                decoration: const InputDecoration(labelText: 'Seleccionar Plan'),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
                onPressed: () async {
                if (selectedPlanId != null) {
                   final error = await context.read<PlanProvider>().assignPlan(selectedPlanId!, studentId);
                   if (context.mounted) {
                     Navigator.pop(context);
                     if (error == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Plan asignado exitosamente'), 
                            backgroundColor: Colors.green
                          ),
                        );
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: Colors.red,
                          ),
                        );
                     }
                   }
                }
              },
              child: const Text('Asignar'),
            ),
          ],
        );
      },
    );
  }
}

class _AssignProfessorDialog extends StatefulWidget {
    final User student;
    const _AssignProfessorDialog({required this.student});

    @override
    State<_AssignProfessorDialog> createState() => _AssignProfessorDialogState();
}

class _AssignProfessorDialogState extends State<_AssignProfessorDialog> {
    List<User> _professors = [];
    bool _isLoading = true;
    String? _selectedProfessorId;
    
    @override
    void initState() {
        super.initState();
        _selectedProfessorId = widget.student.professorId;
        _fetchProfessors();
    }
    
    Future<void> _fetchProfessors() async {
        try {
            // Need to import UserService or use provider? 
            // The file imports UserService? No, it imports UserProvider.
            // Let's use UserProvider if possible, but fetchUsers() gets all.
            // Let's rely on UserService direct call just like EditUserScreen did. 
            // *Wait*, ManageUsersScreen didn't import UserService. I need to add that import.
             
            // Assuming UserService instance is available or I can instantiate it.
            // For now, I'll assume we can use context.read<UserProvider>() if it has a way, 
            // OR I need to add `import '../../services/user_service.dart';` at top of file. 
            // *Self-Correction*: I should add the import in a subsequent step if it's missing.
            // Let's try to assume I will add the import next tool call or assume it's implicitly available (it's not).
            // Actually, I can use UserProvider to update, but fetching specifically teachers might need filter.
            // But UserProvider.students HAS teachers if I am admin.
            // So I can filter `context.read<UserProvider>().students`!
            
            final allUsers = context.read<UserProvider>().students;
            final professors = allUsers.where((u) => u.role == UserRoles.profe).toList();
            if (mounted) {
                setState(() {
                    _professors = professors;
                    _isLoading = false;
                });
            }
        } catch (e) {
             if (mounted) setState(() => _isLoading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('Asignar Profesor'),
            content: _isLoading 
                ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        DropdownButtonFormField<String>(
                             initialValue: _professors.any((p) => p.id == _selectedProfessorId) ? _selectedProfessorId : null,
                             decoration: const InputDecoration(
                                 labelText: 'Seleccionar Profesor',
                             ),
                             items: [
                                 const DropdownMenuItem<String>(
                                     value: null,
                                     child: Text('Sin Profesor (Desasignar)'),
                                 ),
                                 ..._professors.map((p) => DropdownMenuItem(
                                     value: p.id,
                                     child: Text(p.name),
                                 )),
                             ],
                             onChanged: (val) => setState(() => _selectedProfessorId = val),
                         ),
                    ],
                ),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () async {
                            final success = await context.read<UserProvider>().updateUser(
                                widget.student.id,
                                { 'professorId': _selectedProfessorId } // If null, backend handles unassign
                            );
                             if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(success ? 'Profesor asignado exitosamente' : 'Error al asignar profesor')),
                                );
                                // Refresh list to show updated data? 
                                // UserProvider.updateUser usually should update local state, 
                                // but if not, we might need fetchUsers.
                                context.read<UserProvider>().fetchUsers(forceRefresh: true); 
                            }
                        },
                        child: const Text('Guardar'),
                    )
                ]
        );
    }
}

class _InviteLinkDialog extends StatefulWidget {
    final String gymId;
    const _InviteLinkDialog({required this.gymId});

    @override
    State<_InviteLinkDialog> createState() => _InviteLinkDialogState();
}

class _InviteLinkDialogState extends State<_InviteLinkDialog> {
    bool _isLoading = true;
    String? _inviteLink;
    String? _errorMessage;

    @override
    void initState() {
        super.initState();
        _generateLink();
    }

    Future<void> _generateLink() async {
        try {
            final api = ApiClient();
            final response = await api.post('/auth/generate-invite-link', {
                'gymId': widget.gymId,
                'role': 'alumno'
            });
            
            if (response != null && response['token'] != null) {
                final token = response['token']; 
                final fullLink = 'https://tugymflow.com/invite?token=$token'; 
                
                setState(() {
                    _inviteLink = fullLink;
                    _isLoading = false;
                });
            } else {
                 setState(() {
                    _errorMessage = 'Respuesta inválida del servidor';
                    _isLoading = false;
                });
            }
        } catch (e) {
            setState(() {
                _errorMessage = 'Error al generar link: $e';
                _isLoading = false;
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('Enlace de Invitación', textAlign: TextAlign.center),
            content: _isLoading 
                ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                : _errorMessage != null
                    ? Text(_errorMessage!, style: const TextStyle(color: Colors.red))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            const Text('Comparte este QR o enlace con tus alumnos para que se registren automáticamente a tu gimnasio.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
                            const SizedBox(height: 24),
                            // QR Code
                            Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(8),
                                child: QrImageView(
                                    data: _inviteLink!,
                                    version: QrVersions.auto,
                                    size: 200.0,
                                ),
                            ),
                            const SizedBox(height: 24),
                            // Copy Link button
                            ElevatedButton.icon(
                                onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _inviteLink!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Enlace copiado al portapapeles'), backgroundColor: Colors.green)
                                    );
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('Copiar Enlace'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                            ),
                        ],
                    ),
            actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                )
            ],
        );
    }
}
