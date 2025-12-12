import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  List<User> _students = [];
  bool _isLoading = false;

  List<User> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _students = await _userService.getUsers();
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Alias for backward compatibility or clarity
  Future<void> fetchStudents() => fetchUsers();

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
      );
      if (newUser != null) {
        _students.add(newUser);
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
      role: 'alumno',
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

  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _userService.deleteUser(id);
      if (success) {
        _students.removeWhere((user) => user.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
