import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'group_management_screen.dart';
import 'ranking_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StudyGroup? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // ── Header ──────────────────────────────────────────────
            AppSwooshHeader(
              height: 130,
              child: Row(
                children: [
                  const Icon(Icons.dashboard_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('لوحة المتابعة',
                            style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text('متابعة أداء المجموعات والطلاب',
                            style: GoogleFonts.cairo(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Group selector ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
              child: StreamBuilder<List<StudyGroup>>(
                stream: FirestoreService.instance.watchTeacherGroups(),
                builder: (ctx, snap) {
                  final groups = snap.data ?? [];
                  if (groups.isEmpty) {
                    return _noGroupsCard();
                  }
                  // Auto-select first group
                  if (_selectedGroup == null && groups.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedGroup = groups.first);
                    });
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(title: 'اختر المجموعة'),
                      // Group chips
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: groups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (ctx, i) {
                            final g = groups[i];
                            final selected = _selectedGroup?.id == g.id;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedGroup = g),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.pill),
                                  border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.border),
                                ),
                                child: Text(
                                  g.title,
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.inkMuted),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_selectedGroup != null) ...[
                        const SizedBox(height: AppSpace.lg),
                        _GroupDashboard(group: _selectedGroup!),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noGroupsCard() => Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            const Icon(Icons.groups_outlined,
                size: 48, color: AppColors.inkMuted),
            const SizedBox(height: AppSpace.md),
            Text('لا توجد مجموعات بعد',
                style: GoogleFonts.cairo(
                    fontSize: 14, color: AppColors.inkMuted)),
          ],
        ),
      );
}

// ── Group Dashboard ───────────────────────────────────────────────────────────

class _GroupDashboard extends StatelessWidget {
  final StudyGroup group;
  const _GroupDashboard({required this.group});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupStats>(
      stream: FirestoreService.instance.watchGroupStats(group.id),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snap.data;
        if (stats == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Quick stats grid ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _BigStat(
                    value: '${stats.totalStudents}',
                    label: 'عدد الطلاب',
                    icon: Icons.groups_2_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BigStat(
                    value: '${stats.avgAttendanceRate.toInt()}٪',
                    label: 'نسبة الحضور',
                    icon: Icons.event_available_outlined,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _BigStat(
                    value: stats.avgWeeklyScore.toStringAsFixed(1),
                    label: 'متوسط درجة الحصة',
                    icon: Icons.quiz_outlined,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BigStat(
                    value: stats.avgMonthlyScore.toStringAsFixed(1),
                    label: 'متوسط الامتحان',
                    icon: Icons.assignment_outlined,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),

            // ── Attendance summary ─────────────────────────────────
            const SectionTitle(title: 'الحضور اليوم'),
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _AttendancePie(
                      present: stats.presentToday,
                      absent: stats.absentToday,
                      total: stats.totalStudents),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legendRow(
                            '${stats.presentToday} حاضر',
                            AppColors.success),
                        const SizedBox(height: 8),
                        _legendRow(
                            '${stats.absentToday} غائب',
                            AppColors.danger),
                        const SizedBox(height: 8),
                        _legendRow(
                            '${stats.totalStudents - stats.presentToday - stats.absentToday} متأخر',
                            AppColors.warning),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),

            // ── Top student ────────────────────────────────────────
            if (stats.topStudentName.isNotEmpty) ...[
              const SectionTitle(title: 'المتفوق الأول'),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7D6), Color(0xFFFFF3CD)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                          color: Color(0xFFFFD700), shape: BoxShape.circle),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stats.topStudentName,
                              style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                          Text(
                              'التقييم التراكمي: ${stats.topStudentScore.toStringAsFixed(1)}٪',
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.inkMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
            ],

            // ── Action buttons ─────────────────────────────────────
            const SectionTitle(title: 'إجراءات سريعة'),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.fact_check_outlined,
                    label: 'تسجيل الحضور',
                    color: AppColors.success,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GroupManagementScreen(
                              group: group, initialTab: 0)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.leaderboard_rounded,
                    label: 'الترتيب',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RankingScreen(group: group)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.grade_outlined,
                    label: 'الدرجات',
                    color: AppColors.warning,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GroupManagementScreen(
                              group: group, initialTab: 1)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _legendRow(String label, Color color) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 12, color: AppColors.ink)),
        ],
      );
}

// ── Big Stat ──────────────────────────────────────────────────────────────────

class _BigStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _BigStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                Text(label,
                    style: GoogleFonts.cairo(
                        fontSize: 10.5, color: AppColors.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attendance Pie (Custom Paint) ─────────────────────────────────────────────

class _AttendancePie extends StatelessWidget {
  final int present;
  final int absent;
  final int total;
  const _AttendancePie(
      {required this.present, required this.absent, required this.total});

  @override
  Widget build(BuildContext context) {
    final rate = total > 0 ? present / total : 0.0;
    return SizedBox(
      width: 70,
      height: 70,
      child: CustomPaint(
        painter: _PiePainter(presentRate: rate),
        child: Center(
          child: Text(
            '${(rate * 100).toInt()}٪',
            style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final double presentRate;
  const _PiePainter({required this.presentRate});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const startAngle = -1.5708; // -90 degrees
    final sweepAngle = 2 * 3.14159 * presentRate;

    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    if (presentRate > 0) {
      final fgPaint = Paint()
        ..color = AppColors.success
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) => old.presentRate != presentRate;
}

// ── Action Btn ────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
