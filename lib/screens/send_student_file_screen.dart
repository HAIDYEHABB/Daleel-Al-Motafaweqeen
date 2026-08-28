import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SendStudentFileScreen extends StatefulWidget {
  final StudyGroup group;
  final StudentRecord? preselectedStudent;
  const SendStudentFileScreen({
    super.key,
    required this.group,
    this.preselectedStudent,
  });

  @override
  State<SendStudentFileScreen> createState() =>
      _SendStudentFileScreenState();
}

class _SendStudentFileScreenState extends State<SendStudentFileScreen> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  // Use student ID (String) as the dropdown value to avoid object-equality
  // issues that cause Flutter's DropdownButton assertion error.
  String? _selectedStudentId;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.preselectedStudent?.id;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(List<StudentRecord> students) async {
    final title = _titleCtrl.text.trim();
    final url = _urlCtrl.text.trim();

    if (_selectedStudentId == null) {
      setState(() => _error = 'اختر الطالب أولاً');
      return;
    }
    if (title.isEmpty) {
      setState(() => _error = 'أدخل عنوان الملف');
      return;
    }
    if (url.isEmpty) {
      setState(() => _error = 'أدخل رابط الملف');
      return;
    }

    final student =
        students.where((s) => s.id == _selectedStudentId).firstOrNull;
    if (student == null) {
      setState(() => _error = 'الطالب المختار لم يعد موجوداً');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await FirestoreService.instance.addStudentFile(
        studentId: student.id,
        title: title,
        url: url,
        groupId: widget.group.id,
      );
      setState(() {
        _success = 'تم إرسال الملف إلى ${student.name} بنجاح';
        _titleCtrl.clear();
        _urlCtrl.clear();
        if (widget.preselectedStudent == null) {
          _selectedStudentId = null;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء الإرسال، حاول مرة أخرى';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إرسال ملف خاص',
            style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: StreamBuilder<List<StudentRecord>>(
          stream:
              FirestoreService.instance.watchGroupStudents(widget.group.id),
          builder: (ctx, snap) {
            final students = snap.data ?? [];

            // Ensure selected ID is still valid (student may have left group)
            final validId = students.any((s) => s.id == _selectedStudentId)
                ? _selectedStudentId
                : null;
            if (validId != _selectedStudentId) {
              // Schedule state update outside build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedStudentId = validId);
              });
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpace.lg),
              children: [
                // ── Info banner ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الملف سيظهر فقط للطالب المحدد ولن يراه أي طالب آخر',
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),

                // ── Student selector ─────────────────────────────────
                const SectionTitle(title: 'اختر الطالب'),
                if (snap.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (students.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: Text('لا يوجد طلاب في هذه المجموعة بعد',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: AppColors.inkMuted)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        // value must either be null or exist exactly once in items
                        value: validId,
                        hint: Text('اختر الطالب',
                            style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: AppColors.inkMuted)),
                        items: students
                            .map((s) => DropdownMenuItem<String>(
                                  value: s.id,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor:
                                            AppColors.primary.withValues(
                                                alpha: 0.10),
                                        child: Text(
                                          s.name.isNotEmpty
                                              ? s.name.substring(0, 1)
                                              : '؟',
                                          style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(s.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.cairo(
                                                fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (id) =>
                            setState(() => _selectedStudentId = id),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpace.lg),

                // ── File details ─────────────────────────────────────
                const SectionTitle(title: 'تفاصيل الملف'),
                _label('عنوان الملف'),
                TextField(
                  controller: _titleCtrl,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'مثال: تصحيح امتحان الشهر',
                    hintStyle: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.inkMuted),
                    prefixIcon: const Icon(Icons.title_rounded,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                _label('رابط الملف (PDF)'),
                TextField(
                  controller: _urlCtrl,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'رابط Google Drive أو أي رابط مباشر',
                    hintStyle: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.inkMuted),
                    prefixIcon: const Icon(Icons.link_rounded,
                        color: AppColors.primary),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: AppSpace.md),
                  _feedbackBanner(
                      _error!, AppColors.danger, Icons.error_outline),
                ],
                if (_success != null) ...[
                  const SizedBox(height: AppSpace.md),
                  _feedbackBanner(_success!, AppColors.success,
                      Icons.check_circle_outline),
                ],

                const SizedBox(height: AppSpace.xl),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        label: 'إرسال الملف للطالب',
                        icon: Icons.send_rounded,
                        onPressed: () => _send(students),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, right: 4),
        child: Text(text,
            style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      );

  Widget _feedbackBanner(String msg, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.cairo(fontSize: 12, color: color)),
            ),
          ],
        ),
      );
}
