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
import 'src/utils/app_colors.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/localization/app_localizations.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProxyProvider<AuthProvider, GymScheduleProvider>(
          create: (_) => GymScheduleProvider(null),
          update: (_, auth, prev) => prev!..update(auth.token),
        ),
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
      title: 'GymFlow', // Updated Name
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.lightScheme,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textMain,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          elevation: 2,
        ),
        textTheme: const TextTheme(
           bodyMedium: TextStyle(color: AppColors.textMain),
           bodySmall: TextStyle(color: AppColors.textSoft),
        ),

      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Spanish, no country code
        Locale('en', ''), // English
      ],
      locale: const Locale('es', ''), // Force Spanish for now
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
