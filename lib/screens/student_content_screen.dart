import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

Future<void> _launchUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    _showUrlError(context, url);
    return;
  }
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) _showUrlError(context, url);
  }
}

void _showUrlError(BuildContext context, String url) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('تعذّر فتح الرابط: $url', style: GoogleFonts.cairo()),
      backgroundColor: AppColors.danger,
    ),
  );
}

class StudentContentScreen extends StatelessWidget {
  final String groupId;
  final String groupTitle;
  const StudentContentScreen({
    super.key,
    required this.groupId,
    required this.groupTitle,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('المحتوى التعليمي',
              style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.inkMuted,
            labelStyle: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'شروحات الفيديو'),
              Tab(text: 'حلول الواجبات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _VideosTab(groupId: groupId),
            _HomeworkTab(groupId: groupId),
          ],
        ),
      ),
    );
  }
}

// ── Videos Tab ────────────────────────────────────────────────────────────────

class _VideosTab extends StatelessWidget {
  final String groupId;
  const _VideosTab({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LessonVideo>>(
      stream: FirestoreService.instance.watchGroupVideos(groupId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final videos = snap.data ?? [];
        if (videos.isEmpty) {
          return _emptyState(
            icon: Icons.play_circle_outline_rounded,
            msg: 'لا توجد شروحات مضافة بعد',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpace.lg),
          itemCount: videos.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpace.sm),
          itemBuilder: (ctx, i) => _VideoCard(video: videos[i]),
        );
      },
    );
  }
}

class _VideoCard extends StatelessWidget {
  final LessonVideo video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thumbnail area
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Stack(
              children: [
                // YouTube thumbnail if URL contains youtube
                if (video.url.contains('youtube') ||
                    video.url.contains('youtu.be'))
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000).withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.lg),
                        topRight: Radius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white, size: 48),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.smart_display_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(video.title,
                          style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      if (video.uploadedAt != null)
                        Text(
                          '${video.uploadedAt!.day}/${video.uploadedAt!.month}/${video.uploadedAt!.year}',
                          style: GoogleFonts.cairo(
                              fontSize: 10.5, color: AppColors.inkMuted),
                        ),
                    ],
                  ),
                ),
                _watchBtn(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _watchBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchUrl(context, video.url),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text('مشاهدة',
            style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }
}

// ── Homework Tab ──────────────────────────────────────────────────────────────

class _HomeworkTab extends StatelessWidget {
  final String groupId;
  const _HomeworkTab({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeworkFile>>(
      stream: FirestoreService.instance.watchGroupHomework(groupId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final files = snap.data ?? [];
        if (files.isEmpty) {
          return _emptyState(
            icon: Icons.assignment_outlined,
            msg: 'لا توجد حلول مرفوعة بعد',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpace.lg),
          itemCount: files.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpace.sm),
          itemBuilder: (ctx, i) => _HomeworkCard(file: files[i]),
        );
      },
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkFile file;
  const _HomeworkCard({required this.file});

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
            color: AppColors.danger.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    'تم الرفع: ${file.uploadedAt!.day}/${file.uploadedAt!.month}/${file.uploadedAt!.year}',
                    style: GoogleFonts.cairo(
                        fontSize: 10.5, color: AppColors.inkMuted),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _btn(
                      context,
                      icon: Icons.visibility_outlined,
                      label: 'معاينة',
                      filled: false,
                    ),
                    const SizedBox(width: 8),
                    _btn(
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

  Widget _btn(BuildContext context,
      {required IconData icon,
      required String label,
      required bool filled}) {
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
                    color: filled ? Colors.white : AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _emptyState({required IconData icon, required String msg}) =>
    Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.inkMuted),
            const SizedBox(height: AppSpace.md),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.inkMuted)),
          ],
        ),
      ),
    );
