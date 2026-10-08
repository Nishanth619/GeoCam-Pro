import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';
import '../models/photo_model.dart';
import '../screens/premium_screen.dart';
import '../services/report_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Pro: confirm report details, generate the PDF and open the share/print sheet.
Future<void> startReportFlow(
  BuildContext context,
  List<Photo> photos, {
  String? projectName,
}) async {
  final settings = SettingsService();
  if (!settings.hasFeatureAccess) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PremiumScreen()),
    );
    return;
  }
  if (photos.isEmpty) return;

  final messenger = ScaffoldMessenger.of(context);
  if (photos.length > ReportService.maxPhotos) {
    messenger.showSnackBar(SnackBar(
      content: Text('Reports are limited to ${ReportService.maxPhotos} photos — select fewer.'),
      behavior: SnackBarBehavior.floating,
    ));
    return;
  }

  final details = await showDialog<({String project, String company})>(
    context: context,
    builder: (context) => _ReportDetailsDialog(
      photoCount: photos.length,
      initialProject: (projectName?.isNotEmpty ?? false) ? projectName! : settings.defaultProjectName,
      initialCompany: settings.companyName,
    ),
  );
  if (details == null || !context.mounted) return;
  if (details.company != settings.companyName) settings.companyName = details.company;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.cardDark,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 20),
            Expanded(
              child: Text('Generating report…', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ),
  );

  final navigator = Navigator.of(context, rootNavigator: true);
  try {
    final sorted = [...photos]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    final file = await ReportService()
        .generatePdfReport(sorted, details.project, details.company);
    navigator.pop(); // progress
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: path.basename(file.path),
    );
  } catch (e) {
    navigator.pop(); // progress
    debugPrint('Report generation failed: $e');
    messenger.showSnackBar(const SnackBar(
      content: Text('Could not generate the report. Please try again.'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class _ReportDetailsDialog extends StatefulWidget {
  final int photoCount;
  final String initialProject;
  final String initialCompany;

  const _ReportDetailsDialog({
    required this.photoCount,
    required this.initialProject,
    required this.initialCompany,
  });

  @override
  State<_ReportDetailsDialog> createState() => _ReportDetailsDialogState();
}

class _ReportDetailsDialogState extends State<_ReportDetailsDialog> {
  late final _project = TextEditingController(text: widget.initialProject);
  late final _company = TextEditingController(text: widget.initialCompany);

  @override
  void dispose() {
    _project.dispose();
    _company.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: const Text('Generate report', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.photoCount} photo(s) will be included.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _project,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Project name'),
          ),
          TextField(
            controller: _company,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Company name'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            (project: _project.text.trim(), company: _company.text.trim()),
          ),
          child: const Text('Generate',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
