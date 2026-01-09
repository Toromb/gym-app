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
import 'src/providers/theme_provider.dart';

import 'src/screens/public/activate_account_screen.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'src/services/local_storage_service.dart';
import 'src/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalStorageService().init();
  SyncService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PlanProvider>(
          create: (_) => PlanProvider(),
          update: (_, auth, prev) {
            if (!auth.isAuthenticated) prev?.clear();
            return prev!;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ExerciseProvider>(
          create: (_) => ExerciseProvider(),
          update: (_, auth, prev) {
             if (!auth.isAuthenticated) prev?.clear();
             return prev!;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, GymScheduleProvider>(
          create: (_) => GymScheduleProvider(null),
          update: (_, auth, prev) => prev!..update(auth.token),
        ),
        ChangeNotifierProvider(create: (_) => GymsProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>( 
      builder: (context, auth, themeProvider, _) {
         // Sync User ID safely
         WidgetsBinding.instance.addPostFrameCallback((_) {
            if (auth.user?.id != null) {
              themeProvider.setUserId(auth.user!.id);
            } else {
              themeProvider.setUserId(null); 
            }
         });

        // Resolve colors dynamically
        Color primaryColor = AppColors.primary;
        Color secondaryColor = AppColors.primary;

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
          themeMode: themeProvider.themeMode, 
          theme: AppTheme.createTheme(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            brightness: Brightness.light,
          ),
          darkTheme: AppTheme.createTheme(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            brightness: Brightness.dark,
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
          builder: (context, child) {
            return GestureDetector(
              onTap: () {
                // Dismiss keyboard and unfocus globally
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: child!,
            );
          },
          home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
          onGenerateRoute: (settings) {
            // Handle /activate-account?token=...
            // Handle /reset-password?token=...
            final uri = Uri.parse(settings.name ?? '');
            
            if (uri.path == '/activate-account') {
              final token = uri.queryParameters['token'];
              return MaterialPageRoute(
                builder: (_) => ActivateAccountScreen(token: token, mode: 'activate'),
              );
            }
            
            if (uri.path == '/reset-password') {
              final token = uri.queryParameters['token'];
              return MaterialPageRoute(
                builder: (_) => ActivateAccountScreen(token: token, mode: 'reset'),
              );
            }

            if (uri.path == '/login') {
               return MaterialPageRoute(builder: (_) => const LoginScreen());
            }

            return null; // Let home take precedence or default
          },
        );
      },
    );
  }
}
