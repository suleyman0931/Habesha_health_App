import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/welcome_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/meal_screen.dart';
import 'screens/exercise_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'localization/app_localizations.dart';
import 'utils/storage.dart';
import 'utils/notification_service.dart';
import 'utils/step_tracker.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestActivityRecognitionPermission() async {
  if (await Permission.activityRecognition.isDenied) {
    await Permission.activityRecognition.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request activity recognition permission
  await requestActivityRecognitionPermission();

  // Initialize services in parallel
  await Future.wait([
    NotificationService.initialize(),
    StepTracker.initialize(),
  ]);

  // Load preferences and user data
  final themeMode = await Storage.getThemeMode();
  final locale = await Storage.getLocale();
  final user = await Storage.getUser();

  // Run the app
  runApp(
    HabeshaHealthApp(
      initialThemeMode: themeMode,
      initialLocale: locale,
      initialRoute: user != null ? '/dashboard' : '/welcome',
    ),
  );
}

class HabeshaHealthApp extends StatefulWidget {
  final String initialThemeMode;
  final Locale initialLocale;
  final String initialRoute;

  const HabeshaHealthApp({
    Key? key,
    required this.initialThemeMode,
    required this.initialLocale,
    required this.initialRoute,
  }) : super(key: key);

  @override
  _HabeshaHealthAppState createState() => _HabeshaHealthAppState();

  static _HabeshaHealthAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_HabeshaHealthAppState>();
}

class _HabeshaHealthAppState extends State<HabeshaHealthApp>
    with WidgetsBindingObserver {
  late String _themeMode;
  late Locale _locale;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _locale = widget.initialLocale;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void setThemeMode(String mode) {
    if (_themeMode != mode) {
      setState(() {
        _themeMode = mode;
      });
      Storage.saveThemeMode(mode);
    }
  }

  void setLocale(Locale locale) {
    if (_locale != locale) {
      setState(() {
        _locale = locale;
      });
      Storage.saveLocale(locale);
    }
  }

  String get themeMode => _themeMode;
  Locale get locale => _locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habesha Health',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF8B4513),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        textTheme: ThemeData.light().textTheme,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8B4513),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: ThemeData.dark().textTheme,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      themeMode: _themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
      locale: _locale,
      supportedLocales: const [Locale('en', ''), Locale('am', '')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: widget.initialRoute,
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/register': (context) => RegisterScreen(),
        '/profile': (context) => ProfileScreen(),
        '/meal': (context) => MealScreen(),
        '/exercise': (context) => ExerciseScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/settings': (context) => SettingsScreen(),
      },
      navigatorObservers: [routeObserver],
    );
  }
}
