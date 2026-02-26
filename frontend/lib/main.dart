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
import 'src/screens/public/support_screen.dart';
import 'src/screens/public/terms_screen.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'src/services/local_storage_service.dart';
import 'src/services/local_storage_service.dart';
import 'src/services/sync_service.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await Hive.initFlutter();
  await LocalStorageService().init();
  SyncService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
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
          debugShowCheckedModeBanner: false,
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
          initialRoute: '/',
          onGenerateRoute: (settings) {
            
            final uri = Uri.parse(settings.name ?? '/');
            final queryParams = uri.queryParameters;
            
            // 0. Handle Invite Link Deep Link (e.g. gymflow://invite?token=XYZ)
            if (uri.path == '/invite' || uri.path.contains('invite')) {
               final token = queryParams['token'];
               if (token != null) {
                 // Push to LoginScreen but pass the token to trigger invite flow
                 return MaterialPageRoute(
                   builder: (_) => LoginScreen(queryParams: {'token': token}),
                 );
               }
            }

            // 1. Handle Activation/Reset (Public)
            if (uri.path == '/activate-account' || uri.path.contains('activate-account')) {
              final token = queryParams['token'];
              return MaterialPageRoute(
                builder: (_) => ActivateAccountScreen(token: token, mode: 'activate'),
              );
            }
            
            if (uri.path == '/reset-password' || uri.path.contains('reset-password')) {
              final token = queryParams['token'];
              return MaterialPageRoute(
                builder: (_) => ActivateAccountScreen(token: token, mode: 'reset'),
              );
            }

            if (uri.path == '/soporte') {
               return MaterialPageRoute(builder: (_) => const SupportScreen());
            }

            if (uri.path == '/terminos') {
               return MaterialPageRoute(builder: (_) => const TermsScreen());
            }

            // 2. Handle Root / Login (Auth Guarded)
            // If path is / or /login, we apply the auth check logic
            if (uri.path == '/' || uri.path == '/login') {
               return MaterialPageRoute(
                 builder: (_) {
                    if (auth.status == AuthStatus.loading || auth.status == AuthStatus.unknown) {
                       return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    if (auth.isAuthenticated) {
                       return const HomeScreen();
                    }
                    return const LoginScreen();
                 }
               );
            }

            // Default fallback
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          },
        );
      },
    );
  }
}

// DeepLinkHandler Widget to wrap MaterialApp and listen for links
class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const DeepLinkHandler({super.key, required this.child});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Handle initial URI (app opened from closed state)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to handle initial deep link: $e");
    }

    // 2. Handle incoming links while app is open/background
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Error listening to deep links: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("Deep link received: $uri");
    // Depending on routing, you might need a GlobalKey<NavigatorState>
    // to push a route dynamically, or if your routing reads initialRoute correctly
    // it will be picked up by onGenerateRoute if passed correctly.
    // For simplicity with MaterialApp's default navigation flow, if we are inside
    // context, we could try:
    // Navigator.of(context).pushNamed(uri.toString());
    // However, since we wrap the MaterialApp or are inside it, we will use a global key
    // or rely on standard path-based routing if web.
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
