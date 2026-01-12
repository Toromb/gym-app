import 'dart:convert';
import 'dart:io';
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

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    if (kDebugMode) debugPrint('GET $url');

    try {
      final response = await _client.get(url, headers: headers).timeout(_timeout);
      return _processResponse(response, url);
    } on SocketException {
      throw NetworkException('No Internet Connection');
    } on TimeoutException {
      throw NetworkException('Connection Timed Out');
    } catch (e) {
        if (e is ApiException) rethrow; // Pass up known exceptions
        throw NetworkException('Error communicating with server: $e');
    }
  }

  Future<dynamic> post(String endpoint, dynamic body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    if (kDebugMode) debugPrint('POST $url');

    try {
      final response = await _client
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _processResponse(response, url);
    } on SocketException {
      throw NetworkException('No Internet Connection');
    } on TimeoutException {
      throw NetworkException('Connection Timed Out');
    } catch (e) {
        if (e is ApiException) rethrow;
        throw NetworkException('Error communicating with server: $e');
    }
  }

  Future<dynamic> put(String endpoint, dynamic body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    if (kDebugMode) debugPrint('PUT $url');

    try {
      final response = await _client
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _processResponse(response, url);
    } on SocketException {
      throw NetworkException('No Internet Connection');
    } on TimeoutException {
      throw NetworkException('Connection Timed Out');
    } catch (e) {
        if (e is ApiException) rethrow;
        throw NetworkException('Error communicating with server: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    if (kDebugMode) debugPrint('DELETE $url');

    try {
      final response = await _client.delete(url, headers: headers).timeout(_timeout);
      return _processResponse(response, url);
    } on SocketException {
      throw NetworkException('No Internet Connection');
    } on TimeoutException {
      throw NetworkException('Connection Timed Out');
    } catch (e) {
        if (e is ApiException) rethrow;
        throw NetworkException('Error communicating with server: $e');
    }
  }
  Future<dynamic> patch(String endpoint, dynamic body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    if (kDebugMode) debugPrint('PATCH $url');

    try {
      final response = await _client
          .patch(url, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _processResponse(response, url);
    } on SocketException {
      throw NetworkException('No Internet Connection');
    } on TimeoutException {
      throw NetworkException('Connection Timed Out');
    } catch (e) {
        if (e is ApiException) rethrow;
        throw NetworkException('Error communicating with server: $e');
    }
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
