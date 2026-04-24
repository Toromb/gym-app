import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized application logger.
///
/// Usage:
///   AppLogger.d('Debug message');         // Debug (solo en debug mode)
///   AppLogger.i('Info message');          // Info
///   AppLogger.w('Warning message');       // Warning
///   AppLogger.e('Error', error: e);       // Error con excepción opcional
///
/// En release/profile build, los niveles debug e info quedan silenciados
/// automáticamente, evitando exponer información en producción.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    // En producción solo mostramos warnings y errores.
    // En debug mostramos todo con colores y stack trace.
    level: kDebugMode ? Level.debug : Level.warning,
    printer: PrettyPrinter(
      methodCount: 1,        // Líneas de stack trace a mostrar
      errorMethodCount: 5,   // Líneas de stack en errores
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  /// Mensaje de debug — solo visible en debug builds.
  static void d(String message) => _logger.d(message);

  /// Mensaje informativo.
  static void i(String message) => _logger.i(message);

  /// Advertencia — visible en debug y release.
  static void w(String message, {Object? error}) =>
      _logger.w(message, error: error);

  /// Error — siempre visible, con excepción y stack trace opcionales.
  static void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
