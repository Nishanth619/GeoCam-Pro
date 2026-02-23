import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/settings_service.dart';
import 'services/ad_service.dart';

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize settings service
  final settings = SettingsService();
  await settings.init();
  
  // Initialize AdMob
  await AdService().initialize();
  
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
      statusBarIconBrightness: Brightness.dark, // Dark icons for white splash
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
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
    return MaterialApp(
      title: 'GeoCam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Start with the animated splash sequence
      home: SplashScreen(
        hasSeenOnboarding: hasSeenOnboarding,
        hasAcceptedTerms: hasAcceptedTerms,
      ),
    );
  }
}
