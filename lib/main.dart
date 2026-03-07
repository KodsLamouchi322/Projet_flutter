import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/livre_controller.dart';
import 'controllers/emprunt_controller.dart';
import 'controllers/evenement_controller.dart';
import 'controllers/message_controller.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';
import 'views/auth/login_view.dart';
import 'views/home/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BibliothequeApp());
}

class BibliothequeApp extends StatelessWidget {
  const BibliothequeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => LivreController()),
        ChangeNotifierProvider(create: (_) => EmpruntController()),
        ChangeNotifierProvider(create: (_) => EvenementController()),
        ChangeNotifierProvider(create: (_) => MessageController()),
      ],
      child: MaterialApp(
        title: 'Bibliothèque de Quartier',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    switch (auth.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const _SplashScreen();

      case AuthStatus.authenticated:
        return const MainNavigation();

      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const MainNavigation();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.local_library,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bibliothèque',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'de Quartier',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}