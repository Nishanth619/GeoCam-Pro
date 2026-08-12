import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import '../services/ad_service.dart';
import '../services/settings_service.dart';
import 'package:geocam_flutter/l10n/app_localizations.dart';

/// Full-screen map that lets the user drop a pin to override GPS.
/// Opened from the CameraScreen top toolbar.
class EditLocationScreen extends StatefulWidget {
  const EditLocationScreen({super.key});

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final SettingsService _settings = SettingsService();
  final AdService _adService = AdService();
  final MapController _mapController = MapController();

  // The coordinate at the center of the map (the "pin").
  LatLng _pinnedLatLng = const LatLng(20.5937, 78.9629); // India default

  // Reverse-geocoded address for the pinned point.
  String _pinnedAddress = 'Searching address…';
  bool _isGeocodingAddress = false;
  Timer? _geocodeDebounce;

  // Whether the user is actively dragging the map (crosshair animates).
  bool _isDragging = false;

  // ─── Custom Date & Time ───────────────────────────────────────────────────
  DateTime? _customDate;
  TimeOfDay? _customTime;

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearching = false;
  Timer? _searchDebounce;
  int _searchGeneration = 0; // guards against stale/out-of-order responses
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  // In-memory cache: query → results (avoids repeat network calls)
  final Map<String, List<Map<String, dynamic>>> _suggestionCache = {};

  // Suggestion dropdown fade+slide animation
  late AnimationController _suggAnimController;
  late Animation<double> _suggFade;
  late Animation<Offset> _suggSlide;

  // Animation for the drop-pin bounce.
  late AnimationController _pinAnimController;
  late Animation<double> _pinBounce;

