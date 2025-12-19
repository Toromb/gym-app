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
import 'src/theme/app_theme.dart';

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
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Resolve colors dynamically
        Color primaryColor = AppColors.primary;
        Color secondaryColor = AppColors.primary; // Default to primary if not set

        if (auth.user?.gym?.primaryColor != null) {
           try {
             String hex = auth.user!.gym!.primaryColor!.replaceAll('#', '');
             if (hex.length == 6) hex = 'FF$hex';
             primaryColor = Color(int.parse(hex, radix: 16));
           } catch (_) {}
        }
        
         if (auth.user?.gym?.secondaryColor != null) {
           try {
             String hex = auth.user!.gym!.secondaryColor!.replaceAll('#', '');
             if (hex.length == 6) hex = 'FF$hex';
             secondaryColor = Color(int.parse(hex, radix: 16));
           } catch (_) {}
        }

        return MaterialApp(
          title: 'GymFlow',
          theme: AppTheme.createTheme(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', ''),
            Locale('en', ''),
          ],
          locale: const Locale('es', ''),
          home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}
