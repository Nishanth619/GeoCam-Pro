import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist app settings across sessions
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // Setting keys
  static const String _keyGridLines = 'grid_lines_enabled';
  static const String _keyMetricUnits = 'metric_units';
  static const String _keyCelsiusTemp = 'celsius_temp';
  static const String _keySaveToSdCard = 'save_to_sd_card';
  static const String _keyShowWatermark = 'show_watermark';
  static const String _keyImageResolution = 'image_resolution';
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String _keyHasAcceptedTerms = 'has_accepted_terms';
  static const String _keyAppLanguage = 'app_language';
  
  // Watermark settings
  static const String _keyWatermarkLogo = 'watermark_logo';
  static const String _keyWatermarkText = 'watermark_text';
  static const String _keyWatermarkPosition = 'watermark_position';
  static const String _keyWatermarkOpacity = 'watermark_opacity';
  static const String _keyWatermarkScale = 'watermark_scale';
  
  // Template settings
  static const String _keyTemplateMapType = 'template_map_type';
  static const String _keyTemplateShowAddress = 'template_show_address';
  static const String _keyTemplateShowCoordinates = 'template_show_coordinates';
  static const String _keyTemplateShowCompass = 'template_show_compass';
  static const String _keyTemplateShowDateTime = 'template_show_datetime';
  static const String _keyTemplateDateFormat = 'template_date_format';
  static const String _keyTemplateCoordFormat = 'template_coord_format';
  static const String _keyRewardExpiration = 'reward_expiration_time';
  // One-shot key: set true when user watches a rewarded ad for custom geo edit.
  // Cleared immediately after the location is confirmed (single-use).
  static const String _keyHasOneTimeGeoEdit = 'has_one_time_geo_edit';

  
  // Subscription keys
  static const String _keyRealSubscriptionActive = 'real_subscription_active';
  static const String _keyActiveProductId = 'active_product_id';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('SettingsService initialized');
  }

  // ============= Camera Settings =============
  
  bool get gridLinesEnabled => _prefs?.getBool(_keyGridLines) ?? false;
  set gridLinesEnabled(bool value) => _prefs?.setBool(_keyGridLines, value);

  String get imageResolution => _prefs?.getString(_keyImageResolution) ?? 'high';
  set imageResolution(String value) => _prefs?.setString(_keyImageResolution, value);

  bool get hasSeenOnboarding => _prefs?.getBool(_keyHasSeenOnboarding) ?? false;
  set hasSeenOnboarding(bool value) => _prefs?.setBool(_keyHasSeenOnboarding, value);

  bool get hasAcceptedTerms => _prefs?.getBool(_keyHasAcceptedTerms) ?? false;
  set hasAcceptedTerms(bool value) => _prefs?.setBool(_keyHasAcceptedTerms, value);

  String get appLanguage => _prefs?.getString(_keyAppLanguage) ?? 'auto';
  set appLanguage(String value) => _prefs?.setString(_keyAppLanguage, value);

  // ============= Unit Settings =============
  
  bool get useMetricUnits => _prefs?.getBool(_keyMetricUnits) ?? true;
  set useMetricUnits(bool value) => _prefs?.setBool(_keyMetricUnits, value);

  bool get useCelsius => _prefs?.getBool(_keyCelsiusTemp) ?? true;
  set useCelsius(bool value) => _prefs?.setBool(_keyCelsiusTemp, value);

  // ============= Storage Settings =============
  
  bool get saveToSdCard => _prefs?.getBool(_keySaveToSdCard) ?? false;
  set saveToSdCard(bool value) => _prefs?.setBool(_keySaveToSdCard, value);

  // ============= Watermark Settings =============
  
  bool get showWatermark => _prefs?.getBool(_keyShowWatermark) ?? true;
  set showWatermark(bool value) => _prefs?.setBool(_keyShowWatermark, value);

  int get watermarkLogo => _prefs?.getInt(_keyWatermarkLogo) ?? 1;
  set watermarkLogo(int value) => _prefs?.setInt(_keyWatermarkLogo, value);

  String get watermarkText => _prefs?.getString(_keyWatermarkText) ?? 'GeoCam';
  set watermarkText(String value) => _prefs?.setString(_keyWatermarkText, value);

  int get watermarkPosition => _prefs?.getInt(_keyWatermarkPosition) ?? 8; // Bottom right
  set watermarkPosition(int value) => _prefs?.setInt(_keyWatermarkPosition, value);

  double get watermarkOpacity => _prefs?.getDouble(_keyWatermarkOpacity) ?? 0.85;
  set watermarkOpacity(double value) => _prefs?.setDouble(_keyWatermarkOpacity, value);

  double get watermarkScale => _prefs?.getDouble(_keyWatermarkScale) ?? 1.0;
  set watermarkScale(double value) => _prefs?.setDouble(_keyWatermarkScale, value);

  // ============= Template Settings =============
  
  int get templateMapType => _prefs?.getInt(_keyTemplateMapType) ?? 3; // Default to Hybrid
  set templateMapType(int value) => _prefs?.setInt(_keyTemplateMapType, value);

  bool get templateShowAddress => _prefs?.getBool(_keyTemplateShowAddress) ?? true;
  set templateShowAddress(bool value) => _prefs?.setBool(_keyTemplateShowAddress, value);

  bool get templateShowCoordinates => _prefs?.getBool(_keyTemplateShowCoordinates) ?? true;
  set templateShowCoordinates(bool value) => _prefs?.setBool(_keyTemplateShowCoordinates, value);

  bool get templateShowCompass => _prefs?.getBool(_keyTemplateShowCompass) ?? false;
  set templateShowCompass(bool value) => _prefs?.setBool(_keyTemplateShowCompass, value);

  bool get templateShowDateTime => _prefs?.getBool(_keyTemplateShowDateTime) ?? true;
  set templateShowDateTime(bool value) => _prefs?.setBool(_keyTemplateShowDateTime, value);

  String get templateDateFormat => _prefs?.getString(_keyTemplateDateFormat) ?? 'DD/MM/YYYY';
  set templateDateFormat(String value) => _prefs?.setString(_keyTemplateDateFormat, value);

  String get templateCoordFormat => _prefs?.getString(_keyTemplateCoordFormat) ?? 'Decimal Degrees (DD)';
  set templateCoordFormat(String value) => _prefs?.setString(_keyTemplateCoordFormat, value);

  // ============= Reward Settings =============
  
  DateTime? get rewardExpiration {
    final ms = _prefs?.getInt(_keyRewardExpiration);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set rewardExpiration(DateTime? value) {
    if (value == null) {
      _prefs?.remove(_keyRewardExpiration);
    } else {
      _prefs?.setInt(_keyRewardExpiration, value.millisecondsSinceEpoch);
    }
  }

  bool get isRewardActive {
    final expiration = rewardExpiration;
    if (expiration == null) return false;
    return DateTime.now().isBefore(expiration);
  }

  // ── One-shot custom geo edit (earned by watching one rewarded ad) ────────
  /// True only after user watches a rewarded ad specifically for geo editing.
  /// Consumed (set back to false) immediately after the location is confirmed.
  bool get hasOneTimeGeoEdit =>
      _prefs?.getBool(_keyHasOneTimeGeoEdit) ?? false;
  set hasOneTimeGeoEdit(bool value) =>
      _prefs?.setBool(_keyHasOneTimeGeoEdit, value);

  // ============= Subscription Settings (Real IAP) =============

  bool get isRealSubscriptionActive =>
      _prefs?.getBool(_keyRealSubscriptionActive) ?? false;
  set isRealSubscriptionActive(bool value) =>
      _prefs?.setBool(_keyRealSubscriptionActive, value);

  String? get activeProductId => _prefs?.getString(_keyActiveProductId);
  set activeProductId(String? value) {
    if (value == null) {
      _prefs?.remove(_keyActiveProductId);
    } else {
      _prefs?.setString(_keyActiveProductId, value);
    }
  }

  /// True ONLY when the user has an active paid subscription.
  /// Reward ad watchers do NOT get isPremiumUnlocked = true —
  /// so banner and interstitial ads keep running for them.
  bool get isPremiumUnlocked => isRealSubscriptionActive;

  /// True when user can access premium FEATURES (paid sub OR active 24-h reward).
  /// Use this to gate feature access (map styles, watermark, etc.) — NOT ads.
  bool get hasFeatureAccess => isRealSubscriptionActive || isRewardActive;

  // ============= Helper Methods =============

  /// Format altitude based on unit preference
  String formatAltitude(double? meters) {
    if (meters == null) return '--';
    if (useMetricUnits) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      final feet = meters * 3.28084;
      return '${feet.toStringAsFixed(0)}ft';
    }
  }

  /// Format distance based on unit preference
  String formatDistance(double? meters) {
    if (meters == null) return '--';
    if (useMetricUnits) {
      if (meters >= 1000) {
        return '${(meters / 1000).toStringAsFixed(1)}km';
      }
      return '${meters.toStringAsFixed(0)}m';
    } else {
      final miles = meters * 0.000621371;
      if (miles >= 1) {
        return '${miles.toStringAsFixed(1)}mi';
      }
      final feet = meters * 3.28084;
      return '${feet.toStringAsFixed(0)}ft';
    }
  }

  /// Format temperature based on unit preference
  String formatTemperature(double? celsius) {
    if (celsius == null) return '--';
    if (useCelsius) {
      return '${celsius.toStringAsFixed(0)}°C';
    } else {
      final fahrenheit = (celsius * 9 / 5) + 32;
      return '${fahrenheit.toStringAsFixed(0)}°F';
    }
  }

  /// Format speed based on unit preference
  String formatSpeed(double? metersPerSecond) {
    if (metersPerSecond == null) return '--';
    if (useMetricUnits) {
      final kmh = metersPerSecond * 3.6;
      return '${kmh.toStringAsFixed(1)} km/h';
    } else {
      final mph = metersPerSecond * 2.23694;
      return '${mph.toStringAsFixed(1)} mph';
    }
  }
}
