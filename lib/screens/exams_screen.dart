import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ExamsScreen extends StatelessWidget {
  final StudyGroup group;
  const ExamsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبارات — ${group.title}',
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateExamSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: Text('اختبار جديد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<Exam>>(
        stream: FirestoreService.instance.watchGroupExams(group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final exams = snapshot.data ?? [];
          if (exams.isEmpty) {
            return _emptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.lg, AppSpace.lg, 100),
            itemCount: exams.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpace.sm),
            itemBuilder: (context, i) =>
                _ExamCard(exam: exams[i], group: group),
          );
        },
      ),
    );
  }

  void _showCreateExamSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateExamSheet(group: group),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined,
                  size: 56, color: AppColors.inkMuted),
              const SizedBox(height: AppSpace.md),
              Text('لا توجد اختبارات بعد',
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('اضغط "اختبار جديد" لإنشاء أول اختبار للمجموعة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.inkMuted)),
            ],
          ),
        ),
      );
}

// ── Exam Card ─────────────────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final StudyGroup group;
  const _ExamCard({required this.exam, required this.group});

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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title,
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                      Text(
                          '${exam.date.day}/${exam.date.month}/${exam.date.year} — الدرجة الكلية: ${exam.totalScore.toInt()}',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: AppColors.inkMuted)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      await FirestoreService.instance
                          .deleteExam(group.id, exam.id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Text('حذف الاختبار',
                              style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Results entry
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: _ExamResultsEntry(exam: exam, group: group),
          ),
        ],
      ),
    );
  }
}

// ── Exam Results Entry ────────────────────────────────────────────────────────

class _ExamResultsEntry extends StatefulWidget {
  final Exam exam;
  final StudyGroup group;
  const _ExamResultsEntry({required this.exam, required this.group});

  @override
  State<_ExamResultsEntry> createState() => _ExamResultsEntryState();
}

class _ExamResultsEntryState extends State<_ExamResultsEntry> {
  final Map<String, TextEditingController> _controllers = {};
  bool _expanded = false;

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentRecord>>(
      stream: FirestoreService.instance
          .watchGroupStudents(widget.group.id),
      builder: (ctx, studentsSnap) {
        return StreamBuilder<List<ExamResult>>(
          stream: FirestoreService.instance
              .watchExamResults(widget.group.id, widget.exam.id),
          builder: (ctx2, resultsSnap) {
            final students = studentsSnap.data ?? [];
            final results = resultsSnap.data ?? [];
            final resultMap = {
              for (final r in results) r.studentId: r
            };

            // Init controllers
            for (final s in students) {
              if (!_controllers.containsKey(s.id)) {
                final existing = resultMap[s.id];
                _controllers[s.id] = TextEditingController(
                    text: existing != null
                        ? existing.score.toString()
                        : '');
              }
            }

            if (students.isEmpty) {
              return Text('لا يوجد طلاب',
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.inkMuted));
            }

            final entered = results.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary
                Row(
                  children: [
                    InfoBadge(
                      text:
                          'تم إدخال $entered/${students.length} درجة',
                      color: entered == students.length
                          ? AppColors.success
                          : AppColors.warning,
                      icon: Icons.how_to_reg_outlined,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          setState(() => _expanded = !_expanded),
                      child: Text(
                          _expanded ? 'إخفاء' : 'إدخال الدرجات',
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: AppSpace.sm),
                  ...students.map((s) {
                    final ctrl = _controllers[s.id]!;
                    final existing = resultMap[s.id];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(s.name,
                                style: GoogleFonts.cairo(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink)),
                          ),
                          if (existing != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8),
                              child: InfoBadge(
                                text:
                                    '${existing.score.toStringAsFixed(1)}/${widget.exam.totalScore.toInt()}',
                                color: AppColors.success,
                              ),
                            ),
                          SizedBox(
                            width: 70,
                            child: TextFormField(
                              controller: ctrl,
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: GoogleFonts.cairo(fontSize: 12),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        vertical: 8),
                                hintText: 'الدرجة',
                                hintStyle: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: AppColors.inkMuted),
                              ),
                              onEditingComplete: () async {
                                final val =
                                    double.tryParse(ctrl.text);
                                if (val != null &&
                                    val >= 0 &&
                                    val <=
                                        widget.exam.totalScore) {
                                  await FirestoreService.instance
                                      .saveExamResult(
                                    groupId: widget.group.id,
                                    examId: widget.exam.id,
                                    studentId: s.id,
                                    studentName: s.name,
                                    score: val,
                                    totalScore:
                                        widget.exam.totalScore,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

// ── Create Exam Sheet ─────────────────────────────────────────────────────────

class _CreateExamSheet extends StatefulWidget {
  final StudyGroup group;
  const _CreateExamSheet({required this.group});

  @override
  State<_CreateExamSheet> createState() => _CreateExamSheetState();
}

class _CreateExamSheetState extends State<_CreateExamSheet> {
  final _titleCtrl = TextEditingController();
  final _totalCtrl = TextEditingController(text: '100');
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.lg,
        left: AppSpace.lg,
        right: AppSpace.lg,
        top: AppSpace.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إنشاء اختبار جديد',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _titleCtrl,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'اسم الاختبار (مثال: اختبار الوحدة الثانية)',
                hintStyle: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.inkMuted),
                prefixIcon: const Icon(Icons.assignment_outlined,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: _totalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'الدرجة الكلية',
                hintStyle: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.inkMuted),
                prefixIcon: const Icon(Icons.grade_outlined,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            // Date picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_date.day}/${_date.month}/${_date.year}',
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: AppColors.ink),
                    ),
                    const Spacer(),
                    Text('تغيير',
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(_error!,
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.danger)),
            ],
            const SizedBox(height: AppSpace.lg),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    label: 'إنشاء الاختبار',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () async {
                      final title = _titleCtrl.text.trim();
                      final total =
                          double.tryParse(_totalCtrl.text.trim());
                      if (title.isEmpty) {
                        setState(
                            () => _error = 'أدخل اسم الاختبار');
                        return;
                      }
                      if (total == null || total <= 0) {
                        setState(() =>
                            _error = 'أدخل الدرجة الكلية');
                        return;
                      }
                      setState(() => _saving = true);
                      await FirestoreService.instance.createExam(
                        groupId: widget.group.id,
                        title: title,
                        totalScore: total,
                        date: _date,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
