import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';
import '../services/ad_service.dart';

class TemplateCustomizationSheet extends StatefulWidget {
  const TemplateCustomizationSheet({super.key});

  @override
  State<TemplateCustomizationSheet> createState() => _TemplateCustomizationSheetState();
}

class _TemplateCustomizationSheetState extends State<TemplateCustomizationSheet> {
  final SettingsService _settings = SettingsService();
  final AdService _adService = AdService();
  
  late int _selectedMapType;
  late bool _showAddress;
  late bool _showCoordinates;
  late bool _showCompass;
  late bool _showDateTime;
  late String _dateFormat;
  late String _coordFormat;

  final List<String> _mapTypes = ['Normal', 'Satellite', 'Terrain', 'Hybrid'];
  final List<String> _dateFormats = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];
  final List<String> _coordFormats = ['Decimal Degrees (DD)', 'Degrees Minutes Seconds (DMS)'];

  @override
  void initState() {
    super.initState();
    _selectedMapType = _settings.templateMapType;
    _showAddress = _settings.templateShowAddress;
    _showCoordinates = _settings.templateShowCoordinates;
    _showCompass = _settings.templateShowCompass;
    _showDateTime = _settings.templateShowDateTime;
    _dateFormat = _settings.templateDateFormat;
    _coordFormat = _settings.templateCoordFormat;
  }

  void _saveAndClose() {
    _settings.templateMapType = _selectedMapType;
    _settings.templateShowAddress = _showAddress;
    _settings.templateShowCoordinates = _showCoordinates;
    _settings.templateShowCompass = _showCompass;
    _settings.templateShowDateTime = _showDateTime;
    _settings.templateDateFormat = _dateFormat;
    _settings.templateCoordFormat = _coordFormat;
    
    Navigator.pop(context);
    _adService.showInterstitialAd();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Professional settings applied'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: Colors.white10, width: 1.5),
              ),
              child: Column(
                children: [
                  // Branded Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'GEOCAM PRO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Template Customization',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const SizedBox(height: 8),
                        _buildSectionHeader('CHOOSE MAP STYLE', Icons.auto_awesome),
                        const SizedBox(height: 16),
                        _buildMapTypeCarousel(),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('DATA FIELDS VISIBILITY', Icons.view_quilt_outlined),
                        const SizedBox(height: 16),
                        _DataFieldToggle(
                          icon: Icons.location_on_outlined,
                          label: 'Full Address',
                          value: _showAddress,
                          onChanged: (v) => setState(() => _showAddress = v),
                        ),
                        _DataFieldToggle(
                          icon: Icons.my_location_outlined,
                          label: 'GPS Coordinates',
                          value: _showCoordinates,
                          onChanged: (v) => setState(() => _showCoordinates = v),
                        ),
                        _DataFieldToggle(
                          icon: Icons.explore_outlined,
                          label: 'Compass & Heading',
                          value: _showCompass,
                          onChanged: (v) => setState(() => _showCompass = v),
                        ),
                        _DataFieldToggle(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date & Time Stamp',
                          value: _showDateTime,
                          onChanged: (v) => setState(() => _showDateTime = v),
                        ),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('DISPLAY FORMATS', Icons.settings_outlined),
                        const SizedBox(height: 16),
                        _FormatSelector(
                          label: 'Date Display',
                          options: _dateFormats,
                          selectedValue: _dateFormat,
                          onChanged: (v) => setState(() => _dateFormat = v),
                        ),
                        const SizedBox(height: 16),
                        _FormatSelector(
                          label: 'Coordinate Precision',
                          options: _coordFormats,
                          selectedValue: _coordFormat,
                          onChanged: (v) => setState(() => _coordFormat = v),
                        ),
                        
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _saveAndClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: const Color(0xFF102219),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          child: const Text('APPLY TEMPLATE'),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildMapTypeCarousel() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _mapTypes.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedMapType;
          return GestureDetector(
            onTap: () {
              // If it's already selected, do nothing
              if (index == _selectedMapType) return;
              
              // Hybrid (Index 3) is FREE by default
              // All others are locked if premium is not active
              if (index != 3 && !_settings.isPremiumUnlocked) {
                _showAdUnlockDialog(index);
                return;
              }
              
              setState(() => _selectedMapType = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 100,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.white12,
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _getMapIcon(index),
                          color: isSelected ? const Color(0xFF102219) : Colors.white70,
                          size: 26,
                        ),
                        // Lock icon for non-free styles if not unlocked
                        if (index != 3 && !_settings.isPremiumUnlocked)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Icon(Icons.lock, size: 14, color: isSelected ? Colors.black : AppColors.primary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _mapTypes[index].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: isSelected ? const Color(0xFF102219) : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAdUnlockDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF102219),
        title: const Text('Unlock Premium Styles', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Watch a quick ad to unlock all premium template styles for 24 hours!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              _unlockWithAd(index);
            },
            child: const Text('WATCH AD', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _unlockWithAd(int index) {
    if (_adService.isRewardedInterstitialReady()) {
      _adService.showRewardedInterstitialAd(
        onUserEarnedReward: (ad, reward) {
          setState(() {
            _settings.rewardExpiration = DateTime.now().add(const Duration(hours: 24));
            _selectedMapType = index;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Premium Styles unlocked for 24 hours!')),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready, please try again.')),
      );
    }
  }

  IconData _getMapIcon(int index) {
    switch (index) {
      case 0: return Icons.map_outlined;
      case 1: return Icons.satellite_outlined;
      case 2: return Icons.terrain_outlined;
      case 3: return Icons.layers_outlined;
      default: return Icons.map;
    }
  }
}

class _DataFieldToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DataFieldToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? AppColors.primary : Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatSelector extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _FormatSelector({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            dropdownColor: const Color(0xFF102219),
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more, color: AppColors.primary, size: 20),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
