import '../models/user_model.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

class UserService {
  final ApiClient _api = ApiClient();

  // Helper
  List<T> _parseList<T>(dynamic response, T Function(Map<String, dynamic>) fromJson) {
      if (response is List) {
          return response.map((json) => fromJson(json)).toList();
      }
      return [];
  }

  Future<List<User>> getUsers({String? role, String? gymId}) async {
    final uri = Uri(path: '/users', queryParameters: {
      if (role != null) 'role': role,
      if (gymId != null) 'gymId': gymId,
    });
    
    final response = await _api.get(uri.toString());
    return _parseList(response, (json) => User.fromJson(json));
  }

  Future<User?> createUser({
    required String email,
    String? password, // Made optional
    required String firstName,
    required String lastName,
    String? phone,
    int? age,
    String? gender,
    String? notes,
    required String role,
    String? gymId,
    String? professorId,
    String? membershipStartDate,
    double? initialWeight,
    bool paysMembership = true,
  }) async {
    final bodyData = {
        'email': email,
        if (password != null) 'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'age': age,
        'gender': gender,
        'notes': notes,
        'role': role,
        if (gymId != null) 'gymId': gymId,
        if (professorId != null) 'professorId': professorId,
        if (membershipStartDate != null) 'membershipStartDate': membershipStartDate,
        if (initialWeight != null) 'initialWeight': initialWeight,
        'paysMembership': paysMembership,
    };

    try {
        final response = await _api.post('/users', bodyData);
        return User.fromJson(response);
    } catch (_) {
        return null;
    }
  }

  Future<String?> deleteUser(String id) async {
    try {
      await _api.delete('/users/$id');
      return null;
    } on ApiException catch (e) {
      // Improve this mapping if needed
      if (e.statusCode == 409) return 'Usuario en uso';
      return e.message; 
    } catch (e) {
      return 'Error al eliminar usuario';
    }
  }

  // Uses Plan endpoint but kept here for compatibility
  Future<bool> assignPlan(String studentId, String planId) async {
    try {
        await _api.post('/plans/assign', {
            'studentId': studentId,
            'planId': planId,
        });
        return true;
    } catch (_) {
        return false;
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
     try {
       await _api.patch('/users/$id', data);
       return true;
     } catch (_) {
       return false;
     }
  }

  Future<User?> getProfile() async {
    try {
      final response = await _api.get('/users/profile');
      return User.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      await _api.patch('/users/profile', data);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<User?> markAsPaid(String userId) async {
    try {
       // Passing empty map as body
       final response = await _api.patch('/users/$userId/payment-status', {});
       return User.fromJson(response);
    } catch (_) {
       return null;
    }
  }
}
