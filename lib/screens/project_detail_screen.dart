import 'dart:async';
import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_grid_tile.dart';
import '../widgets/project_picker_sheet.dart';
import '../widgets/report_flow.dart';
import 'photo_detail_screen.dart';

/// Shows the photos in a project, with rename and delete actions.
class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Project _project = widget.project;
  List<Photo>? _photos;
  StreamSubscription<void>? _dbSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _dbSubscription = _databaseService.onChange.listen((_) => _load());
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final project = await _databaseService.getProjectById(_project.id);
    if (project == null) return; // deleted — we're popping
    final photos = await _databaseService.getPhotosByProject(project.id);
    if (mounted) {
      setState(() {
        _project = project;
        _photos = photos;
      });
    }
  }

  Future<void> _rename() async {
    final name = await showRenameProjectDialog(context, _project);
    if (name == null || name == _project.name) return;
    await _databaseService.renameProject(_project.id, name);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Delete "${_project.name}"?', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'The project is removed. Its photos are kept and moved to "No project".',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _databaseService.deleteProject(_project.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Row(
          children: [
            Icon(Icons.folder, color: Color(_project.color), size: 20),
            const SizedBox(width: 8),
            Flexible(child: Text(_project.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Generate report',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: (photos == null || photos.isEmpty)
                ? null
                : () => startReportFlow(context, photos, projectName: _project.name),
          ),
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _rename,
          ),
          IconButton(
            tooltip: 'Delete project',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _delete,
          ),
        ],
      ),
      body: photos == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : photos.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No photos in this project yet.\nSelect it from the folder pill on the camera, '
                      'or move photos here from the gallery.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return PhotoGridTile(
                      photo: photo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoDetailScreen(photo: photo),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
