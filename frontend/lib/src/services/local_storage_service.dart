import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_logger.dart';

class LocalStorageService {
  static const String _sessionBoxName = 'session_cache';
  static const String _queueBoxName = 'sync_queue';

  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Box? _sessionBox;
  Box? _queueBox;

  Future<void> init() async {
    _sessionBox = await Hive.openBox(_sessionBoxName);
    _queueBox = await Hive.openBox(_queueBoxName);
    AppLogger.d('📦 Hive Boxes Opened: $_sessionBoxName, $_queueBoxName');
  }

  // --- Session Cache ---

  Future<void> saveSession(Map<String, dynamic> sessionJson) async {
    await _sessionBox?.put('active_session', jsonEncode(sessionJson));
    AppLogger.d('📦 Session Cached');
  }

  Map<String, dynamic>? getSession() {
    final String? jsonStr = _sessionBox?.get('active_session');
    if (jsonStr == null) return null;
    return jsonDecode(jsonStr);
  }

  Future<void> clearSession() async {
    await _sessionBox?.delete('active_session');
    AppLogger.d('📦 Session Cache Cleared');
  }

  // --- Sync Queue ---

  Future<void> addToQueue(Map<String, dynamic> request) async {
    // request: { 'id': uuid, 'method': 'POST', 'url': '...', 'body': {...}, 'timestamp': ... }
    await _queueBox?.add(jsonEncode(request));
    AppLogger.d(
        '📦 Added to Sync Queue: ${request["method"]} ${request["url"]}');
  }

  List<Map<String, dynamic>> getQueue() {
    if (_queueBox == null) return [];
    return _queueBox!.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  Future<void> removeFromQueue(int index) async {
    await _queueBox?.deleteAt(index);
    AppLogger.d('📦 Removed from Queue at index $index');
  }

  Future<void> clearQueue() async {
    await _queueBox?.clear();
  }
}
