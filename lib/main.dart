// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2) Initialize local notifications
  await NotificationService.init();

  // 3) Force a test notification on app start
  //await NotificationService.debugTestNotification();

  // 4) Run the app
  runApp(const CampusEventsApp());
}


class CampusEventsApp extends StatelessWidget {
  const CampusEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    // High-contrast, accessible color scheme
    const seed = Color(0xFF4C1D95); // deep purple
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    // Slightly larger, higher-contrast text
    final baseText = ThemeData.light().textTheme;
    final textTheme = baseText.copyWith(
      bodyLarge: baseText.bodyLarge?.copyWith(fontSize: 18),
      bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 16),
      bodySmall: baseText.bodySmall?.copyWith(
        fontSize: 14,
        color: Colors.black87,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    return MaterialApp(
      title: 'Campus Events',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        textTheme: textTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 48), // big tap targets
            textStyle: textTheme.labelLarge,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: textTheme.labelLarge,
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == null) {
            return const LoginPage();
          }
          return const HomePage();
        },
      ),
    );
  }
}
