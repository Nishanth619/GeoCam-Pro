import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/photo_model.dart';

class PhotoGridTile extends StatelessWidget {
  final Photo photo;
  final bool isSelected;
  /// Select mode: shows an empty circle on unselected tiles.
  final bool showCheckbox;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PhotoGridTile({
    super.key,
    required this.photo,
    this.isSelected = false,
    this.showCheckbox = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(photo.imagePath);
    final exists = file.existsSync();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo content
            exists
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    cacheWidth: 300,  // Optimize memory for grid
                    cacheHeight: 300, // Square grid tiles — constrain both axes
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
            
            // Premium glass overlay (subtle)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),

            // Location indicator
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 10,
                ),
              ),
            ),

            // Empty checkbox in select mode
            if (showCheckbox && !isSelected)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),

            // Selection indicator
            if (isSelected)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.cardBorder,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textMuted,
          size: 24,
        ),
      ),
    );
  }
}
