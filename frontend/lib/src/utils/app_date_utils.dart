/// Utilidades de fecha para la app.
///
/// Centraliza el formateo de fechas para enviar/recibir de la API,
/// eliminando el patrón repetido:
///   "${now.year}-${now.month.toString().padLeft(2, '0')}-..."
///
/// No depende de 'intl' para evitar una dependencia extra.
/// Si en el futuro se agrega 'intl', reemplazar las implementaciones
/// por DateFormat('yyyy-MM-dd').format(date).
class AppDateUtils {
  AppDateUtils._(); // No instanciable

  /// Formatea una [DateTime] como 'yyyy-MM-dd' para enviar a la API.
  ///
  /// ```dart
  /// // Antes:
  /// final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  ///
  /// // Después:
  /// final dateStr = AppDateUtils.toIsoDate(now);
  /// ```
  static String toIsoDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parsea un string 'yyyy-MM-dd' de la API a [DateTime].
  static DateTime fromIsoDate(String date) => DateTime.parse(date);

  /// Devuelve el rango de la semana actual (lunes a domingo).
  /// Útil para el calendario y stats semanales.
  static ({DateTime start, DateTime end}) currentWeekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return (start: start, end: end);
  }
}
