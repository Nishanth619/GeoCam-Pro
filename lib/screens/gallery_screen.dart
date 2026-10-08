import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme/app_theme.dart';
import '../models/photo_model.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../services/ad_service.dart';
import '../services/settings_service.dart';
import '../widgets/photo_grid_tile.dart';
import '../widgets/soft_paywall_banner.dart';
import '../widgets/project_picker_sheet.dart';
import 'package:geocam_flutter/l10n/app_localizations.dart';
import 'photo_detail_screen.dart';
import 'project_detail_screen.dart';

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

  // Project filter (null = all photos)
  List<Project> _projects = [];
  String? _filterProjectId;

  // Multi-select
  bool _selectMode = false;
  final Set<int> _selectedIds = {};
  

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    
    // Listen for database changes (captured in background)
    _dbSubscription = _databaseService.onChange.listen((_) {
      if (mounted) _loadPhotos();
    });
  }


  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    final projects = await _databaseService.getAllProjects();
    if (_filterProjectId != null && !projects.any((p) => p.id == _filterProjectId)) {
      _filterProjectId = null; // filtered project was deleted
    }
    final photos = _filterProjectId == null
        ? await _databaseService.getAllPhotos()
        : await _databaseService.getPhotosByProject(_filterProjectId!);
    if (!mounted) return;
    
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
      _projects = projects;
      _photos = photos;
      _groupedPhotos = grouped;
      _selectedIds.retainAll(photos.map((p) => p.id));
      _isLoading = false;
    });
  }

  void _setFilter(String? projectId) {
    if (_filterProjectId == projectId) return;
    _filterProjectId = projectId;
    _loadPhotos();
  }

  Future<void> _createProject() async {
    final project = await showCreateProjectDialog(context);
    if (project != null) _setFilter(project.id);
  }

  void _openProjectDetail(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProjectDetailScreen(project: project)),
    ).then((_) => _loadPhotos());
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(Photo photo) {
    final id = photo.id;
    if (id == null) return;
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  Future<void> _moveSelectedToProject() async {
    final choice = await showProjectPickerSheet(
      context,
      selectedId: _filterProjectId,
      title: 'Move ${_selectedIds.length} photo(s) to',
    );
    if (choice == null) return;
    await _databaseService.assignPhotosToProject(_selectedIds.toList(), choice.projectId);
    if (!mounted) return;
    setState(() {
      _selectMode = false;
      _selectedIds.clear();
    });
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      bottomNavigationBar: _selectMode ? _buildSelectionBar() : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildProjectFilterBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _photos.isEmpty
                      ? _buildEmptyState()
                      : _buildPhotoGrid(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.galleryTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.galleryCapturedWith,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_filterProjectId != null)
                IconButton(
                  tooltip: 'Project details',
                  icon: const Icon(Icons.folder_open, color: AppColors.primary),
                  onPressed: () => _openProjectDetail(
                    _projects.firstWhere((p) => p.id == _filterProjectId),
                  ),
                ),
              IconButton(
                tooltip: _selectMode ? 'Cancel selection' : 'Select',
                icon: Icon(
                  _selectMode ? Icons.close : Icons.checklist_rounded,
                  color: AppColors.primary,
                ),
                onPressed: _photos.isEmpty && !_selectMode ? null : _toggleSelectMode,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _loadPhotos,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _FilterChip(
            label: 'All Photos',
            selected: _filterProjectId == null,
            onTap: () => _setFilter(null),
          ),
          for (final project in _projects)
            _FilterChip(
              label: project.name,
              color: Color(project.color),
              selected: _filterProjectId == project.id,
              onTap: () => _setFilter(project.id),
              onLongPress: () => _openProjectDetail(project),
            ),
          _FilterChip(
            label: 'New',
            icon: Icons.add,
            selected: false,
            onTap: _createProject,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    final count = _selectedIds.length;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.cardDark,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$count selected',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: count == 0 ? null : _moveSelectedToProject,
              icon: const Icon(Icons.drive_file_move_outline),
              label: const Text('Move'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
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
          Text(
            _filterProjectId != null
                ? 'No photos in this project'
                : AppLocalizations.of(context)!.galleryEmpty,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.galleryEmptyHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                  showCheckbox: _selectMode,
                  isSelected: _selectMode && _selectedIds.contains(photo.id),
                  onLongPress: _selectMode
                      ? null
                      : () {
                          setState(() => _selectMode = true);
                          _toggleSelected(photo);
                        },
                  onTap: () {
                    if (_selectMode) {
                      _toggleSelected(photo);
                      return;
                    }
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? AppColors.primary : AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? Colors.black : AppColors.primary),
                const SizedBox(width: 4),
              ] else if (color != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.black
                        : (icon != null ? AppColors.primary : Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
