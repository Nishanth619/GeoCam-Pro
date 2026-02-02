import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LegalContentScreen extends StatelessWidget {
  final String title;
  final bool isPrivacyPolicy;

  const LegalContentScreen({
    super.key,
    required this.title,
    required this.isPrivacyPolicy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPrivacyPolicy) ..._buildPrivacyPolicy() else ..._buildTermsAndConditions(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPrivacyPolicy() {
    return [
      _sectionHeader('GEOCAM PRO - Privacy Policy'),
      _subsection('Effective Date: January 31, 2026'),
      const SizedBox(height: 16),
      
      _section('1. Information We Collect', 
          '• Location Data: GPS coordinates, altitude, heading, and speed - collected only when actively using the app\n'
          '• Camera Access: To capture geo-tagged photographs\n'
          '• Photo Metadata (EXIF): GPS coordinates, altitude, and timestamp embedded in photos\n'
          '• Storage Access: To save photos to your device gallery\n'
          '• Device Information: Model, OS version, crash logs for diagnostics\n'
          '• Weather Data: Coordinates sent to OpenWeather API for local weather'),
      
      _section('2. How We Use Your Information', 
          'We use collected information solely for:\n'
          '• Core Functionality: Capture and save geo-tagged photos\n'
          '• Map Display: Show your location on mini-map and overlays\n'
          '• Weather Overlay: Display local weather on photos\n'
          '• App Improvement: Analyze crash logs and performance\n\n'
          'We do NOT:\n'
          '• Sell, rent, or share your data for marketing\n'
          '• Upload photos or location history to cloud servers\n'
          '• Track your location when app is not in use'),
      
      _section('3. Data Storage and Security', 
          '• Local Storage: All photos, GPS data, and settings stored exclusively on your device\n'
          '• No Cloud Access: We do not operate servers or databases\n'
          '• Data Security: Protected by your device\'s built-in security\n'
          '• Data Retention: Retained until you manually delete (via app, device settings, or uninstall)'),
      
      _section('4. Third-Party Services', 
          '• Map Tiles: OpenStreetMap/Mapbox (coordinates only)\n'
          '• Weather API: OpenWeather (coordinates only)\n'
          '• Advertising: Google AdMob (device ID, usage data)\n'
          '• Billing: Google Play Billing (purchase information)'),
      
      _section('5. Your Rights (GDPR & CCPA)', 
          '• Right to Access: View all data via app gallery and settings\n'
          '• Right to Deletion: Delete photos, clear app data, or uninstall\n'
          '• Right to Opt-Out: Disable location/camera permissions or personalized ads\n'
          '• Right to Portability: Export photos and metadata anytime\n'
          '• Right to Withdraw Consent: Revoke permissions via device settings'),
      
      _section('6. Children\'s Privacy', 
          'GEOCAM PRO is not intended for children under 13. We do not knowingly collect data from children.'),
      
      _section('7. Contact Us', 
          'For questions or requests regarding this Privacy Policy:\n'
          'Email: nishantharadhya4@gmail.com\n'
          'Website: https://www.nexaaradhya.site/\n'
          'Developer: Nishanth Aradhya AG'),
    ];
  }

  List<Widget> _buildTermsAndConditions() {
    return [
      _sectionHeader('GEOCAM PRO - Terms and Conditions'),
      _subsection('Effective Date: January 31, 2026'),
      const SizedBox(height: 16),
      
      _section('1. Acceptance of Terms', 
          'By using GEOCAM PRO, you enter into a legally binding agreement. If you do not agree to these Terms, do not use the App.\n\n'
          'Age Requirement: You must be at least 13 years of age to use this App.'),
      
      _section('2. License to Use', 
          'GEOCAM PRO grants you a limited, non-exclusive, non-transferable, revocable license to use the App for personal, non-commercial use.\n\n'
          'You agree NOT to:\n'
          '• Copy, modify, distribute, sell, or lease the App\n'
          '• Reverse engineer, decompile, or disassemble the App\n'
          '• Remove copyright or trademark notices\n'
          '• Use the App for illegal or unauthorized purposes\n'
          '• Use automated bots or scripts'),
      
      _section('3. User Responsibilities', 
          '• Acceptable Use: Comply with all applicable laws\n'
          '• Content Responsibility: You are solely responsible for photos you create\n'
          '• Location Data: GPS accuracy depends on device hardware and environment\n'
          '• Verification: Verify GPS data accuracy before relying on it for critical purposes'),
      
      _section('4. Premium Features', 
          '• Free Version: Core functionality with ads\n'
          '• Premium Version: Advanced features, ad-free (via in-app purchase)\n'
          '• Billing: Processed via Google Play Billing\n'
          '• Auto-Renewal: Subscriptions auto-renew unless canceled 24h before period ends\n'
          '• Refunds: Governed by Google Play refund policy'),
      
      _section('5. Disclaimers and Limitations', 
          '• "AS IS" Basis: App provided without warranties of any kind\n'
          '• No Professional Advice: For informational and recreational purposes only\n'
          '• GPS Accuracy: We do not guarantee accuracy of GPS data\n'
          '• Third-Party Services: Not responsible for third-party service availability\n'
          '• Limitation of Liability: Not liable for indirect, incidental, or consequential damages'),
      
      _section('6. Intellectual Property', 
          '• Trademarks: "GEOCAM PRO" and logo are property of the developer\n'
          '• Copyright: All app content is protected by copyright laws\n'
          '• User Content: You retain ownership of photos you create'),
      
      _section('7. Termination', 
          'We reserve the right to suspend or terminate your access for:\n'
          '• Violation of these Terms\n'
          '• Fraudulent, abusive, or illegal activity\n'
          '• Any other reason at our sole discretion'),
      
      _section('8. Governing Law', 
          'These Terms are governed by the laws of India.\n\n'
          'Disputes will be resolved through informal negotiation or binding arbitration.'),
      
      _section('9. Contact Us', 
          'For questions regarding these Terms:\n'
          'Email: nishantharadhya4@gmail.com\n'
          'Website: https://www.nexaaradhya.site/\n'
          'Developer: Nishanth Aradhya AG'),
    ];
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _subsection(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
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
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}
