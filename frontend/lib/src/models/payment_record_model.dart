class PaymentRecord {
  final String id;
  final double? amount;
  final String? method;
  final String? notes;
  final String periodFrom; // 'YYYY-MM-DD'
  final String periodTo; // 'YYYY-MM-DD'
  final DateTime paidAt;
  final String? registeredByName; // "Nombre Apellido" del admin

  PaymentRecord({
    required this.id,
    this.amount,
    this.method,
    this.notes,
    required this.periodFrom,
    required this.periodTo,
    required this.paidAt,
    this.registeredByName,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    String? adminName;
    if (json['registeredBy'] != null) {
      final rb = json['registeredBy'] as Map<String, dynamic>;
      adminName =
          '${rb['firstName'] ?? ''} ${rb['lastName'] ?? ''}'.trim();
    }

    return PaymentRecord(
      id: json['id'] as String,
      amount: json['amount'] != null
          ? double.parse(json['amount'].toString())
          : null,

      method: json['method'] as String?,
      notes: json['notes'] as String?,
      periodFrom: json['periodFrom'] as String,
      periodTo: json['periodTo'] as String,
      paidAt: DateTime.parse(json['paidAt'] as String),
      registeredByName: adminName,
    );
  }

  /// Formatted period string e.g. "12 Abr → 12 May"
  String get periodLabel {
    final from = _formatDate(periodFrom);
    final to = _formatDate(periodTo);
    return '$from → $to';
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
