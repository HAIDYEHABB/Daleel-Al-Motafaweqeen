import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Used from the group management Content tab — pre-receives the group,
/// so teacher/admin never has to re-pick it.
class HomeworkUploadScreen extends StatefulWidget {
  final StudyGroup group;
  const HomeworkUploadScreen({super.key, required this.group});

  @override
  State<HomeworkUploadScreen> createState() =>
      _HomeworkUploadScreenState();
}

class _HomeworkUploadScreenState extends State<HomeworkUploadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _hwTitleCtrl = TextEditingController();
  final _hwUrlCtrl = TextEditingController();
  final _vidTitleCtrl = TextEditingController();
  final _vidUrlCtrl = TextEditingController();
  bool _savingHw = false;
  bool _savingVid = false;
  String? _hwError;
  String? _vidError;
  String? _hwSuccess;
  String? _vidSuccess;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hwTitleCtrl.dispose();
    _hwUrlCtrl.dispose();
    _vidTitleCtrl.dispose();
    _vidUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveHomework() async {
    if (_hwTitleCtrl.text.trim().isEmpty) {
      setState(() => _hwError = 'أدخل عنوان حل الواجب');
      return;
    }
    if (_hwUrlCtrl.text.trim().isEmpty) {
      setState(() => _hwError = 'أدخل رابط الملف');
      return;
    }
    setState(() {
      _savingHw = true;
      _hwError = null;
      _hwSuccess = null;
    });
    try {
      await FirestoreService.instance.addGroupHomework(
        groupId: widget.group.id,
        title: _hwTitleCtrl.text.trim(),
        url: _hwUrlCtrl.text.trim(),
      );
      setState(() {
        _hwSuccess = 'تم رفع حل الواجب بنجاح';
        _hwTitleCtrl.clear();
        _hwUrlCtrl.clear();
        _savingHw = false;
      });
    } catch (_) {
      setState(() {
        _hwError = 'حدث خطأ، حاول مرة أخرى';
        _savingHw = false;
      });
    }
  }

  Future<void> _saveVideo() async {
    if (_vidTitleCtrl.text.trim().isEmpty) {
      setState(() => _vidError = 'أدخل عنوان الفيديو');
      return;
    }
    if (_vidUrlCtrl.text.trim().isEmpty) {
      setState(() => _vidError = 'أدخل رابط اليوتيوب');
      return;
    }
    setState(() {
      _savingVid = true;
      _vidError = null;
      _vidSuccess = null;
    });
    try {
      await FirestoreService.instance.addGroupVideo(
        groupId: widget.group.id,
        title: _vidTitleCtrl.text.trim(),
        url: _vidUrlCtrl.text.trim(),
      );
      setState(() {
        _vidSuccess = 'تم إضافة الفيديو بنجاح';
        _vidTitleCtrl.clear();
        _vidUrlCtrl.clear();
        _savingVid = false;
      });
    } catch (_) {
      setState(() {
        _vidError = 'حدث خطأ، حاول مرة أخرى';
        _savingVid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('رفع المحتوى — ${widget.group.title}',
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.inkMuted,
          labelStyle:
              GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'حل الواجب (PDF)'),
            Tab(text: 'شرح فيديو'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HomeworkTab(
            titleCtrl: _hwTitleCtrl,
            urlCtrl: _hwUrlCtrl,
            onSave: _saveHomework,
            saving: _savingHw,
            error: _hwError,
            success: _hwSuccess,
            group: widget.group,
          ),
          _VideoTab(
            titleCtrl: _vidTitleCtrl,
            urlCtrl: _vidUrlCtrl,
            onSave: _saveVideo,
            saving: _savingVid,
            error: _vidError,
            success: _vidSuccess,
            group: widget.group,
          ),
        ],
      ),
    );
  }
}

// ── Homework Tab ──────────────────────────────────────────────────────────────

