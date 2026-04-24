import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/constrained_app_bar.dart';
import '../../widgets/payment_status_badge.dart';
import 'payment_history_screen.dart';
import 'edit_user_screen.dart';

class CollectionDashboardScreen extends StatefulWidget {
  const CollectionDashboardScreen({super.key});

  @override
  State<CollectionDashboardScreen> createState() =>
      _CollectionDashboardScreenState();
}

class _CollectionDashboardScreenState
    extends State<CollectionDashboardScreen> {
  // Estado: 'all', 'overdue', 'pending', 'paid'
  String _statusFilter = 'all';
  // Rol:    'all', 'alumno', 'profe'
  String _roleFilter = 'all';
  // Búsqueda por nombre / email
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers(forceRefresh: true);
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers de formato
  // ─────────────────────────────────────────────────────────────────
  static String _fmtDate(String? isoDate) {
    if (isoDate == null) return '—';
    final raw = isoDate.split('T')[0];
    final parts = raw.split('-');
    if (parts.length < 3) return raw;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: ConstrainedAppBar(
        title: const Text('Cobranza'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () =>
                context.read<UserProvider>().fetchUsers(forceRefresh: true),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Aplicar filtro de rol ──────────────────────────────
          // Los que pagan membresía (alumnos normalmente, pero pueden
          // existir profes con membresía también).
          final allByRole = provider.students.where((u) {
            if (_roleFilter == 'alumno') return u.role == UserRoles.alumno;
            if (_roleFilter == 'profe') return u.role == UserRoles.profe;
            return u.role == UserRoles.alumno || u.role == UserRoles.profe;
          }).where((u) => u.paysMembership ?? true).where((u) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return ('${u.firstName} ${u.lastName}').toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q);
          }).toList();

          // ── Contadores por estado (siempre sobre el rol filtrado) ──
          final paid = allByRole.where((u) => u.paymentStatus == 'paid').toList();
          final pending = allByRole.where((u) => u.paymentStatus == 'pending').toList();
          final overdue = allByRole.where((u) => u.paymentStatus == 'overdue').toList();

          // ── Aplicar filtro de estado ───────────────────────────
          List<User> filtered;
          switch (_statusFilter) {
            case 'paid':
              filtered = paid;
              break;
            case 'pending':
              filtered = pending;
              break;
            case 'overdue':
              filtered = overdue;
              break;
            default:
              filtered = allByRole;
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Resumen ──────────────────────────────────────
                  Text(
                    'RESUMEN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSummaryCard(
                        context,
                        label: 'Al día',
                        count: paid.length,
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                        filterValue: 'paid',
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        context,
                        label: 'Por vencer',
                        count: pending.length,
                        color: Colors.orange,
                        icon: Icons.access_time,
                        filterValue: 'pending',
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryCard(
                        context,
                        label: 'Vencidos',
                        count: overdue.length,
                        color: Colors.red,
                        icon: Icons.warning_amber_outlined,
                        filterValue: 'overdue',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Buscador ──────────────────────────────────────
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o email...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 20),

                  // ── Filtro de rol ─────────────────────────────────
                  Text(
                    'TIPO DE USUARIO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _roleChip(context, 'Todos', 'all', Icons.people_outline),
                        const SizedBox(width: 8),
                        _roleChip(context, 'Alumnos', UserRoles.alumno,
                            Icons.school_outlined),
                        const SizedBox(width: 8),
                        _roleChip(context, 'Profesores', UserRoles.profe,
                            Icons.fitness_center_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Filtro de estado ──────────────────────────────
                  Text(
                    'ESTADO DE CUOTA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statusChip('Todos', 'all', allByRole.length,
                            colorScheme.primary),
                        const SizedBox(width: 8),
                        _statusChip(
                            'Vencidos', 'overdue', overdue.length, Colors.red),
                        const SizedBox(width: 8),
                        _statusChip('Por vencer', 'pending', pending.length,
                            Colors.orange),
                        const SizedBox(width: 8),
                        _statusChip(
                            'Al día', 'paid', paid.length, Colors.green),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Lista ─────────────────────────────────────────
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Text(
                          'Sin usuarios en este estado',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filtered.map((u) => _buildUserTile(context, u)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Widgets auxiliares
  // ─────────────────────────────────────────────────────────────────

  Widget _buildSummaryCard(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required String filterValue,
  }) {
    final isSelected = _statusFilter == filterValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _statusFilter = isSelected ? 'all' : filterValue;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(
      BuildContext context, String label, String value, IconData icon) {
    final isSelected = _roleFilter == value;
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      avatar: Icon(icon,
          size: 16,
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
      label: Text(label),
      selected: isSelected,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.transparent),
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.primary : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _roleFilter = value),
    );
  }

  Widget _statusChip(String label, String value, int count, Color color) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: isSelected ? color : Colors.transparent),
      labelStyle: TextStyle(
        color: isSelected ? color : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Widget _buildUserTile(BuildContext context, User user) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAlumno = user.role == UserRoles.alumno;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────
            CircleAvatar(
              backgroundColor: isAlumno
                  ? colorScheme.primaryContainer
                  : colorScheme.tertiaryContainer,
              child: Text(
                '${user.firstName[0]}${user.lastName[0]}'.toUpperCase(),
                style: TextStyle(
                  color: isAlumno
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Chip de rol
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAlumno
                              ? colorScheme.primaryContainer
                              : colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAlumno ? 'Alumno' : 'Profesor',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isAlumno
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Fecha de inicio
                  Row(
                    children: [
                      Icon(Icons.play_circle_outline,
                          size: 12, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Inicio: ${_fmtDate(user.membershipStartDate)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.event_outlined,
                          size: 12, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Vence: ${_fmtDate(user.membershipExpirationDate)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Acciones ─────────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Badge de estado + registrar pago
                PaymentStatusBadge(
                  status: user.paymentStatus,
                  isEditable: true,
                  userId: user.id,
                  onRegisterPayment: (amount, method, notes, months) async {
                    final success =
                        await context.read<UserProvider>().registerPayment(
                              user.id,
                              amount: amount,
                              method: method,
                              notes: notes,
                              periodMonths: months,
                            );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? '✅ Pago registrado correctamente'
                              : '❌ Error al registrar el pago'),
                          backgroundColor:
                              success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 4),
                // Botones: editar + historial
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: Icon(Icons.edit_outlined,
                            color: colorScheme.onSurfaceVariant),
                        tooltip: 'Editar usuario',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditUserScreen(user: user),
                            ),
                          );
                          // Refrescar después de editar
                          if (context.mounted) {
                            context
                                .read<UserProvider>()
                                .fetchUsers(forceRefresh: true);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: Icon(Icons.history,
                            color: colorScheme.primary),
                        tooltip: 'Historial de pagos',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentHistoryScreen(
                              userId: user.id,
                              userName:
                                  '${user.firstName} ${user.lastName}',
                              membershipStartDate: user.membershipStartDate,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
