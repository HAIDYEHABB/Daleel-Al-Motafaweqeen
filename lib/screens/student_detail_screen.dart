import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'send_student_file_screen.dart';

class StudentDetailScreen extends StatelessWidget {
  final StudentRecord student;
  final StudyGroup group;
  const StudentDetailScreen(
      {super.key, required this.student, required this.group});

  bool get _isAdmin => Session.instance.role == UserRole.admin;

  void _showAddNoteSheet(BuildContext context, String studentId) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpace.lg,
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
                  Text('إضافة ملاحظة',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(height: AppSpace.md),
                  TextField(
                    controller: ctrl,
                    maxLines: 4,
                    autofocus: true,
                    style: GoogleFonts.cairo(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'اكتب ملاحظتك هنا...',
                      hintStyle: GoogleFonts.cairo(
                          fontSize: 13, color: AppColors.inkMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  ElevatedButton(
                      onPressed: () async {
                        final text = ctrl.text.trim();
                        if (text.isEmpty) return;
                        await FirestoreService.instance.addStudentNote(
                          studentId: studentId,
                          content: text,
                        );
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      },
                      child: Text('حفظ الملاحظة',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.name,
            style: GoogleFonts.cairo(
                fontSize: 15, fontWeight: FontWeight.w800)),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.attach_file_rounded),
              tooltip: 'إرسال ملف',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SendStudentFileScreen(
                      group: group, preselectedStudent: student),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          // ── Profile Card ───────────────────────────────────────────
          _ProfileCard(student: student, group: group),
          const SizedBox(height: AppSpace.lg),

          // ── Cumulative score ───────────────────────────────────────
          const SectionTitle(title: 'بطاقة المستوى التراكمي'),
          _CumulativeCard(student: student),
          const SizedBox(height: AppSpace.lg),

          // ── Attendance history ─────────────────────────────────────
          const SectionTitle(title: 'سجل الحضور والغياب'),
          _AttendanceHistorySection(studentId: student.id),
          const SizedBox(height: AppSpace.lg),

          // ── Weekly scores history ──────────────────────────────────
          const SectionTitle(title: 'تاريخ درجات الحصة'),
          _WeeklyScoresSection(studentId: student.id),
          const SizedBox(height: AppSpace.lg),

          // ── Personal files ─────────────────────────────────────────
          SectionTitle(
            title: 'الملفات الخاصة',
            trailing: _isAdmin
                ? TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SendStudentFileScreen(
                            group: group,
                            preselectedStudent: student),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('إرسال ملف',
                        style: GoogleFonts.cairo(fontSize: 12)),
                  )
                : null,
          ),
          _StudentFilesSection(
              studentId: student.id, isAdmin: _isAdmin),
          const SizedBox(height: AppSpace.lg),

          // ── Notes ──────────────────────────────────────────────────
          SectionTitle(
            title: 'ملاحظات المعلم',
            trailing: _isAdmin
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primary, size: 20),
                    tooltip: 'إضافة ملاحظة',
                    onPressed: () =>
                        _showAddNoteSheet(context, student.id),
                  )
                : null,
          ),
          _NotesSection(studentId: student.id, isAdmin: _isAdmin),
          const SizedBox(height: AppSpace.xl),
        ],
      ),
    );
  }
}

// ── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final StudentRecord student;
  final StudyGroup group;
  const _ProfileCard({required this.student, required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            backgroundImage: student.photoUrl.isNotEmpty
                ? NetworkImage(student.photoUrl)
                : null,
            child: student.photoUrl.isEmpty
                ? Text(
                    student.name.isNotEmpty
                        ? student.name.substring(0, 1)
                        : '؟',
                    style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(student.name,
              style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(group.title,
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              _pill(Icons.phone_iphone_rounded, student.phone),
              const SizedBox(width: 8),
              _pill(Icons.phone_forwarded_outlined, student.parentPhone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  text.isNotEmpty ? text : '—',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Cumulative Card ───────────────────────────────────────────────────────────

class _CumulativeCard extends StatelessWidget {
  final StudentRecord student;
  const _CumulativeCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final score = student.overallRating;
    final Color scoreColor = score >= 80
        ? AppColors.success
        : score >= 60
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: 'درجة الحصة',
                  value: '${student.weeklyQuizScore.toStringAsFixed(1)}/١٠',
                  color: AppColors.primary,
                  icon: Icons.quiz_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricTile(
                  label: 'درجة الامتحان',
                  value:
                      '${student.monthlyExamScore.toStringAsFixed(1)}/١٠٠',
                  color: AppColors.warning,
                  icon: Icons.assignment_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricTile(
                  label: 'التقييم التراكمي',
                  value: '${score.toStringAsFixed(1)}٪',
                  color: scoreColor,
                  icon: Icons.emoji_events_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              color: scoreColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('٠',
                  style: GoogleFonts.cairo(
                      fontSize: 10, color: AppColors.inkMuted)),
              Text('المستوى التراكمي',
                  style: GoogleFonts.cairo(
                      fontSize: 10, color: AppColors.inkMuted)),
              Text('١٠٠',
                  style: GoogleFonts.cairo(
                      fontSize: 10, color: AppColors.inkMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.cairo(fontSize: 9.5, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}

// ── Attendance History ────────────────────────────────────────────────────────

class _AttendanceHistorySection extends StatelessWidget {
  final String studentId;
  const _AttendanceHistorySection({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream:
          FirestoreService.instance.watchStudentAttendanceHistory(studentId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snap.data ?? [];
        if (records.isEmpty) {
          return _miniEmpty('لا يوجد سجل حضور بعد');
        }
        final present =
            records.where((r) => r.status == AttendanceStatus.present).length;
        final absent =
            records.where((r) => r.status == AttendanceStatus.absent).length;
        final late =
            records.where((r) => r.status == AttendanceStatus.late).length;
        final rate = ((present + late) / records.length) * 100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _attBadge('$present', 'حاضر', AppColors.success),
                const SizedBox(width: 8),
                _attBadge('$late', 'متأخر', AppColors.warning),
                const SizedBox(width: 8),
                _attBadge('$absent', 'غائب', AppColors.danger),
                const SizedBox(width: 8),
                _attBadge('${rate.toInt()}٪', 'الحضور', AppColors.primary),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            ...records.take(10).map((r) => _AttendanceRow(record: r)),
          ],
        );
      },
    );
  }

  Widget _attBadge(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            children: [
              Text(value,
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 10, color: AppColors.inkMuted)),
            ],
          ),
        ),
      );
}

class _AttendanceRow extends StatelessWidget {
  final AttendanceRecord record;
  const _AttendanceRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (record.status) {
      AttendanceStatus.present => ('حاضر', AppColors.success),
      AttendanceStatus.absent => ('غائب', AppColors.danger),
      AttendanceStatus.late => ('متأخر', AppColors.warning),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 14, color: AppColors.inkMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${record.date.day}/${record.date.month}/${record.date.year}',
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.ink),
            ),
          ),
          InfoBadge(text: label, color: color),
        ],
      ),
    );
  }
}

// ── Weekly Scores History + Trend Chart ──────────────────────────────────────

class _WeeklyScoresSection extends StatelessWidget {
  final String studentId;
  const _WeeklyScoresSection({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WeeklyScore>>(
      stream: FirestoreService.instance.watchStudentWeeklyScores(studentId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final scores = snap.data ?? [];
        if (scores.isEmpty) return _miniEmpty('لا توجد درجات مسجلة بعد');

        // Reverse so oldest is left on chart
        final ordered = scores.reversed.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Trend chart ───────────────────────────────────────
            _ScoreTrendChart(scores: ordered),
            const SizedBox(height: AppSpace.md),
            // ── Row list ──────────────────────────────────────────
            ...ordered.reversed
                .take(12)
                .map((ws) => _ScoreRow(score: ws)),
          ],
        );
      },
    );
  }
}

