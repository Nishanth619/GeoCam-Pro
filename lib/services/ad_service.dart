import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

/// Service to manage AdMob ads (Banner and Interstitial).
///
/// Ad-block detection:
///   [adBlockDetected] becomes true when 3+ consecutive ad failures are seen,
///   suggesting a DNS-based blocker is active. UI listens to this notifier
///   and shows a soft "Support us / Go PRO" paywall in place of the banner.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ── Ad Unit IDs ──────────────────────────────────────────────────────────
  static const String _prodBannerAdUnitId =
      'ca-app-pub-4025737666505759/1313677435';
  static const String _prodInterstitialAdUnitId =
      'ca-app-pub-4025737666505759/2239746297';
  static const String _prodRewardedInterstitialAdUnitId =
      'ca-app-pub-4025737666505759/9699722890';

  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/5354046379';

  // Debug builds use test IDs; Google blocks production ads on debug builds.
  String get bannerAdUnitId =>
      kDebugMode ? _testBannerAdUnitId : _prodBannerAdUnitId;
  String get interstitialAdUnitId =>
      kDebugMode ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  String get rewardedInterstitialAdUnitId => kDebugMode
      ? _testRewardedInterstitialAdUnitId
      : _prodRewardedInterstitialAdUnitId;

  // ── Ad-block detection ───────────────────────────────────────────────────
  /// True when 3+ consecutive ad failures suggest DNS ad-blocking is active.
  /// Screens listen to this ValueNotifier to show a soft paywall widget.
  final ValueNotifier<bool> adBlockDetected = ValueNotifier(false);
  int _consecutiveAdFailures = 0;
  static const int _adBlockThreshold = 3;

  void _recordFailure() {
    _consecutiveAdFailures++;
    debugPrint('⚠️ Ad failure #$_consecutiveAdFailures');
    if (_consecutiveAdFailures >= _adBlockThreshold) {
      adBlockDetected.value = true;
      debugPrint('🚫 Ad-block detected after $_consecutiveAdFailures failures');
    }
  }

  void _recordSuccess() {
    _consecutiveAdFailures = 0;
    if (adBlockDetected.value) {
      adBlockDetected.value = false;
      debugPrint('✅ Ad loaded — clearing ad-block flag');
    }
  }

  // ── Interstitial state ───────────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  int _interstitialRetryAttempt = 0;

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isRewardedInterstitialReady = false;

  int _photosCapturedCount = 0;
  DateTime? _lastInterstitialTime;

  // Debug: 10 s cooldown for easy testing. Release: 3 minutes.
  Duration get _interstitialCooldown =>
      kDebugMode ? const Duration(seconds: 10) : const Duration(minutes: 3);

  // ── SDK initialisation ───────────────────────────────────────────────────
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    debugPrint('✅ AdMob SDK Initialized');
    loadInterstitialAd();
    loadRewardedInterstitialAd();
  }

  // ── BANNER AD ────────────────────────────────────────────────────────────

  /// Creates a BannerAd. Caller must call [BannerAd.load] and [BannerAd.dispose].
  BannerAd createBannerAd({
    required AdSize size,
    required void Function() onLoaded,
    required void Function(String error) onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Banner Ad Loaded');
          _recordSuccess();
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
              '❌ Banner Ad Failed: ${error.message} (code: ${error.code})');
          ad.dispose();
          _recordFailure();
          onFailed(error.message);
        },
      ),
    );
  }

  // ── INTERSTITIAL AD ──────────────────────────────────────────────────────

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialRetryAttempt = 0;
          _recordSuccess();
          debugPrint('✅ Interstitial Ad Loaded');

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Interstitial failed to show: ${error.message}');
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint(
              '❌ Interstitial Failed: ${error.message} (code: ${error.code})');
          _isInterstitialAdReady = false;
          _recordFailure();
          // Exponential backoff: 30 s → 60 s → 120 s → … max 5 min
          _interstitialRetryAttempt++;
          final delay = Duration(
            seconds: (30 * _interstitialRetryAttempt).clamp(30, 300),
          );
          debugPrint('🔄 Retrying interstitial in ${delay.inSeconds}s');
          Future.delayed(delay, loadInterstitialAd);
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (SettingsService().isPremiumUnlocked) return;

    if (_lastInterstitialTime != null &&
        DateTime.now().difference(_lastInterstitialTime!) <
            _interstitialCooldown) {
      final remaining = _interstitialCooldown -
          DateTime.now().difference(_lastInterstitialTime!);
      debugPrint('⏳ Interstitial cooldown: ${remaining.inSeconds}s remaining');
      return;
    }

    if (_isInterstitialAdReady && _interstitialAd != null) {
      debugPrint('📲 Showing interstitial ad...');
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
      _lastInterstitialTime = DateTime.now();
    } else {
      debugPrint('⚠️ Interstitial not ready — preloading');
      loadInterstitialAd();
    }
  }

  // ── REWARDED INTERSTITIAL AD ─────────────────────────────────────────────

  void loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialReady = true;
          debugPrint('✅ Rewarded Interstitial Loaded');

          _rewardedInterstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedInterstitialReady = false;
              loadRewardedInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedInterstitialReady = false;
              loadRewardedInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded Interstitial Failed: ${error.message}');
          _isRewardedInterstitialReady = false;
        },
      ),
    );
  }

  void showRewardedInterstitialAd({
    required void Function(AdWithoutView ad, RewardItem reward)
        onUserEarnedReward,
  }) {
    if (_isRewardedInterstitialReady && _rewardedInterstitialAd != null) {
      _rewardedInterstitialAd!.show(onUserEarnedReward: onUserEarnedReward);
      _isRewardedInterstitialReady = false;
    } else {
      debugPrint('⚠️ Rewarded Interstitial not ready — reloading');
      loadRewardedInterstitialAd();
    }
  }

  bool isRewardedInterstitialReady() => _isRewardedInterstitialReady;

  // ── Photo capture counter ────────────────────────────────────────────────

  void onPhotoCaptured({int showAfterCount = 3}) {
    _photosCapturedCount++;
    if (_photosCapturedCount >= showAfterCount) {
      showInterstitialAd();
      _photosCapturedCount = 0;
    }
  }
}
