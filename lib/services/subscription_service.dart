import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'settings_service.dart';

/// Manages Google Play subscription purchases for GeoCam Pro.
///
/// Product IDs (must match exactly what you set up in Google Play Console):
///   geocam_pro_monthly  — monthly subscription
///   geocam_pro_yearly   — yearly subscription
///
/// Subscription Lifecycle:
///   - On app start, [initialize] silently restores purchases.
///   - If the restore pass returns NO active subscription for a user who
///     previously had one, [isRealSubscriptionActive] is revoked automatically.
///   - This handles cancellations, expired billing, and chargebacks correctly.
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // ─── Product IDs ──────────────────────────────────────────────────────────
  static const String monthlyId = 'geocam_pro_monthly';
  static const String yearlyId = 'geocam_pro_yearly';
  static const Set<String> _productIds = {monthlyId, yearlyId};

  // ─── State ────────────────────────────────────────────────────────────────
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final SettingsService _settings = SettingsService();

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = false;

  // ── Restore-pass tracking ─────────────────────────────────────────────────
  // Used to detect when a restore returns zero active subscriptions,
  // meaning the user's sub was cancelled/expired.
  bool _isSilentRestoreInProgress = false;
  bool _restoreFoundActiveSub = false;

  // ── User-triggered restore tracking ───────────────────────────────────────
  bool _isUserRestoreInProgress = false;
  bool _userRestoreFoundActiveSub = false;

  // ─── Public status callbacks — set from your UI screen ────────────────────
  void Function(String productId)? onPurchaseSuccess;
  void Function(String error)? onPurchaseError;
  void Function()? onRestoreComplete;
  void Function()? onPurchasePending;
  /// Called when a previously active subscription is detected as cancelled/expired.
  void Function()? onSubscriptionRevoked;

  // ─── Getters ──────────────────────────────────────────────────────────────
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;

  ProductDetails? get monthlyProduct {
    try {
      return _products.firstWhere((p) => p.id == monthlyId);
    } catch (_) {
      return null;
    }
  }

  ProductDetails? get yearlyProduct {
    try {
      return _products.firstWhere((p) => p.id == yearlyId);
    } catch (_) {
      return null;
    }
  }

  bool get isProActive => _settings.isPremiumUnlocked;
  bool get hasRealSubscription => _settings.isRealSubscriptionActive;
  String? get activeProductId => _settings.activeProductId;

  // ─── Initialization ───────────────────────────────────────────────────────

  /// Call once from main() after SettingsService.init().
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('[Sub] Google Play Billing not available.');
      return;
    }

    // Listen to the purchase update stream
    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) {
        debugPrint('[Sub] Purchase stream error: $error');
        onPurchaseError?.call('Purchase stream error: $error');
      },
    );

    // Load product details from Play Store
    await _loadProducts();

    // Silent restore on every startup — checks if subscription is still active.
    // If the user cancelled, this will revoke access automatically.
    await _silentRestoreOnStartup();

    debugPrint('[Sub] Initialized. Available: $_isAvailable, '
        'ProActive: ${_settings.isRealSubscriptionActive}');
  }

  Future<void> _loadProducts() async {
    _isLoading = true;
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_productIds);
    _isLoading = false;

    if (response.error != null) {
      debugPrint('[Sub] Product load error: ${response.error}');
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[Sub] Products not found in Play Console: '
          '${response.notFoundIDs} — create them at '
          'play.google.com/console → Subscriptions');
    }

    _products = response.productDetails;
    debugPrint('[Sub] Loaded ${_products.length} products: '
        '${_products.map((p) => p.id).toList()}');
  }

  /// Silently restores purchases on startup.
  /// Revokes [isRealSubscriptionActive] if no active sub is found.
  Future<void> _silentRestoreOnStartup() async {
    // Only check if user previously had a real subscription
    if (!_settings.isRealSubscriptionActive) return;

    debugPrint('[Sub] Silently checking subscription status...');
    _isSilentRestoreInProgress = true;
    _restoreFoundActiveSub = false;

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[Sub] Silent restore error: $e');
    }

    // Wait for the purchase stream to process all restored items.
    // The stream fires synchronously-ish but we give it a short window.
    await Future.delayed(const Duration(milliseconds: 1200));
    _isSilentRestoreInProgress = false;

    if (!_restoreFoundActiveSub && _settings.isRealSubscriptionActive) {
      // No active subscription found — user cancelled or billing lapsed.
      _settings.isRealSubscriptionActive = false;
      _settings.activeProductId = null;
      debugPrint('[Sub] ⚠️ Subscription revoked — no active purchase found.');
      onSubscriptionRevoked?.call();
    } else if (_restoreFoundActiveSub) {
      debugPrint('[Sub] ✅ Subscription confirmed active.');
    }
  }

  // ─── Purchase Flow ────────────────────────────────────────────────────────

  Future<void> buyMonthly() async => _buy(monthlyId);
  Future<void> buyYearly() async => _buy(yearlyId);

  Future<void> _buy(String productId) async {
    if (!_isAvailable) {
      onPurchaseError
          ?.call('Google Play Billing is not available on this device.');
      return;
    }

    ProductDetails? product;
    try {
      product = _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      await _loadProducts();
      try {
        product = _products.firstWhere((p) => p.id == productId);
      } catch (_) {
        onPurchaseError?.call(
            'Product not found. Please check your internet connection.');
        return;
      }
    }

    final PurchaseParam param = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('[Sub] Buy error: $e');
      onPurchaseError?.call('Could not initiate purchase: $e');
    }
  }

  /// Restore previous purchases (called from "Restore Purchase" button).
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onPurchaseError?.call('Google Play Billing is not available.');
      return;
    }

    _isUserRestoreInProgress = true;
    _userRestoreFoundActiveSub = false;

    try {
      await _iap.restorePurchases();
      // Give the purchase stream time to process all restored items.
      await Future.delayed(const Duration(milliseconds: 900));
    } catch (e) {
      debugPrint('[Sub] Restore error: $e');
      onPurchaseError?.call('Could not restore purchases: $e');
    } finally {
      _isUserRestoreInProgress = false;
      onRestoreComplete?.call();
    }
  }

  // ─── Purchase Stream Handler ───────────────────────────────────────────────

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('[Sub] Purchase pending: ${purchase.productID}');
          onPurchasePending?.call();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchase);
          break;

        case PurchaseStatus.error:
          final errorMsg =
              purchase.error?.message ?? 'Unknown purchase error';
          debugPrint('[Sub] Purchase error: $errorMsg');
          // Don't fire error for user-cancelled purchases
          if (purchase.error?.code != 'responseCode' &&
              errorMsg != 'User canceled the purchase.') {
            onPurchaseError?.call(errorMsg);
          }
          break;

        case PurchaseStatus.canceled:
          debugPrint('[Sub] Purchase cancelled by user.');
          break;
      }

      // Always complete the purchase to avoid Google Play issues
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchase) {
    // Only process our subscription product IDs
    if (!_productIds.contains(purchase.productID)) return;

    // Mark subscription as active
    _settings.isRealSubscriptionActive = true;
    _settings.activeProductId = purchase.productID;
    debugPrint('[Sub] ✅ Subscription active: ${purchase.productID}');

    // Update restore-pass tracking flags
    if (_isSilentRestoreInProgress) {
      _restoreFoundActiveSub = true;
    }
    if (_isUserRestoreInProgress) {
      _userRestoreFoundActiveSub = true;
    }

    // Only fire the success callback for new purchases (not silent restore)
    if (!_isSilentRestoreInProgress) {
      onPurchaseSuccess?.call(purchase.productID);
    }
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────

  void dispose() {
    _purchaseSubscription?.cancel();
  }
}
