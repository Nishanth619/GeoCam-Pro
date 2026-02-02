import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';
import '../widgets/primary_button.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'legal_content_screen.dart';

class LegalAcceptanceScreen extends StatefulWidget {
  final bool hasSeenOnboarding;

  const LegalAcceptanceScreen({
    super.key,
    required this.hasSeenOnboarding,
  });

  @override
  State<LegalAcceptanceScreen> createState() => _LegalAcceptanceScreenState();
}

class _LegalAcceptanceScreenState extends State<LegalAcceptanceScreen> {
  final SettingsService _settings = SettingsService();

  void _onAccept() {
    _settings.hasAcceptedTerms = true;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => widget.hasSeenOnboarding ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  void _onDecline() {
    // Exit the app as per requirements
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.gavel_outlined, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Terms & Privacy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please review and accept our terms to continue using GEOCAM PRO.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Legal Content Logic (Scrollable)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section('Privacy Policy', 
                            'Last Updated: January 26, 2026\n\n'
                            '• Location Data: We access your GPS coordinates to overlay data on your photos. This data is collected only when the app is in use.\n'
                            '• Local Storage: All photos and metadata are stored exclusively on your device. We do not have servers and do not upload your data.\n'
                            '• Permissions: Camera and Location permissions are vital for core functionality.'),
                        const Divider(color: Colors.white24, height: 32),
                        _section('Terms & Conditions', 
                            '• Responsibility: You are solely responsible for the content you capture and share.\n'
                            '• Accuracy: GEOCAM PRO is a tool for convenience; we do not guarantee 100% hardware GPS accuracy due to environmental factors.\n'
                            '• Usage: By clicking Accept, you confirm you are authorized to use this application for site data capture.'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Links to full documents
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LegalContentScreen(
                            title: 'Privacy Policy',
                            isPrivacyPolicy: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                    label: const Text('Read Full Privacy Policy'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LegalContentScreen(
                            title: 'Terms & Conditions',
                            isPrivacyPolicy: false,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Read Full Terms'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Accept & Continue',
                    onPressed: _onAccept,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _onDecline,
                    child: Text(
                      'Decline & Exit',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }
}
