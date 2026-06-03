import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../services/ad_service.dart';
import '../services/settings_service.dart';
import '../services/subscription_service.dart';
import 'legal_content_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  final AdService _adService = AdService();
  final SettingsService _settings = SettingsService();
  final SubscriptionService _sub = SubscriptionService();

  bool _yearlySelected = true;
  bool _isRealSubscription = false;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _activeProductId;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _loadState();
    _setupSubscriptionCallbacks();
  }

  void _loadState() {
    setState(() {
      _isRealSubscription = _settings.isRealSubscriptionActive;
      _activeProductId = _settings.activeProductId;
    });
  }

  void _setupSubscriptionCallbacks() {
    _sub.onPurchaseSuccess = (productId) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _isRestoring = false;
        _isRealSubscription = true;
        _activeProductId = productId;
      });
      _showSnackBar(
        '🎉 GeoCam Pro activated! Enjoy all features.',
        color: AppColors.primary,
        icon: Icons.check_circle,
      );
    };

    _sub.onPurchaseError = (error) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _isRestoring = false;
      });
      _showSnackBar(
        error,
        color: Colors.red,
        icon: Icons.error_outline,
      );
    };

    _sub.onPurchasePending = () {
      if (!mounted) return;
      setState(() => _isPurchasing = true);
    };

    _sub.onRestoreComplete = () {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _isRealSubscription = _settings.isRealSubscriptionActive;
        _activeProductId = _settings.activeProductId;
      });

      if (_settings.isRealSubscriptionActive) {
        _showSnackBar(
          '✅ Purchase restored successfully!',
          color: AppColors.primary,
          icon: Icons.restore,
        );
      } else {
        _showSnackBar(
          'No previous purchases found.',
          color: Colors.grey,
          icon: Icons.info_outline,
        );
      }
    };

    // Called when startup silent-restore finds no active subscription.
    // This handles cancellations and expired billing cycles.
    _sub.onSubscriptionRevoked = () {
      if (!mounted) return;
      setState(() {
        _isRealSubscription = false;
        _activeProductId = null;
      });
      debugPrint('[PremiumScreen] Subscription revoked — access removed.');
    };
  }

  void _showSnackBar(String message,
      {Color color = AppColors.primary, IconData icon = Icons.info}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribe() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    if (_yearlySelected) {
      await _sub.buyYearly();
    } else {
      await _sub.buyMonthly();
    }

    // _isPurchasing will be set to false via callback
    // but guard against callback not firing (e.g. user cancels)
    await Future.delayed(const Duration(seconds: 1));
    if (mounted && _isPurchasing) {
      setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);
    // SubscriptionService guarantees onRestoreComplete fires after ~800ms
    await _sub.restorePurchases();
  }

  @override
  void dispose() {
    _glowController.dispose();
    // Remove callbacks to avoid memory leaks
    _sub.onPurchaseSuccess = null;
    _sub.onPurchaseError = null;
    _sub.onPurchasePending = null;
    _sub.onRestoreComplete = null;
    _sub.onSubscriptionRevoked = null;
    super.dispose();
  }

  /// Opens a URL in the external browser.
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showSnackBar('Could not open link.', color: Colors.grey, icon: Icons.error_outline);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Gradient background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.backgroundDark,
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      // Animated diamond icon
                      Center(
                        child: AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) => Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  Color(0xFF0EA5E9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                      alpha: _glowAnimation.value),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.diamond,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      const Text(
                        'GeoCam Pro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Take your GPS photos to the next level with exclusive tools and unlimited access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Feature comparison table
                      _buildFeatureTable(),
                      const SizedBox(height: 28),

                      // Status cards
                      if (_isRealSubscription) ...[
                        _buildActiveSubscriptionCard(),
                        const SizedBox(height: 20),
                        // Still show pricing cards greyed out so they know what they have
                        _buildManageNote(),
                        const SizedBox(height: 20),
                      ] else ...[
                        // Pricing cards
                        _PricingCard(
                          title: 'Yearly Access',
                          price: _sub.yearlyProduct?.price ?? r'$29.99',
                          period: 'year',
                          subtitle: 'Just \$2.49/month — Save 50%',
                          isSelected: _yearlySelected,
                          badge: 'BEST VALUE',
                          onTap: () => setState(() => _yearlySelected = true),
                        ),
                        const SizedBox(height: 12),
                        _PricingCard(
                          title: 'Monthly Access',
                          price: _sub.monthlyProduct?.price ?? r'$4.99',
                          period: 'month',
                          isSelected: !_yearlySelected,
                          onTap: () => setState(() => _yearlySelected = false),
                        ),
                        const SizedBox(height: 20),

                        // Subscribe button
                        _isPurchasing
                            ? _buildLoadingButton('Processing...')
                            : PrimaryButton(
                                label: _yearlySelected
                                    ? 'Subscribe Yearly'
                                    : 'Subscribe Monthly',
                                icon: Icons.lock_open_rounded,
                                onPressed: _subscribe,
                              ),
                        const SizedBox(height: 16),
                      ],

                      // Footer links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FooterLink(
                            label: _isRestoring ? 'Restoring...' : 'Restore Purchase',
                            onTap: _isRestoring ? () {} : _restore,
                          ),
                          _footerDot(),
                          _FooterLink(
                            label: 'Terms of Use',
                            onTap: () {
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
                          ),
                          _footerDot(),
                          _FooterLink(
                            label: 'Privacy Policy',
                            onTap: () {
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Google Play.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Full-screen loading overlay for restore
          if (_isRestoring)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Restoring purchases...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _footerDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildLoadingButton(String label) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'FEATURE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'FREE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'PRO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FeatureRow(feature: 'Custom Logos', freeEnabled: false, proEnabled: true),
          _FeatureRow(feature: 'High Resolution Photos', freeEnabled: true, proEnabled: true),
          _FeatureRow(feature: 'No Ads', freeEnabled: false, proEnabled: true),
          _FeatureRow(feature: 'GPX / KML / CSV Export', freeEnabled: false, proEnabled: true),
          _FeatureRow(feature: 'Unlimited Photos', freeEnabled: true, proEnabled: true),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionCard() {
    final planName = _activeProductId == SubscriptionService.yearlyId
        ? 'Yearly Plan'
        : _activeProductId == SubscriptionService.monthlyId
            ? 'Monthly Plan'
            : 'Pro Plan';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUBSCRIPTION ACTIVE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      planName,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.backgroundDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'All PRO features are unlocked',
                style: TextStyle(fontSize: 13, color: Colors.grey[300]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManageNote() {
    return Center(
      child: TextButton.icon(
        onPressed: () => _launchUrl(
          'https://play.google.com/store/account/subscriptions'
          '?package=com.geocam.geocam_flutter',
        ),
        icon: const Icon(Icons.open_in_new, size: 14, color: AppColors.textMuted),
        label: const Text(
          'Manage subscription in Google Play',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String feature;
  final bool freeEnabled;
  final bool proEnabled;

  const _FeatureRow({
    required this.feature,
    required this.freeEnabled,
    required this.proEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                freeEnabled ? Icons.check_circle : Icons.remove_circle_outline,
                color: freeEnabled ? AppColors.primary : Colors.grey[700],
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                proEnabled ? Icons.check_circle : Icons.remove_circle_outline,
                color: proEnabled ? AppColors.primary : Colors.grey[700],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? subtitle;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    this.subtitle,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              '/ $period',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.9)
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: AppColors.backgroundDark,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
          // Badge
          if (badge != null)
            Positioned(
              top: -10,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0EA5E9)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.backgroundDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}
