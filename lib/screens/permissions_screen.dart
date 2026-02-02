import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/permission_card.dart';
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
  
  bool _locationEnabled = false;
  bool _cameraEnabled = false;
  bool _storageEnabled = false;
  bool _isLoading = false;

  bool get _allPermissionsGranted => _locationEnabled && _cameraEnabled && _storageEnabled;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final status = await _permissionService.getPermissionStatus();
    if (mounted) {
      setState(() {
        _locationEnabled = status['location'] ?? false;
        _cameraEnabled = status['camera'] ?? false;
        _storageEnabled = status['storage'] ?? false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);
    final granted = await _permissionService.requestLocationPermission();
    if (mounted) {
      setState(() {
        _locationEnabled = granted;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    setState(() => _isLoading = true);
    final granted = await _permissionService.requestCameraPermission();
    if (mounted) {
      setState(() {
        _cameraEnabled = granted;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestStoragePermission() async {
    setState(() => _isLoading = true);
    final granted = await _permissionService.requestStoragePermission();
    if (mounted) {
      setState(() {
        _storageEnabled = granted;
        _isLoading = false;
      });
    }
  }

  void _getStarted() {
    // Set onboarding as completed
    SettingsService().hasSeenOnboarding = true;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(isActive: false),
                  const SizedBox(width: 12),
                  _buildDot(isActive: true, isLong: true),
                  const SizedBox(width: 12),
                  _buildDot(isActive: false),
                ],
              ),
            ),
            // Header text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Enable Permissions',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To capture geo-tagged photos and access full features, we need access to your device\'s sensors.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Permission cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    PermissionCard(
                      icon: Icons.location_on,
                      title: 'Location Access',
                      subtitle: _locationEnabled 
                          ? 'Permission granted'
                          : 'Required for GPS data overlay',
                      isEnabled: _locationEnabled,
                      onChanged: (value) async {
                        if (value && !_locationEnabled) {
                          await _requestLocationPermission();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    PermissionCard(
                      icon: Icons.camera_alt,
                      title: 'Camera Access',
                      subtitle: _cameraEnabled 
                          ? 'Permission granted'
                          : 'Required to take photos',
                      isEnabled: _cameraEnabled,
                      onChanged: (value) async {
                        if (value && !_cameraEnabled) {
                          await _requestCameraPermission();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    PermissionCard(
                      icon: Icons.folder_open,
                      title: 'Storage Access',
                      subtitle: _storageEnabled 
                          ? 'Permission granted'
                          : 'Required to save photos to Gallery',
                      isEnabled: _storageEnabled,
                      onChanged: (value) async {
                        if (value && !_storageEnabled) {
                          await _requestStoragePermission();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    else
                      Text(
                        'You can change these settings later in your device settings.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: _allPermissionsGranted ? 'Get Started' : 'Grant Permissions',
                icon: _allPermissionsGranted ? Icons.arrow_forward : Icons.security,
                isDisabled: false,
                onPressed: _allPermissionsGranted 
                    ? _getStarted 
                    : () async {
                        if (!_locationEnabled) await _requestLocationPermission();
                        if (!_cameraEnabled) await _requestCameraPermission();
                        if (!_storageEnabled) await _requestStoragePermission();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive, bool isLong = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 8,
      width: isLong ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
