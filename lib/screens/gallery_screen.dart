import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme/app_theme.dart';
import '../models/photo_model.dart';
import '../services/database_service.dart';
import '../services/ad_service.dart';
import '../services/settings_service.dart';
import '../widgets/photo_grid_tile.dart';
import 'photo_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AdService _adService = AdService();
  final SettingsService _settings = SettingsService();
  bool _isLoading = true;
  List<Photo> _photos = [];
  Map<String, List<Photo>> _groupedPhotos = {};
  StreamSubscription<void>? _dbSubscription;
  
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    
    _loadPhotos();
    _loadBannerAd();
    
    // Listen for database changes (captured in background)
    _dbSubscription = _databaseService.onChange.listen((_) {
      if (mounted) _loadPhotos();
    });
  }

  void _loadBannerAd() {
    _bannerAd = _adService.createBannerAd(
      size: AdSize.banner,
      onLoaded: () => setState(() => _isBannerAdLoaded = true),
      onFailed: (error) => debugPrint('Banner failed: $error'),
    );
    _bannerAd?.load();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    final photos = await _databaseService.getAllPhotos();
    
    // Group photos by date
    final Map<String, List<Photo>> grouped = {};
    for (var photo in photos) {
      final dateStr = DateFormat('MMMM d, yyyy').format(photo.capturedAt);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(photo);
    }

    setState(() {
      _photos = photos;
      _groupedPhotos = grouped;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _photos.isEmpty
                      ? _buildEmptyState()
                      : _buildPhotoGrid(),
            ),
            // Adaptive Banner Ad
            if (_isBannerAdLoaded && _bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: _bannerAd!.size.height.toDouble(),
                color: AppColors.backgroundDark,
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Gallery',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Captured with GPS',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadPhotos,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 24),
          const Text(
            'No photos captured yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Take some photos with the camera\nto see them here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final dates = _groupedPhotos.keys.toList();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final photos = _groupedPhotos[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
              child: Text(
                date.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: photos.length,
              itemBuilder: (context, pIndex) {
                final photo = photos[pIndex];
                return PhotoGridTile(
                  photo: photo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoDetailScreen(photo: photo),
                      ),
                    ).then((_) => _loadPhotos());
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
