import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../services/permission_service.dart';
import '../services/settings_service.dart';
import 'home_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final PermissionService _permissionService = PermissionService();

  bool _cameraGranted = false;
  bool _locationGranted = false;
  bool _storageGranted = false;
  bool _storageIsLimited = false; // Android 14+ limited/partial photo access
  bool _isLoading = false;

  // The app can proceed once camera + location + storage (or limited storage) are all granted.
  bool get _canProceed => _cameraGranted && _locationGranted && (_storageGranted || _storageIsLimited);

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final status = await _permissionService.getPermissionStatus();
    // Also check raw limited status for Android 14+ UI
    bool limited = false;
    try {
      final photosStatus = await Permission.photos.status;
      limited = photosStatus.isLimited;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _cameraGranted = status['camera'] ?? false;
      _locationGranted = status['location'] ?? false;
      _storageGranted = status['storage'] ?? false;
      _storageIsLimited = limited && !_storageGranted;
    });
  }

  Future<void> _handleGrantAll() async {
    setState(() => _isLoading = true);
    await _permissionService.requestAllPermissions();
    await _refreshStatus();
    if (!mounted) return;
    setState(() => _isLoading = false);
    // Auto-advance when both required permissions are granted
    if (_canProceed) _proceed();
  }

  Future<void> _handlePermissionTap(String type) async {
    setState(() => _isLoading = true);
    switch (type) {
      case 'camera':
        final ok = await _permissionService.requestCameraPermission();
        if (mounted) setState(() => _cameraGranted = ok);
        break;
      case 'location':
        final ok = await _permissionService.requestLocationPermission();
        if (mounted) setState(() => _locationGranted = ok);
        break;
      case 'storage':
        final ok = await _permissionService.requestMediaPermission();
        // Detect limited separately for amber UI badge
        bool limited = false;
        try {
          final photosStatus = await Permission.photos.status;
          limited = photosStatus.isLimited;
        } catch (_) {}
        if (mounted) setState(() {
          _storageGranted = ok;
          _storageIsLimited = limited && !ok;
        });
        break;
    }
    if (mounted) setState(() => _isLoading = false);
    if (_canProceed) _proceed();
  }

  void _proceed() {
    SettingsService().hasSeenOnboarding = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.security_outlined,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'App Permissions',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'GEOCAM PRO needs the following permissions to function. Your data stays private and on-device.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Permission Cards ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _PermissionTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Camera',
                      description: 'Take geo-tagged photos with GPS overlays.',
                      badge: 'Required',
                      badgeColor: const Color(0xFFEF4444),
                      isGranted: _cameraGranted,
                      isLoading: _isLoading,
                      onTap: _cameraGranted ? null : () => _handlePermissionTap('camera'),
                    ),
                    const SizedBox(height: 12),
                    _PermissionTile(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      description: 'Embed GPS coordinates and address in your photos.',
                      badge: 'Required',
                      badgeColor: const Color(0xFFEF4444),
                      isGranted: _locationGranted,
                      isLoading: _isLoading,
                      onTap: _locationGranted ? null : () => _handlePermissionTap('location'),
                    ),
                    const SizedBox(height: 12),
                    _PermissionTile(
                      icon: Icons.photo_library_outlined,
                      title: 'Photos / Storage',
                      description: _storageIsLimited
                          ? 'Limited access granted — only selected photos visible.'
                          : 'Read gallery photos. Saving to gallery is handled automatically by Android on OS 10+.',
                      badge: _storageGranted ? 'Granted' : (_storageIsLimited ? 'Limited' : 'Required'),
                      badgeColor: _storageGranted
                          ? AppColors.primary
                          : (_storageIsLimited ? Colors.amber : const Color(0xFFEF4444)),
                      isGranted: _storageGranted || _storageIsLimited,
                      isLoading: _isLoading,
                      onTap: (_storageGranted || _storageIsLimited)
                          ? null
                          : () => _handlePermissionTap('storage'),
                    ),
                    const SizedBox(height: 24),

                    // Play-policy notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white38, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Only "when in use" location is used — never background. '
                              'No data is uploaded to servers. '
                              'You can change permissions any time in device Settings.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Actions ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  else
                    PrimaryButton(
                      label: _canProceed ? 'Get Started' : 'Grant Permissions',
                      icon: _canProceed ? Icons.arrow_forward : Icons.lock_open_outlined,
                      onPressed: _canProceed ? _proceed : _handleGrantAll,
                    ),
                  if (_canProceed) ...[
                    const SizedBox(height: 8),
                    Text(
                      'All required permissions granted ✓',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Permission Tile ───────────────────────────────────────────────

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final Color badgeColor;
  final bool isGranted;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.isGranted,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isGranted
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: (!isGranted && !isLoading) ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon bubble
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isGranted
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGranted ? Icons.check_circle_outline : icon,
                    color: isGranted ? AppColors.primary : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isGranted ? Colors.white : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isGranted
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isGranted ? 'Granted' : badge,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isGranted ? AppColors.primary : badgeColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron
                if (!isGranted)
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.25),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
