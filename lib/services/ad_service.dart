import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

/// Service to manage AdMob ads (Banner and Interstitial)
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Production Ad Unit IDs
  static const String _prodBannerAdUnitId = 'ca-app-pub-4025737666505759/1313677435';
  static const String _prodInterstitialAdUnitId = 'ca-app-pub-4025737666505759/2239746297';
  static const String _prodRewardedInterstitialAdUnitId = 'ca-app-pub-4025737666505759/9699722890';

  // Test Ad Unit IDs (for development)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedInterstitialAdUnitId = 'ca-app-pub-3940256099942544/5354046379';

  // Use production IDs (change to _test* for development)
  String get bannerAdUnitId => _prodBannerAdUnitId;
  String get interstitialAdUnitId => _prodInterstitialAdUnitId;
  String get rewardedInterstitialAdUnitId => _prodRewardedInterstitialAdUnitId;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isRewardedInterstitialReady = false;
  
  int _photosCapturedCount = 0;
  DateTime? _lastInterstitialTime;
  static const Duration _interstitialCooldown = Duration(minutes: 3);

  /// Initialize the Mobile Ads SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    debugPrint('AdMob SDK Initialized');
    loadInterstitialAd();
    loadRewardedInterstitialAd();
  }

  // ============= BANNER AD =============

  /// Creates an Adaptive Banner Ad
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
          debugPrint('Banner Ad Loaded');
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner Ad Failed: ${error.message}');
          ad.dispose();
          onFailed(error.message);
        },
      ),
    );
  }

  // ============= INTERSTITIAL AD =============

  /// Loads an Interstitial Ad for later display
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          debugPrint('Interstitial Ad Loaded');

          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd(); // Preload the next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial Failed to Load: ${error.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  /// Shows the Interstitial Ad if it's ready and cooldown has passed
  void showInterstitialAd() {
    // Check if cooldown has passed
    if (_lastInterstitialTime != null && 
        DateTime.now().difference(_lastInterstitialTime!) < _interstitialCooldown) {
      debugPrint('Interstitial in cooldown period');
      return;
    }

    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
      _lastInterstitialTime = DateTime.now();
    } else {
      debugPrint('Interstitial Ad not ready yet');
    }
  }

  // ============= REWARDED INTERSTITIAL AD =============

  /// Loads a Rewarded Interstitial Ad
  void loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialReady = true;
          debugPrint('Rewarded Interstitial Loaded');

          _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
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
          debugPrint('Rewarded Interstitial Failed: ${error.message}');
          _isRewardedInterstitialReady = false;
        },
      ),
    );
  }

  /// Shows the Rewarded Interstitial Ad
  void showRewardedInterstitialAd({required void Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward}) {
    if (_isRewardedInterstitialReady && _rewardedInterstitialAd != null) {
      _rewardedInterstitialAd!.show(onUserEarnedReward: onUserEarnedReward);
      _isRewardedInterstitialReady = false;
    } else {
      debugPrint('Rewarded Interstitial Ad not ready yet');
      // Fallback: reload if not ready
      loadRewardedInterstitialAd();
    }
  }

  /// Check if Ready
  bool isRewardedInterstitialReady() => _isRewardedInterstitialReady;

  /// Track photos and show interstitial every N photos
  void onPhotoCaptured({int showAfterCount = 3}) {
    _photosCapturedCount++;
    debugPrint('Photos captured: $_photosCapturedCount');
    
    if (_photosCapturedCount >= showAfterCount) {
      showInterstitialAd();
      _photosCapturedCount = 0;
    }
  }
}
