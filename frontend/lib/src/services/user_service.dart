import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class UserService {
  final _storage = const FlutterSecureStorage();

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt');
  }

  Future<List<User>> getUsers() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<User?> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    int? age,
    String? gender,
    String? notes,
    required String role,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'age': age,
        'gender': gender,
        'notes': notes,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deleteUser(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> assignPlan(String studentId, String planId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/plans/assign'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'studentId': studentId,
        'planId': planId,
      }),
    );

    return response.statusCode == 201;
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }
  Future<User?> getProfile() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/users/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }
}
