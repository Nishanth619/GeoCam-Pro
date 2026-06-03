import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geocam_flutter/l10n/app_localizations.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/settings_service.dart';
import 'services/ad_service.dart';
import 'services/subscription_service.dart';
import 'services/location_service.dart';

// Global notifier for changing the app language without restarting
final ValueNotifier<Locale?> appLocaleNotifier = ValueNotifier<Locale?>(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize settings service (fast — just SharedPreferences)
  final settings = SettingsService();
  await settings.init();
  
  // Load saved language
  if (settings.appLanguage != 'auto') {
    appLocaleNotifier.value = Locale(settings.appLanguage);
  }
  
  // Initialize AdMob in the background — do NOT await.
  AdService().initialize();
  
  // Initialize Subscription Service in the background — do NOT await.
  SubscriptionService().initialize();

  // Load any previously saved manual datetime override from storage.
  unawaited(LocationService().loadPersistedDateTime());
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, 
      systemNavigationBarColor: Color(0xFF070E14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(GeoCamApp(
    hasSeenOnboarding: settings.hasSeenOnboarding,
    hasAcceptedTerms: settings.hasAcceptedTerms,
  ));
}

class GeoCamApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final bool hasAcceptedTerms;

  const GeoCamApp({
    super.key,
    required this.hasSeenOnboarding,
    required this.hasAcceptedTerms,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'GeoCam Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('ru'),
            Locale('de'),
            Locale('id'),
            Locale('tl'),
          ],
          locale: locale, // null means auto-detect from device
          home: SplashScreen(
            hasSeenOnboarding: hasSeenOnboarding,
            hasAcceptedTerms: hasAcceptedTerms,
          ),
        );
      },
    );
  }
}
