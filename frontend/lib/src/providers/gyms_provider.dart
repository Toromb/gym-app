import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Gym {
  final String id;
  final String businessName;
  final String address;
  final String? phone;
  final String? email;
  final String status;
  final int maxProfiles;

  Gym({
    required this.id,
    required this.businessName,
    required this.address,
    this.phone,
    this.email,
    required this.status,
    required this.maxProfiles,
  });

  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: json['id'],
      businessName: json['businessName'],
      address: json['address'],
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'active',
      maxProfiles: json['maxProfiles'] ?? 0,
    );
  }
}

class GymsProvider with ChangeNotifier {
  List<Gym> _gyms = [];
  bool _isLoading = false;
  String? _error;
  final _storage = const FlutterSecureStorage();

  List<Gym> get gyms => _gyms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt');
  }

  Future<void> fetchGyms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/gyms'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _gyms = data.map((json) => Gym.fromJson(json)).toList();
      } else {
        _error = 'Failed to load gyms: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _error = 'Error fetching gyms: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGym(Gym gym) async {
      _isLoading = true;
      notifyListeners();
      try {
          final token = await _getToken();
          if (token == null) throw Exception('No authentication token found');

          final response = await http.post(
              Uri.parse('$_baseUrl/gyms'),
              headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json'
              },
              body: json.encode({
                  'businessName': gym.businessName,
                  'address': gym.address,
                  'email': gym.email,
                  'maxProfiles': gym.maxProfiles,
                  'status': gym.status,
              })
          );
          if (response.statusCode == 201) {
              await fetchGyms(); // Refresh
          } else {
              throw Exception('Failed to create gym: ${response.body}');
          }
      } finally {
          _isLoading = false;
          notifyListeners();
      }
  }

  Future<void> updateGym(String id, Gym gym) async {
       _isLoading = true;
      notifyListeners();
      try {
          final token = await _getToken();
          if (token == null) throw Exception('No authentication token found');

          final response = await http.patch(
              Uri.parse('$_baseUrl/gyms/$id'),
              headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json'
              },
              body: json.encode({
                  'businessName': gym.businessName,
                  'address': gym.address,
                  'email': gym.email,
                  'maxProfiles': gym.maxProfiles,
                  'status': gym.status,
              })
          );
          if (response.statusCode == 200) {
              await fetchGyms(); // Refresh
          } else {
              throw Exception('Failed to update gym: ${response.body}');
          }
      } finally {
          _isLoading = false;
          notifyListeners();
      }
  }
  Future<void> deleteGym(String id) async {
       _isLoading = true;
      notifyListeners();
      try {
          final token = await _getToken();
          if (token == null) throw Exception('No authentication token found');

          final response = await http.delete(
              Uri.parse('$_baseUrl/gyms/$id'),
              headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json'
              },
          );
          if (response.statusCode == 200 || response.statusCode == 204) {
              await fetchGyms(); // Refresh
          } else {
              throw Exception('Failed to delete gym: ${response.body}');
          }
      } finally {
          _isLoading = false;
          notifyListeners();
      }
  }
}
