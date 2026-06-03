import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/premium_screen.dart';

/// Shown in place of an ad banner when ad-blocking is detected.
///
/// Displays a polite message asking the user to support the app,
/// with a "GO PRO" button linking to the upgrade screen.
class SoftPaywallBanner extends StatefulWidget {
  const SoftPaywallBanner({super.key});

  @override
  State<SoftPaywallBanner> createState() => _SoftPaywallBannerState();
}

class _SoftPaywallBannerState extends State<SoftPaywallBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openPremium() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    );
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _dismissed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F1A24),
              AppColors.primary.withValues(alpha: 0.08),
            ],
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          children: [
            // Heart icon
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFEF4444),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            // Message
            const Expanded(
              child: Text(
                'Ads keep GeoCam Pro free. '
                'Your ad blocker prevents them from loading.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            // GO PRO button
            GestureDetector(
              onTap: _openPremium,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF00C8A0)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'GO PRO',
                  style: TextStyle(
                    color: Color(0xFF0F1A24),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Dismiss X
            GestureDetector(
              onTap: _dismiss,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: Colors.white30,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
