import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/gym_schedule_model.dart';
import '../utils/constants.dart';

class GymScheduleProvider with ChangeNotifier {
  List<GymSchedule> _schedules = [];
  bool _isLoading = false;
  String? _error;

  List<GymSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? _authToken;

  GymScheduleProvider(this._authToken);

  void update(String? token) {
    _authToken = token;
  }

  Future<void> fetchSchedule() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Fetching schedule from: $baseUrl/gym-schedule');
      final response = await http.get(
        Uri.parse('$baseUrl/gym-schedule'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );
      print('Schedule response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _schedules = data.map((json) => GymSchedule.fromJson(json)).toList();
        print('Parsed ${_schedules.length} schedules');
      } else {
        _error = 'Failed to load schedule: ${response.statusCode}';
        print(_error);
      }
    } catch (e) {
      _error = 'Error loading schedule: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSchedule(List<GymSchedule> updatedSchedules) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/gym-schedule'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedSchedules.map((s) => s.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _schedules = data.map((json) => GymSchedule.fromJson(json)).toList();
        return true;
      } else {
        _error = 'Failed to update schedule: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _error = 'Error updating schedule: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
