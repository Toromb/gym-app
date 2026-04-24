import 'package:flutter/material.dart';
import '../../models/payment_record_model.dart';
import '../../services/payment_service.dart';
import '../../widgets/constrained_app_bar.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? membershipStartDate;

  const PaymentHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.membershipStartDate,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late Future<List<PaymentRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _load();
  }

  Future<List<PaymentRecord>> _load() =>
      PaymentService().getPaymentHistory(widget.userId);

  void _refresh() => setState(() {
        _historyFuture = _load();
      });


  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: ConstrainedAppBar(
        title: Text(
          'Pagos – ${widget.userName}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _refresh,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: RefreshIndicator(
            onRefresh: () async {
              final f = _load();
              setState(() => _historyFuture = f);
              await f;
            },
            child: FutureBuilder<List<PaymentRecord>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                // ── Cargando ──
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // ── Error ──
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off,
                              size: 48,
                              color: colorScheme.error.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar el historial',
                            style: textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.error),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: _refresh,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final records = snapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── Cabecera del alumno ───────────────────────
                    _buildHeader(context, records),
                    const SizedBox(height: 24),

                    // ── Historial ─────────────────────────────────
                    Text(
                      'HISTORIAL DE PAGOS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (records.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sin pagos registrados',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...records.map((r) => _buildRecordCard(context, r)),

                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Cabecera con info del usuario
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, List<PaymentRecord> records) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Último pago
    String lastPaymentLabel = 'Sin pagos registrados';
    if (records.isNotEmpty) {
      try {
        final local = records.first.paidAt.toLocal();
        lastPaymentLabel =
            '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
      } catch (_) {}
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _summaryRow(
              context,
              Icons.play_circle_outline,
              'Alta / Inicio',
              _fmtDate(widget.membershipStartDate),
            ),
            const SizedBox(height: 4),
            _summaryRow(
              context,
              Icons.receipt_long_outlined,
              'Pagos registrados',
              '${records.length}',
            ),
            const SizedBox(height: 4),
            _summaryRow(
              context,
              Icons.calendar_today_outlined,
              'Último pago',
              lastPaymentLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
      BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
              fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Card de un registro de pago
  // ─────────────────────────────────────────────────────────────────
  Widget _buildRecordCard(BuildContext context, PaymentRecord record) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Fecha de registro
    String paidAtLabel = '';
    try {
      final local = record.paidAt.toLocal();
      paidAtLabel =
          '${local.day.toString().padLeft(2, '0')} ${_monthName(local.month)} ${local.year}  ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      paidAtLabel = record.paidAt.toString();
    }

    // Ícono de método
    IconData methodIcon;
    switch (record.method?.toLowerCase()) {
      case 'transferencia':
        methodIcon = Icons.account_balance_wallet_outlined;
        break;
      case 'efectivo':
        methodIcon = Icons.payments_outlined;
        break;
      default:
        methodIcon = Icons.payment_outlined;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha del registro
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  paidAtLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Período
            _infoRow(context, Icons.date_range, 'Período',
                record.periodLabel),

            // Monto
            if (record.amount != null)
              _infoRow(context, Icons.attach_money, 'Monto',
                  '\$${record.amount!.toStringAsFixed(0)}'),

            // Método
            if (record.method != null)
              _infoRow(context, methodIcon, 'Método',
                  _capitalize(record.method!)),

            // Admin
            if (record.registeredByName != null)
              _infoRow(context, Icons.admin_panel_settings_outlined,
                  'Registrado por', record.registeredByName!),

            // Nota
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.notes!,
                  style: textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers estáticos
  // ─────────────────────────────────────────────────────────────────
  static String _fmtDate(String? isoDate) {
    if (isoDate == null) return '—';
    final raw = isoDate.split('T')[0];
    final parts = raw.split('-');
    if (parts.length < 3) return raw;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static String _monthName(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return months[month - 1];
  }
}