  @override
  void initState() {
    super.initState();

    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pinBounce = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _pinAnimController, curve: Curves.elasticOut),
    );

    _suggAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _suggFade = CurvedAnimation(parent: _suggAnimController, curve: Curves.easeOut);
    _suggSlide = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _suggAnimController, curve: Curves.easeOut));

    // Start at the current effective location.
    final effective = _locationService.effectivePosition;
    if (effective != null) {
      _pinnedLatLng = LatLng(effective.latitude, effective.longitude);
    }

    // If a manual override is already active, display its address immediately.
    if (_locationService.isManualOverrideActive &&
        _locationService.manualOverrideAddress != null) {
      _pinnedAddress = _locationService.manualOverrideAddress!;
    } else {
      _reverseGeocode(_pinnedLatLng);
    }

    // Pre-fill date/time if a manual override is already active.
    if (_locationService.isManualDateTimeActive) {
      final dt = _locationService.manualDateTime!;
      _customDate = DateTime(dt.year, dt.month, dt.day);
      _customTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _suggAnimController.dispose();
    _pinAnimController.dispose();
    super.dispose();
  }

  // ─── MAP MOVE HANDLER ───────────────────────────────────────────────────────

  void _onMapMove(LatLng center, bool hasGesture) {
    if (!hasGesture) return;
    // Hide suggestions when user starts panning
    if (_showSuggestions) {
      setState(() => _showSuggestions = false);
      _suggAnimController.reverse();
    }
    setState(() {
      _pinnedLatLng = center;
      _isDragging = true;
      _pinnedAddress = 'Searching address…';
    });

    // Debounce geocoding — only fire 800ms after the user stops dragging.
    // Increased from 600ms to reduce unnecessary API calls while panning.
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isDragging = false);
        HapticFeedback.lightImpact(); // satisfying micro-haptic on pin drop
        _reverseGeocode(_pinnedLatLng);
      }
    });
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    if (!mounted) return;
    setState(() => _isGeocodingAddress = true);

    final address = await _locationService.getAddressFromCoordinates(
      latLng.latitude,
      latLng.longitude,
    );

    if (!mounted) return;
    setState(() {
      _pinnedAddress = address ?? _fallbackLabel(latLng);
      _isGeocodingAddress = false;
    });

    // Play the pin-drop bounce.
    _pinAnimController.forward(from: 0);
  }

  String _fallbackLabel(LatLng ll) {
    final latDir = ll.latitude >= 0 ? 'N' : 'S';
    final lonDir = ll.longitude >= 0 ? 'E' : 'W';
    return '${ll.latitude.abs().toStringAsFixed(4)}°$latDir, '
        '${ll.longitude.abs().toStringAsFixed(4)}°$lonDir';
  }

  // ─── CONFIRM: set the override ───────────────────────────────────────────────

  /// Confirms the location override using [address].
  /// If geocoding is still running, call with `_fallbackLabel(_pinnedLatLng)`.
  void _confirmLocationWithAddress(String address) {
    HapticFeedback.mediumImpact();
    _locationService.setManualOverride(
      _pinnedLatLng.latitude,
      _pinnedLatLng.longitude,
      address,
    );

    // Apply custom date/time if either has been set by the user.
    if (_customDate != null || _customTime != null) {
      final date = _customDate ?? DateTime.now();
      final time = _customTime ?? TimeOfDay.now();
      final combined = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _locationService.setManualDateTime(combined);
      debugPrint('🕐 Saved custom datetime: $combined');
    } else {
      // Both null — clear any previous override so camera uses system time.
      _locationService.clearManualDateTime();
    }

    // Consume the one-shot geo edit token (if it was used).
    // After this point the user must watch another ad to edit again.
    if (_settings.hasOneTimeGeoEdit) {
      _settings.hasOneTimeGeoEdit = false;
      debugPrint('🎯 One-shot geo edit consumed.');
    }

    if (!mounted) return;
    Navigator.of(context).pop(true); // true = location was updated
  }

  /// Convenience: uses current address (or coordinate fallback if still geocoding).
  void _confirmLocation() {
    final address = _isGeocodingAddress
        ? _fallbackLabel(_pinnedLatLng)
        : _pinnedAddress;
    _confirmLocationWithAddress(address);
  }

  // ─── CLEAR override and go back to GPS ──────────────────────────────────────

  void _clearOverride() {
    HapticFeedback.lightImpact();
    _locationService.clearManualOverride();
    _locationService.clearManualDateTime();
    if (!mounted) return;
    Navigator.of(context).pop(false); // false = override cleared
  }

  // ─── SEARCH ─────────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      _searchDebounce?.cancel();
      _suggAnimController.reverse();
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      // Check in-memory cache first
      final cacheKey = query.trim().toLowerCase();
      if (_suggestionCache.containsKey(cacheKey)) {
        if (!mounted) return;
        setState(() {
          _suggestions = _suggestionCache[cacheKey]!;
          _showSuggestions = _suggestions.isNotEmpty;
          _isSearching = false;
        });
        if (_suggestions.isNotEmpty) _suggAnimController.forward();
        return;
      }

      // Stamp this request to detect stale responses (race-condition guard)
      final generation = ++_searchGeneration;
      if (mounted) setState(() => _isSearching = true);

      final results = await _locationService.getAddressSuggestions(query);

      // Discard results if a newer request has already started
      if (!mounted || generation != _searchGeneration) return;

      // Write to cache
      _suggestionCache[cacheKey] = results;

      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
        _isSearching = false;
      });
      if (results.isNotEmpty) {
        _suggAnimController.forward();
      } else {
        _suggAnimController.reverse();
      }
    });
  }

  Future<void> _onSuggestionSelected(Map<String, dynamic> suggestion) async {
    FocusScope.of(context).unfocus();
    _searchController.text = suggestion['display_name'] ?? '';
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
      _isSearching = true; // Show spinner while resolving coordinates
    });
    _suggAnimController.reverse();

    double lat;
    double lon;
    final String displayName = suggestion['display_name'] ?? '';

    // Google Places returns a place_id — resolve it to coordinates via Details API
    final placeId = suggestion['place_id'] as String?;
    if (placeId != null && placeId.isNotEmpty) {
      final details = await _locationService.getPlaceCoordinates(placeId);
      if (!mounted) return;
      if (details == null) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not resolve location. Try again.')),
        );
        return;
      }
      lat = details['lat'] as double;
      lon = details['lon'] as double;
    } else {
      // Fallback: already has lat/lon (legacy path)
      lat = (suggestion['lat'] as num?)?.toDouble() ?? 0.0;
      lon = (suggestion['lon'] as num?)?.toDouble() ?? 0.0;
    }

    if (!mounted) return;
    setState(() => _isSearching = false);

    final newLatLng = LatLng(lat, lon);
    // Move the map; onPositionChanged will NOT fire for programmatic moves
    // so we manually trigger the geocode + pin update.
    _mapController.move(newLatLng, 15.0);
    HapticFeedback.mediumImpact();
    setState(() {
      _pinnedLatLng = newLatLng;
      _pinnedAddress = displayName;
    });
    _pinAnimController.forward(from: 0);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    final generation = ++_searchGeneration;
    setState(() => _isSearching = true);

    final results = await _locationService.getAddressSuggestions(query);
    if (!mounted || generation != _searchGeneration) return;
    setState(() => _isSearching = false);

    if (results.isNotEmpty) {
      _onSuggestionSelected(results.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Location not found. Try a different search.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ─── DATE & TIME PICKERS ─────────────────────────────────────────────────

  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Color(0xFF0F1A24),
            surface: Color(0xFF0F1A24),
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF0F1A24),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _customDate = picked);
      // Auto-open time picker right after date is chosen.
      if (_customTime == null) _pickTime();
    }
  }

  Future<void> _pickTime() async {
    HapticFeedback.lightImpact();
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _customTime ?? now,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Color(0xFF0F1A24),
            surface: Color(0xFF0F1A24),
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF0F1A24),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _customTime = picked;
        // Auto-set today as date if user only picked time.
        _customDate ??= DateTime.now();
      });
    }
  }

  void _clearDateTime() {
    HapticFeedback.lightImpact();
    setState(() {
      _customDate = null;
      _customTime = null;
    });
  }

  // ─── AD-UNLOCK GATE (same pattern as template styles) ───────────────────────

  void _showAdUnlockDialog() {
    // Snapshot address NOW before showing dialog (geocoding may still be running).
    final snapshotAddress = _isGeocodingAddress
        ? _fallbackLabel(_pinnedLatLng)
        : _pinnedAddress;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unlock Edit Location',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Watch a quick ad to manually pin your location for 24 hours!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              _watchAdToUnlock(snapshotAddress);
            },
            child: const Text('WATCH AD',
                style: TextStyle(
                    color: Color(0xFF0F1A24), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _watchAdToUnlock(String address) {
    if (_adService.isRewardedInterstitialReady()) {
      _adService.showRewardedInterstitialAd(
        onUserEarnedReward: (ad, reward) {
          // Grant ONE custom geo edit (one-shot — consumed on confirm).
          _settings.hasOneTimeGeoEdit = true;
          // Immediately allow them to confirm.
          if (mounted) _confirmLocationWithAddress(address);
        },
      );
    } else {
      // Capture messenger before the async gap.
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Ad not ready. Please try again.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: Color(0xFF1A2332),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      );
    }
  }

  // ─── TILE URLs ───────────────────────────────────────────────────────────────
  // Esri World Imagery satellite (free, no API key required)
  String get _satelliteUrl =>
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  // Labels overlay — rendered on top so street names are readable on satellite
  String get _labelsUrl =>
      'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png';

  // ─── MY LOCATION ───────────────────────────────────────────────────────────────
  void _flyToMyLocation() {
    final pos = _locationService.lastPosition;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'GPS position not available yet.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: Color(0xFF1A2332),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    final here = LatLng(pos.latitude, pos.longitude);
    _mapController.move(here, 16.0);
    setState(() {
      _pinnedLatLng = here;
      _pinnedAddress = 'Finding address…';
    });
    _reverseGeocode(here);
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: GestureDetector(
        // Dismiss keyboard + suggestions when tapping the map area
        onTap: () {
          if (_showSuggestions || _searchFocus.hasFocus) {
            FocusScope.of(context).unfocus();
            setState(() { _showSuggestions = false; });
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
          // ── MAP ──────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pinnedLatLng,
              initialZoom: 15.0,
              maxZoom: 18.0,
              minZoom: 3.0,
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                if (hasGesture) {
                  _onMapMove(camera.center, hasGesture);
                }
              },
            ),
            children: [
              // Satellite base layer
              TileLayer(
                urlTemplate: _satelliteUrl,
                userAgentPackageName: 'com.geocam.app',
                maxZoom: 20,
              ),
              // Labels overlay (street names, POI labels readable on satellite)
              TileLayer(
                urlTemplate: _labelsUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.geocam.app',
                maxZoom: 20,
              ),
              // Show the current GPS fix as a ghost marker.
              if (_locationService.lastPosition != null &&
                  !_locationService.isManualOverrideActive)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(
                      _locationService.lastPosition!.latitude,
                      _locationService.lastPosition!.longitude,
                    ),
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ]),
            ],
          ),

          // ── CROSSHAIR / ANIMATED PIN in map centre ───────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _pinBounce,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _isDragging ? -8 : _pinBounce.value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pin head
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.edit_location_alt,
                          color: Color(0xFF0F1A24), size: 20),
                    ),
                    // Pin needle
                    CustomPaint(
                      size: const Size(14, 10),
                      painter: _PinNeedlePainter(color: AppColors.primary),
                    ),
                    // Shadow ellipse
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isDragging ? 8 : 14,
                      height: _isDragging ? 4 : 6,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── TOP APP BAR ──────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      border: Border(
                          bottom: BorderSide(color: Colors.white12, width: 1)),
                    ),
                    child: Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'GEOCAM PRO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.editLocationTitle,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Clear GPS override button
                        if (_locationService.isManualOverrideActive)
                          GestureDetector(
                            onTap: _clearOverride,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.error.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.gps_fixed,
                                      color: AppColors.error, size: 14),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      AppLocalizations.of(context)!.editLocationClearBtn.toUpperCase(),
                                      style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── SEARCH BAR AND SUGGESTIONS ───────────────────────────────────────
          Positioned(
            top: topPadding + 90,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.search, color: Colors.white54, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.editLocationSearch,
                            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          onSubmitted: _performSearch,
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            FocusScope.of(context).unfocus();
                          },
                        ),
                    ],
                  ),
                ),
                
                // Suggestions Dropdown — animated fade + slide
                if (_showSuggestions && _suggestions.isNotEmpty)
                  SlideTransition(
                    position: _suggSlide,
                    child: FadeTransition(
                      opacity: _suggFade,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 280),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                                itemBuilder: (context, index) {
                                  final s = _suggestions[index];
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: index == 0
                                          ? const BorderRadius.vertical(top: Radius.circular(12))
                                          : index == _suggestions.length - 1
                                              ? const BorderRadius.vertical(bottom: Radius.circular(12))
                                              : BorderRadius.zero,
                                      onTap: () => _onSuggestionSelected(s),
                                      splashColor: AppColors.primary.withValues(alpha: 0.15),
                                      highlightColor: AppColors.primary.withValues(alpha: 0.08),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                s['display_name'] ?? '',
                                                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(Icons.north_east, color: Colors.white30, size: 14),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── MY LOCATION FAB ───────────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 200,
            child: GestureDetector(
              onTap: _flyToMyLocation,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location, color: Colors.white, size: 22),
              ),
            ),
          ),

          // ── BOTTOM PANEL ─────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                      border: Border.all(color: Colors.white10, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coordinates row
                        Row(
                          children: [
                            const Icon(Icons.my_location,
                                color: AppColors.primary, size: 14),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${_pinnedLatLng.latitude.toStringAsFixed(6)}°, '
                                '${_pinnedLatLng.longitude.toStringAsFixed(6)}°',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Address row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Colors.white54, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _isGeocodingAddress
                                  ? Row(children: [
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 1.5),
                                      ),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text('Finding address…',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 13)))
                                    ])
                                  : Text(
                                      _pinnedAddress,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // ── DATE & TIME EDITOR ─────────────────────────────
                        _buildDateTimeRow(),
                        const SizedBox(height: 20),
                        // Use This Location button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            // Only block while actively dragging (pin still moving).
                            // Geocoding runs in background — no longer a blocker.
                            onPressed: _isDragging
                                ? null
                                 : () {
                                    // Snapshot the address now. If geocoding is still
                                    // running, use coordinate string as fallback.
                                    final address = _isGeocodingAddress
                                        ? _fallbackLabel(_pinnedLatLng)
                                        : _pinnedAddress;
                                    // ── ALWAYS save the custom date/time first ──
                                    // Date/time editing is free. Only the location
                                    // pin override is gated behind premium/ad.
                                    if (_customDate != null || _customTime != null) {
                                      final date = _customDate ?? DateTime.now();
                                      final time = _customTime ?? TimeOfDay.now();
                                      final combined = DateTime(
                                        date.year, date.month, date.day,
                                        time.hour, time.minute,
                                      );
                                      _locationService.setManualDateTime(combined);
                                    } else {
                                      _locationService.clearManualDateTime();
                                    }

                                    // ── Then gate the LOCATION override ──
                                    // Real subscribers always allowed.
                                    // Reward watchers get one-shot access.
                                    if (_settings.isRealSubscriptionActive ||
                                        _settings.hasOneTimeGeoEdit) {
                                      _confirmLocationWithAddress(address);
                                    } else {
                                      _showAdUnlockDialog();
                                    }
                                  },
                            icon: const Icon(Icons.check_circle_outline,
                                size: 20),
                            label: Text(
                              AppLocalizations.of(context)!.editLocationConfirm.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: const Color(0xFF0F1A24),
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

   // ─── DATE & TIME ROW WIDGET ──────────────────────────────────────────────

  Widget _buildDateTimeRow() {
    final hasDate = _customDate != null;
    final hasTime = _customTime != null;
    final isCustom = hasDate || hasTime;

    final dateLabel = hasDate
        ? DateFormat('MMM d, yyyy').format(_customDate!)
        : 'Set Date';
    final timeLabel = hasTime
        ? _customTime!.format(context)
        : 'Set Time';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.schedule, color: AppColors.primary, size: 14),
            const SizedBox(width: 8),
            Flexible(
              child: const Text(
                'CAPTURE DATE & TIME',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            // "CUSTOM" badge when overriding
            if (isCustom)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'CUSTOM',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            const Spacer(),
            // Clear button
            if (isCustom)
              GestureDetector(
                onTap: _clearDateTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, color: Colors.redAccent, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Date + Time pill buttons
        Row(
          children: [
            // ── Date pill ──────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 46,
                  decoration: BoxDecoration(
                    color: hasDate
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasDate
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : Colors.white24,
                      width: hasDate ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: hasDate ? AppColors.primary : Colors.white54,
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            color: hasDate ? Colors.white : Colors.white54,
                            fontSize: 13,
                            fontWeight: hasDate
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ── Time pill ──────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: _pickTime,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 46,
                  decoration: BoxDecoration(
                    color: hasTime
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasTime
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : Colors.white24,
                      width: hasTime ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: hasTime ? AppColors.primary : Colors.white54,
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          timeLabel,
                          style: TextStyle(
                            color: hasTime ? Colors.white : Colors.white54,
                            fontSize: 13,
                            fontWeight: hasTime
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Helper note
        if (!isCustom)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Optional — leave blank to use current system time',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.3),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

}

/// Draws the downward triangle "needle" of the custom pin.
class _PinNeedlePainter extends CustomPainter {
  final Color color;
  const _PinNeedlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
