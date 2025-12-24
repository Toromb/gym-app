import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  List<User> _students = [];
  bool _isLoading = false;

  List<User> get students => _students;
  bool get isLoading => _isLoading;

  Map<String, String?> _lastFetchArgs = {};
  bool _isUsersLoaded = false;

  Future<void> fetchUsers({String? role, String? gymId, bool forceRefresh = false}) async {
    // Check if arguments changed
    final currentArgs = {'role': role, 'gymId': gymId};
    final argsChanged = _lastFetchArgs['role'] != role || _lastFetchArgs['gymId'] != gymId;

    if (_isUsersLoaded && !forceRefresh && !argsChanged && _students.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();
    try {
      _students = await _userService.getUsers(role: role, gymId: gymId);
      _isUsersLoaded = true;
      _lastFetchArgs = currentArgs;
    } catch (e) {
        print('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Alias for backward compatibility or clarity
  Future<void> fetchStudents({bool forceRefresh = false}) => fetchUsers(forceRefresh: forceRefresh);

  Future<bool> addUser({
    required String email,
    required String password,
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
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newUser = await _userService.createUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        age: age,
        gender: gender,
        notes: notes,
        role: role,
        gymId: gymId,
        professorId: professorId,
        membershipStartDate: membershipStartDate,
        initialWeight: initialWeight,
      );
      if (newUser != null) {
        _students.add(newUser); // This list might be misnamed if it holds all users, but legacy variable name
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding user: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper for adding students (defaults role to alumno)
  Future<bool> addStudent({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    int? age,
    String? gender,
    String? notes,
    String? membershipStartDate,
    double? initialWeight,
  }) {
    return addUser(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      age: age,
      gender: gender,
      notes: notes,
      membershipStartDate: membershipStartDate,
      role: UserRoles.alumno,
      initialWeight: initialWeight,
    );
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _userService.updateUser(id, data);
      if (success) {
        // Optimistically update local list if needed, or just refresh
        // For simplicity, just return true and let UI refresh
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteUser(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final error = await _userService.deleteUser(id);
      if (error == null) {
        _students.removeWhere((user) => user.id == id);
        notifyListeners();
        return null; // Success
      }
      return error; // Failure message
    } catch (e) {
      print('Error deleting user: $e');
      return 'Error de conexión o excepción: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markUserAsPaid(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updatedUser = await _userService.markAsPaid(userId);
      if (updatedUser != null) {
        final index = _students.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _students[index] = updatedUser;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking as paid: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  void clear() {
    _students = [];
    _isLoading = false;
    _isUsersLoaded = false;
    _lastFetchArgs = {};
    notifyListeners();
  }
}