class _HomeworkTab extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController urlCtrl;
  final VoidCallback onSave;
  final bool saving;
  final String? error;
  final String? success;
  final StudyGroup group;

  const _HomeworkTab({
    required this.titleCtrl,
    required this.urlCtrl,
    required this.onSave,
    required this.saving,
    required this.error,
    required this.success,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        // Target group pill
        Container(
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_2_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'سيُرفع لـ: ${group.title}',
                style: GoogleFonts.cairo(
                    fontSize: 12, color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        _label('عنوان حل الواجب'),
        TextField(
          controller: titleCtrl,
          style: GoogleFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'مثال: حل واجب الأسبوع الخامس',
            hintStyle: GoogleFonts.cairo(
                fontSize: 13, color: AppColors.inkMuted),
            prefixIcon: const Icon(Icons.title_rounded,
                color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _label('رابط ملف PDF'),
        TextField(
          controller: urlCtrl,
          style: GoogleFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'رابط Google Drive أو أي رابط مباشر للـ PDF',
            hintStyle: GoogleFonts.cairo(
                fontSize: 13, color: AppColors.inkMuted),
            prefixIcon: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.danger),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpace.sm),
          _feedback(error!, AppColors.danger, Icons.error_outline),
        ],
        if (success != null) ...[
          const SizedBox(height: AppSpace.sm),
          _feedback(success!, AppColors.success,
              Icons.check_circle_outline),
        ],
        const SizedBox(height: AppSpace.xl),
        saving
            ? const Center(child: CircularProgressIndicator())
            : PrimaryButton(
                label: 'رفع حل الواجب للمجموعة',
                icon: Icons.upload_rounded,
                onPressed: onSave,
              ),
        const SizedBox(height: AppSpace.xl),
        // Existing homework list
        const SectionTitle(title: 'الواجبات المرفوعة سابقاً'),
        StreamBuilder<List<HomeworkFile>>(
          stream: FirestoreService.instance.watchGroupHomework(group.id),
          builder: (ctx, snap) {
            final files = snap.data ?? [];
            if (files.isEmpty) {
              return Center(
                child: Text('لا توجد ملفات بعد',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.inkMuted)),
              );
            }
            return Column(
              children: files.map((f) => _existingFile(ctx, f)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _existingFile(BuildContext context, HomeworkFile f) =>
      Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(f.title,
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.ink)),
            ),
            GestureDetector(
              onTap: () async {
                await FirestoreService.instance
                    .deleteHomework(group.id, f.id);
              },
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 16),
            ),
          ],
        ),
      );
}

// ── Video Tab ─────────────────────────────────────────────────────────────────

class _VideoTab extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController urlCtrl;
  final VoidCallback onSave;
  final bool saving;
  final String? error;
  final String? success;
  final StudyGroup group;

  const _VideoTab({
    required this.titleCtrl,
    required this.urlCtrl,
    required this.onSave,
    required this.saving,
    required this.error,
    required this.success,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_2_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'سيُضاف لـ: ${group.title}',
                style: GoogleFonts.cairo(
                    fontSize: 12, color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        _label('عنوان الشرح'),
        TextField(
          controller: titleCtrl,
          style: GoogleFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'مثال: مراجعة الوحدة الثانية',
            hintStyle: GoogleFonts.cairo(
                fontSize: 13, color: AppColors.inkMuted),
            prefixIcon: const Icon(Icons.title_rounded,
                color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _label('رابط اليوتيوب'),
        TextField(
          controller: urlCtrl,
          style: GoogleFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'https://youtube.com/watch?v=...',
            hintStyle: GoogleFonts.cairo(
                fontSize: 13, color: AppColors.inkMuted),
            prefixIcon: const Icon(Icons.play_circle_outline_rounded,
                color: AppColors.primary),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpace.sm),
          _feedback(error!, AppColors.danger, Icons.error_outline),
        ],
        if (success != null) ...[
          const SizedBox(height: AppSpace.sm),
          _feedback(success!, AppColors.success,
              Icons.check_circle_outline),
        ],
        const SizedBox(height: AppSpace.xl),
        saving
            ? const Center(child: CircularProgressIndicator())
            : PrimaryButton(
                label: 'إضافة الشرح للمجموعة',
                icon: Icons.add_circle_outline_rounded,
                onPressed: onSave,
              ),
        const SizedBox(height: AppSpace.xl),
        const SectionTitle(title: 'الشروحات المضافة سابقاً'),
        StreamBuilder<List<LessonVideo>>(
          stream: FirestoreService.instance.watchGroupVideos(group.id),
          builder: (ctx, snap) {
            final videos = snap.data ?? [];
            if (videos.isEmpty) {
              return Center(
                child: Text('لا توجد فيديوهات بعد',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.inkMuted)),
              );
            }
            return Column(
              children: videos
                  .map((v) => _existingVideo(ctx, v))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _existingVideo(BuildContext context, LessonVideo v) =>
      Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(v.title,
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.ink)),
            ),
            GestureDetector(
              onTap: () async {
                await FirestoreService.instance
                    .deleteVideo(group.id, v.id);
              },
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 16),
            ),
          ],
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 4, top: 4),
      child: Text(text,
          style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink)),
    );

Widget _feedback(String msg, Color color, IconData icon) => Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style:
                    GoogleFonts.cairo(fontSize: 12, color: color)),
          ),
        ],
      ),
    );

/// Dashed-border upload container — kept for backwards compatibility
class DottedContainer extends StatelessWidget {
  final Widget child;
  const DottedContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(AppRadius.md));
    final path = Path()..addRRect(rrect);
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const dashWidth = 6.0, dashGap = 5.0;
      while (distance < metric.length) {
        dashPath.addPath(
            metric.extractPath(distance, distance + dashWidth),
            Offset.zero);
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
