import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../models/gym_model.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class GymsProvider with ChangeNotifier {
  List<Gym> _gyms = [];
  bool _isLoading = false;
  String? _error;
  final _storage = const FlutterSecureStorage();

  List<Gym> get gyms => _gyms;
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

  Future<Gym?> fetchGym(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/gyms/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Gym.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load gym: ${response.body}');
      }
    } catch (e) {
      _error = 'Error fetching gym: $e';
      return null;
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
              // await fetchGyms(); // Only for SuperAdmin
          } else {
              throw Exception('Failed to create gym: ${response.body}');
          }
      } finally {
          _isLoading = false;
          notifyListeners();
      }
  }

  Future<Gym?> updateGym(String id, Gym gym) async {
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
                  'phone': gym.phone, // Added missing phone field
                  'email': gym.email,
                  'maxProfiles': gym.maxProfiles,
                  'status': gym.status,
                  'primaryColor': gym.primaryColor,
                  'secondaryColor': gym.secondaryColor,
                  'welcomeMessage': gym.welcomeMessage,
                  'openingHours': gym.openingHours,
                  'logoUrl': gym.logoUrl,
                  'paymentAlias': gym.paymentAlias,
                  'paymentCbu': gym.paymentCbu,
                  'paymentAccountName': gym.paymentAccountName,
                  'paymentBankName': gym.paymentBankName,
                  'paymentNotes': gym.paymentNotes,
              })
          );
          if (response.statusCode == 200) {
              final updatedGym = Gym.fromJson(json.decode(response.body));
              return updatedGym;
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
              // await fetchGyms(); // Only for SuperAdmin
          } else {
              throw Exception('Failed to delete gym: ${response.body}');
          }
      } finally {
          _isLoading = false;
          notifyListeners();
      }
  }

  Future<String?> uploadLogo(String gymId, XFile file) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/gyms/$gymId/logo'));
      request.headers['Authorization'] = 'Bearer $token';

      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      final mediaType = MediaType.parse(mimeType);

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
            'file', await file.readAsBytes(),
            filename: file.name,
            contentType: mediaType));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
            'file', file.path,
            contentType: mediaType));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        // await fetchGyms(); // Only for SuperAdmin
        return data['logoUrl'];
      } else {
        throw Exception('Failed to upload logo: ${response.body}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
