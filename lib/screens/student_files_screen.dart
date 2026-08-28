import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

Future<void> _launchUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !await canLaunchUrl(uri)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تعذّر فتح الرابط', style: GoogleFonts.cairo()),
        backgroundColor: AppColors.danger,
      ));
    }
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class StudentFilesScreen extends StatelessWidget {
  final String studentId;
  const StudentFilesScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ملفاتي الخاصة',
            style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<List<StudentFile>>(
        stream: FirestoreService.instance.watchStudentFiles(studentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final files = snapshot.data ?? [];
          if (files.isEmpty) {
            return _emptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpace.md),
            itemCount: files.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpace.sm),
            itemBuilder: (ctx, i) => _FileCard(file: files[i]),
          );
        },
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open_rounded,
                  size: 56, color: AppColors.inkMuted),
              const SizedBox(height: AppSpace.md),
              Text('لا توجد ملفات خاصة بعد',
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('ستظهر هنا الملفات التي يرسلها المعلم إليك',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.inkMuted)),
            ],
          ),
        ),
      );
}

class _FileCard extends StatelessWidget {
  final StudentFile file;
  const _FileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.danger, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.title,
                    style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                if (file.uploadedAt != null)
                  Text(
                    'تم الإرسال: ${file.uploadedAt!.day}/${file.uploadedAt!.month}/${file.uploadedAt!.year}',
                    style: GoogleFonts.cairo(
                        fontSize: 10.5, color: AppColors.inkMuted),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _actionBtn(
                      context,
                      icon: Icons.visibility_outlined,
                      label: 'معاينة',
                      filled: false,
                    ),
                    const SizedBox(width: 8),
                    _actionBtn(
                      context,
                      icon: Icons.download_rounded,
                      label: 'تحميل',
                      filled: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: () => _launchUrl(context, file.url),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: filled ? Colors.white : AppColors.primary),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        filled ? Colors.white : AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
