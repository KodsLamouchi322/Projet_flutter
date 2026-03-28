import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/club_controller.dart';
import 'controllers/emprunt_controller.dart';
import 'controllers/evenement_controller.dart';
import 'controllers/livre_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/message_controller.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'services/cache_service.dart';
import 'services/local_notification_service.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';
import 'widgets/app_logo.dart';
import 'views/home/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('en_US', null);

  final localeCtrl = LocaleController();
  await localeCtrl.load();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await LocalNotificationService().initialize();
  NotificationService().initialize();

  await CacheService.initialize();
  runApp(BibliothequeApp(localeController: localeCtrl));
}

class BibliothequeApp extends StatelessWidget {
  final LocaleController localeController;

  const BibliothequeApp({super.key, required this.localeController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => LivreController()),
        ChangeNotifierProvider(create: (_) => EmpruntController()),
        ChangeNotifierProvider(create: (_) => EvenementController()),
        ChangeNotifierProvider(create: (_) => MessageController()),
        ChangeNotifierProvider(create: (_) => ClubController()),
      ],
      child: Consumer<LocaleController>(
        builder: (context, loc, _) {
          return MaterialApp(
            title: 'BiblioX',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: loc.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const _AppRoot(),
          );
        },
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
            const AppLogo(size: 120, showText: true),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
