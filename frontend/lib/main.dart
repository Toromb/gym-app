import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/user_provider.dart';
import 'src/providers/plan_provider.dart';
import 'src/providers/exercise_provider.dart';
import 'src/providers/gym_schedule_provider.dart';
import 'src/providers/gyms_provider.dart';
import 'src/providers/stats_provider.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (context) => GymScheduleProvider(context.read<AuthProvider>().token)),
        ChangeNotifierProvider(create: (_) => GymsProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
