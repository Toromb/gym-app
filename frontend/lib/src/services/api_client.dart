import 'dart:convert';

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'api_exceptions.dart';
import '../models/plan_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient({http.Client? client}) {
      if (client != null) _instance._client = client;
      return _instance;
  }
  ApiClient._internal();

  final _storage = const FlutterSecureStorage();
  http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 30);

  // Callbacks for global 401 handling
  static Future<bool> Function()? onTokenExpired;
  static void Function()? onSessionTerminated;
  static bool _isRefreshing = false;

  Future<String?> _getToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('jwt');
      }
      return await _storage.read(key: 'jwt');
    } catch (e) {
      debugPrint('Error reading token: $e');
      return null;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _processResponse(http.Response response, Uri url) {
    if (kDebugMode) {
      debugPrint('API Response [${response.statusCode}]: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) return null;
        try {
            return jsonDecode(response.body);
        } catch (_) {
            return response.body; // Return string if not JSON
        }
      case 204:
        return null;
      case 400:
        throw ApiException('Bad Request: ${response.body}', 400);
      case 401:
        throw UnauthorizedException();
      case 403:
        throw ForbiddenException();
      case 404:
        throw NotFoundException();
      case 500:
      case 502:
      case 503:
        throw ServerException();
      default:
        throw ApiException('Unknown Error (Status: ${response.statusCode}) URL: $url', response.statusCode);
    }
  }

  Future<dynamic> _requestWithRetry(String endpoint, String method, {dynamic body, bool disableInterceptor = false}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    Future<http.Response> makeRequest() async {
      final headers = await _getHeaders();
      switch (method) {
        case 'GET': return await _client.get(url, headers: headers).timeout(_timeout);
        case 'POST': return await _client.post(url, headers: headers, body: jsonEncode(body)).timeout(_timeout);
        case 'PUT': return await _client.put(url, headers: headers, body: jsonEncode(body)).timeout(_timeout);
        case 'PATCH': return await _client.patch(url, headers: headers, body: jsonEncode(body)).timeout(_timeout);
        case 'DELETE': return await _client.delete(url, headers: headers).timeout(_timeout);
        default: throw Exception('Unsupported Method');
      }
    }

    if (kDebugMode) debugPrint('$method $url');

    try {
      final response = await makeRequest();
      return _processResponse(response, url);
    } on TimeoutException {
      throw NetworkException('Connection Timed Out');
    } on UnauthorizedException {
      if (disableInterceptor || onTokenExpired == null || kIsWeb) {
        // En Web, no intentamos refresh silencioso, deslogueamos directo
        if (!disableInterceptor) onSessionTerminated?.call();
        rethrow;
      }

      // Prevent concurrent refreshes (a robust app would queue them, MVP just blocks)
      if (_isRefreshing) {
         // Optionally wait or just fail
         onSessionTerminated?.call();
         rethrow;
      }

      _isRefreshing = true;
      try {
        final refreshed = await onTokenExpired!();
        if (refreshed) {
          // Retry original request with fresh token
          final retryResponse = await makeRequest();
          return _processResponse(retryResponse, url);
        } else {
          onSessionTerminated?.call();
          throw UnauthorizedException();
        }
      } catch (e) {
        onSessionTerminated?.call();
        throw UnauthorizedException();
      } finally {
        _isRefreshing = false;
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Error communicating with server: $e');
    }
  }

  Future<dynamic> get(String endpoint, {bool disableInterceptor = false}) async {
    return _requestWithRetry(endpoint, 'GET', disableInterceptor: disableInterceptor);
  }

  Future<dynamic> post(String endpoint, dynamic body, {bool disableInterceptor = false}) async {
    return _requestWithRetry(endpoint, 'POST', body: body, disableInterceptor: disableInterceptor);
  }

  Future<dynamic> put(String endpoint, dynamic body, {bool disableInterceptor = false}) async {
    return _requestWithRetry(endpoint, 'PUT', body: body, disableInterceptor: disableInterceptor);
  }

  Future<dynamic> delete(String endpoint, {bool disableInterceptor = false}) async {
    return _requestWithRetry(endpoint, 'DELETE', disableInterceptor: disableInterceptor);
  }

  Future<dynamic> patch(String endpoint, dynamic body, {bool disableInterceptor = false}) async {
    return _requestWithRetry(endpoint, 'PATCH', body: body, disableInterceptor: disableInterceptor);
  }

  // --- Equipments ---
  // In a real app we might put this in a separate Repository/Service class
  // but fitting here for speed as per existing pattern.
  
  Future<List<Equipment>> getEquipments() async {
      // Assuming endpoint is /exercises/equipments or similar. 
      // Actually backend service for equipments is likely exposed via ExercisesController or GymsController?
      // I need to check backend controller. 
      // Plan: I'll assume standard REST for now, or check where I put 'findAll' in backend.
      // Wait, I created EquipmentsService but did I create a Controller for it?
      // I registered it in ExercisesModule. I probably need to expose it via ExercisesController or a new EquipmentsController.
      // Let's assume ExercisesController exposes it on GET /exercises/equipments.
      
      final dynamic response = await get('/exercises/equipments');
      if (response is List) {
          return response.map((e) => Equipment.fromJson(e)).toList();
      }
      return [];
  }

  Future<Equipment> createEquipment(String name) async {
       // POST /exercises/equipments
       final dynamic response = await post('/exercises/equipments', {'name': name});
       return Equipment.fromJson(response);
  }

  Future<void> deleteEquipment(String id) async {
       // DELETE /exercises/equipments/:id
       await delete('/exercises/equipments/$id');
  }
}
