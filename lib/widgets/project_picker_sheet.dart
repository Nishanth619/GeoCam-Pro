import 'package:flutter/material.dart';
import '../models/project.dart';
import '../screens/premium_screen.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Free users may create this many projects; more requires Pro.
const int kFreeProjectLimit = 1;

/// Prompts for a new project's name and colour and creates it.
/// Free users who already have [kFreeProjectLimit] projects are sent to the
/// premium screen instead. Returns the new project, or null if cancelled.
Future<Project?> showCreateProjectDialog(BuildContext context) async {
  final db = DatabaseService();
  final settings = SettingsService();

  final existing = await db.getAllProjects();
  if (!context.mounted) return null;
  if (!settings.hasFeatureAccess && existing.length >= kFreeProjectLimit) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PremiumScreen()),
    );
    return null;
  }

  final result = await showDialog<({String name, int color})>(
    context: context,
    builder: (context) => _ProjectNameDialog(
      title: 'New project',
      confirmLabel: 'Create',
      initialColor: Project.palette[existing.length % Project.palette.length],
    ),
  );
  if (result == null) return null;
  return db.createProject(result.name, result.color);
}

/// Prompts for a new name for [project]. Returns the trimmed name or null.
Future<String?> showRenameProjectDialog(BuildContext context, Project project) async {
  final result = await showDialog<({String name, int color})>(
    context: context,
    builder: (context) => _ProjectNameDialog(
      title: 'Rename project',
      confirmLabel: 'Save',
      initialName: project.name,
      initialColor: project.color,
      showColors: false,
    ),
  );
  return result?.name;
}

/// Bottom sheet listing projects with a "No project" option and "+ New".
/// Returns `(projectId: ...)` for a choice (projectId null = no project),
/// or null if the sheet was dismissed.
Future<({String? projectId})?> showProjectPickerSheet(
  BuildContext context, {
  required String? selectedId,
  String title = 'Save photos to',
}) {
  return showModalBottomSheet<({String? projectId})>(
    context: context,
    backgroundColor: AppColors.cardDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ProjectPickerSheet(selectedId: selectedId, title: title),
  );
}

class _ProjectPickerSheet extends StatefulWidget {
  final String? selectedId;
  final String title;

  const _ProjectPickerSheet({required this.selectedId, required this.title});

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  List<Project>? _projects;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final projects = await DatabaseService().getAllProjects();
    if (mounted) setState(() => _projects = projects);
  }

  Future<void> _createProject() async {
    final project = await showCreateProjectDialog(context);
    if (project != null && mounted) {
      Navigator.pop(context, (projectId: project.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = _projects;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (projects == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _ProjectOption(
                      icon: Icons.folder_off_outlined,
                      color: AppColors.textSecondary,
                      label: 'No project',
                      selected: widget.selectedId == null,
                      onTap: () => Navigator.pop(context, (projectId: null)),
                    ),
                    for (final project in projects)
                      _ProjectOption(
                        icon: Icons.folder,
                        color: Color(project.color),
                        label: project.name,
                        selected: project.id == widget.selectedId,
                        onTap: () => Navigator.pop(context, (projectId: project.id)),
                      ),
                  ],
                ),
              ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.create_new_folder_outlined, color: AppColors.primary),
              title: const Text(
                'New project',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
              trailing: projects != null &&
                      projects.length >= kFreeProjectLimit &&
                      !SettingsService().hasFeatureAccess
                  ? const Icon(Icons.lock_rounded, color: AppColors.primary, size: 18)
                  : null,
              onTap: _createProject,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ProjectOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProjectOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: selected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
      onTap: onTap,
    );
  }
}

class _ProjectNameDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialName;
  final int initialColor;
  final bool showColors;

  const _ProjectNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialColor,
    this.initialName = '',
    this.showColors = true,
  });

  @override
  State<_ProjectNameDialog> createState() => _ProjectNameDialogState();
}

class _ProjectNameDialogState extends State<_ProjectNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);
  late int _color = widget.initialColor;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, (name: name, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. 12 Oak St — Roof inspection',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.showColors) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in Project.palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == _color ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: Text(widget.confirmLabel,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
