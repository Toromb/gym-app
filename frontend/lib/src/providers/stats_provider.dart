
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stats_model.dart';
import '../utils/constants.dart';
import '../services/stats_service.dart';

class StatsProvider with ChangeNotifier {
  PlatformStats? _stats;
  bool _isLoading = false;
  String? _error;
  final _storage = const FlutterSecureStorage();

  PlatformStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get _baseUrl => baseUrl;

  Future<String?> _getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt');
    }
    return await _storage.read(key: 'jwt');
  }

  Future<void> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _stats = PlatformStats.fromJson(data);
      } else {
        _error = 'Failed to load stats: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching stats: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Muscle Flow Integration ---
  final StatsService _statsService = StatsService();
  List<MuscleLoad> _myLoads = [];
  List<MuscleLoad> get myLoads => _myLoads;

  Future<void> fetchMyMuscleLoads({bool forceRefresh = false}) async {
    // Basic cache: if not empty and not forced, return.
    // Muscle load changes after workout, so we might want aggressive refresh
    // For now, simple check.
    if (_myLoads.isNotEmpty && !forceRefresh) return;
    
    // Do not set global _isLoading to true to avoid full screen blockers if not needed?
    // User might want to see spinner in the specific tab.
    // Let's use local loading or reuse _isLoading but be careful.
    _isLoading = true;
    notifyListeners();
    try {
      _myLoads = await _statsService.getMyMuscleLoads();
    } catch (e) {
      debugPrint('Error fetching muscle loads: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<MuscleLoad>> fetchStudentMuscleLoads(String studentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _statsService.getStudentMuscleLoads(studentId);
    } catch (e) {
       debugPrint('Error fetching student loads: $e');
       return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
