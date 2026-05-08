import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../models/gym_model.dart';
import '../services/api_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class GymsProvider with ChangeNotifier {
  List<Gym> _gyms = [];
  bool _isLoading = false;
  String? _error;

  // Solo necesario para uploads multipart (ApiClient no abstrae multipart aún)
  final _storage = const FlutterSecureStorage();

  List<Gym> get gyms => _gyms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _api = ApiClient();

  // Token para uploads multipart (única razón para acceder al storage directamente)
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
      final data = await _api.get('/gyms');
      _gyms =
          (data as List<dynamic>).map((json) => Gym.fromJson(json)).toList();
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
      final data = await _api.get('/gyms/$id');
      return Gym.fromJson(data);
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
      final data = await _api.post('/gyms', {
        'businessName': gym.businessName,
        'address': gym.address,
        'email': gym.email,
        'maxProfiles': gym.maxProfiles,
        'status': gym.status,
      });
      final newGym = Gym.fromJson(data);
      _gyms.add(newGym);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Gym?> updateGym(String id, Gym gym) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.patch('/gyms/$id', {
        'businessName': gym.businessName,
        'address': gym.address,
        'phone': gym.phone,
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
        'whatsapp': gym.whatsapp,
        'instagram': gym.instagram,
        'facebook': gym.facebook,
      });
      final updatedGym = Gym.fromJson(data);
      final index = _gyms.indexWhere((g) => g.id == id);
      if (index != -1) {
        _gyms[index] = updatedGym;
        notifyListeners();
      }
      return updatedGym;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGym(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.delete('/gyms/$id');
      _gyms.removeWhere((g) => g.id == id);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Uploads multipart ──────────────────────────────────────────────────────
  // ApiClient no abstrae multipart, así que los uploads usan http directo.
  // El token se obtiene del mismo storage que ApiClient.

  Future<String?> uploadLogo(String gymId, XFile file) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/gyms/$gymId/logo'));
      request.headers['Authorization'] = 'Bearer $token';

      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      final mediaType = MediaType.parse(mimeType);

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
            'file', await file.readAsBytes(),
            filename: file.name, contentType: mediaType));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', file.path,
            contentType: mediaType));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['logoUrl'];
      } else {
        throw Exception('Failed to upload logo: ${response.body}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadBackgroundImage(String gymId, XFile file) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/gyms/$gymId/background'));
      request.headers['Authorization'] = 'Bearer $token';

      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      final mediaType = MediaType.parse(mimeType);

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
            'file', await file.readAsBytes(),
            filename: file.name, contentType: mediaType));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', file.path,
            contentType: mediaType));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['backgroundImageUrl'] as String?;
      } else {
        throw Exception('Failed to upload background: ${response.body}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