class _ScoreTrendChart extends StatelessWidget {
  final List<WeeklyScore> scores;
  const _ScoreTrendChart({required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores.length < 2) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('أدخل درجتين على الأقل لعرض منحنى الأداء',
            style: GoogleFonts.cairo(
                fontSize: 12, color: AppColors.inkMuted)),
      );
    }

    final spots = scores.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.score.clamp(0, 10));
    }).toList();

    // Determine trend color: compare last two points
    final isRising =
        scores.last.score >= scores[scores.length - 2].score;
    final lineColor = isRising ? AppColors.success : AppColors.danger;

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRising
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: lineColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isRising ? 'الأداء في تحسّن' : 'الأداء في تراجع',
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: lineColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 10,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.cairo(
                            fontSize: 9, color: AppColors.inkMuted),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: lineColor,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final WeeklyScore score;
  const _ScoreRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score.score / 10).clamp(0.0, 1.0);
    final color = pct >= 0.8
        ? AppColors.success
        : pct >= 0.5
            ? AppColors.warning
            : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(score.weekLabel,
                style: GoogleFonts.cairo(fontSize: 12, color: AppColors.ink)),
          ),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.border,
                color: color,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${score.score.toStringAsFixed(1)}/١٠',
              style: GoogleFonts.cairo(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── Student Files ─────────────────────────────────────────────────────────────

class _StudentFilesSection extends StatelessWidget {
  final String studentId;
  final bool isAdmin;
  const _StudentFilesSection(
      {required this.studentId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentFile>>(
      stream: FirestoreService.instance.watchStudentFiles(studentId),
      builder: (ctx, snap) {
        final files = snap.data ?? [];
        if (files.isEmpty) return _miniEmpty('لا توجد ملفات خاصة بعد');
        return Column(
          children: files
              .map((f) => _FileItem(
                    file: f,
                    onDelete: isAdmin
                        ? () async {
                            await FirestoreService.instance
                                .deleteStudentFile(studentId, f.id);
                          }
                        : null,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _FileItem extends StatelessWidget {
  final StudentFile file;
  final VoidCallback? onDelete;
  const _FileItem({required this.file, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(file.url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تعذّر فتح الرابط', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.danger,
          ));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.title,
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  if (file.uploadedAt != null)
                    Text(
                      '${file.uploadedAt!.day}/${file.uploadedAt!.month}/${file.uploadedAt!.year}',
                      style: GoogleFonts.cairo(
                          fontSize: 10.5, color: AppColors.inkMuted),
                    ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                size: 14, color: AppColors.inkMuted),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger, size: 18),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Notes Section ─────────────────────────────────────────────────────────────

class _NotesSection extends StatelessWidget {
  final String studentId;
  final bool isAdmin;
  const _NotesSection({required this.studentId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentNote>>(
      stream: FirestoreService.instance.watchStudentNotes(studentId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final notes = snap.data ?? [];
        if (notes.isEmpty) {
          return _miniEmpty('لا توجد ملاحظات بعد');
        }
        return Column(
          children: notes
              .map((n) => _NoteRow(
                    note: n,
                    onDelete: isAdmin
                        ? () async {
                            await FirestoreService.instance
                                .deleteStudentNote(studentId, n.id);
                          }
                        : null,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _NoteRow extends StatelessWidget {
  final StudentNote note;
  final VoidCallback? onDelete;
  const _NoteRow({required this.note, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_outlined,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.content,
                    style:
                        GoogleFonts.cairo(fontSize: 13, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                  '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                  style: GoogleFonts.cairo(
                      fontSize: 10.5, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

Widget _miniEmpty(String msg) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Center(
        child: Text(msg,
            style:
                GoogleFonts.cairo(fontSize: 12, color: AppColors.inkMuted)),
      ),
    );
