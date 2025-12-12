import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'teacher/dashboard_screen.dart';
import 'student/student_home_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.role == 'admin') {
          return const AdminDashboardScreen();
        } else if (auth.role == 'profe') {
          return const TeacherDashboardScreen();
        } else {
          return const StudentHomeScreen();
        }
      },
    );
  }
}
