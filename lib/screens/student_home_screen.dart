import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'student_content_screen.dart';
import 'student_files_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<StudentRecord?> _watchSelf() {
    if (_uid.isEmpty) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('students')
        .doc(_uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return StudentRecord.fromDoc(doc.id, doc.data()!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudentRecord?>(
      stream: _watchSelf(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final student = snap.data;
        if (student == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: AppColors.inkMuted),
                  const SizedBox(height: AppSpace.md),
                  Text('تعذر تحميل بياناتك',
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: AppColors.inkMuted)),
                  const SizedBox(height: AppSpace.md),
                  TextButton(
                    onPressed: () async {
                      await AuthService.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (_) => false);
                      }
                    },
                    child: Text('تسجيل الخروج',
                        style: GoogleFonts.cairo(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          );
        }
        return _StudentDashboard(student: student);
      },
    );
  }
}

// ── Student Dashboard with Bottom Nav ────────────────────────────────────────

class _StudentDashboard extends StatefulWidget {
  final StudentRecord student;
  const _StudentDashboard({required this.student});

  @override
  State<_StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<_StudentDashboard> {
  int _currentIndex = 0;

  void _changeTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    // Pages are built fresh on every student-data update so _HomeTab
    // always receives the latest record. IndexedStack preserves the
    // scroll position / state of each page between tab switches.
    final pages = [
      _HomeTab(student: widget.student, onTabChange: _changeTab),
      StudentContentScreen(
        groupId: widget.student.groupId,
        groupTitle: widget.student.groupId,
      ),
      StudentFilesScreen(studentId: widget.student.id),
      NotificationsScreen(groupId: widget.student.groupId),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changeTab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon:
                Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded,
                color: AppColors.primary),
            label: 'المحتوى',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon:
                Icon(Icons.folder_rounded, color: AppColors.primary),
            label: 'ملفاتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded,
                color: AppColors.primary),
            label: 'الإشعارات',
          ),
        ],
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final StudentRecord student;
  final ValueChanged<int> onTabChange;
  const _HomeTab({required this.student, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<StudyGroup?>(
          future: FirestoreService.instance.getGroup(student.groupId),
          builder: (ctx, groupSnap) {
            final group = groupSnap.data;
            return ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                _StudentHeader(
                    student: student,
                    group: group,
                    onSignOut: () async {
                      await AuthService.instance.signOut();
                      if (ctx.mounted) {
                        Navigator.of(ctx).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (_) => false);
                      }
                    }),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Subscription card
                      const SectionTitle(title: 'حالة الاشتراك'),
                      _SubscriptionCard(student: student),
                      const SizedBox(height: AppSpace.lg),

                      // Achievement card
                      const SectionTitle(title: 'بطاقة التميز'),
                      _AchievementCard(student: student),
                      const SizedBox(height: AppSpace.lg),

                      // Attendance
                      const SectionTitle(title: 'الحضور والغياب'),
                      _AttendanceSummary(studentId: student.id),
                      const SizedBox(height: AppSpace.lg),

                      // Quick links
                      const SectionTitle(title: 'روابط سريعة'),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickLink(
                              icon: Icons.auto_stories_rounded,
                              label: 'المحتوى',
                              color: AppColors.primary,
                              onTap: () => onTabChange(1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickLink(
                              icon: Icons.folder_rounded,
                              label: 'ملفاتي',
                              color: AppColors.warning,
                              onTap: () => onTabChange(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickLink(
                              icon: Icons.notifications_rounded,
                              label: 'الإشعارات',
                              color: AppColors.success,
                              onTap: () => onTabChange(3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),

                      // Latest homework
                      if (student.groupId.isNotEmpty) ...[
                        const SectionTitle(title: 'آخر حل واجب'),
                        _LatestHomework(groupId: student.groupId),
                        const SizedBox(height: AppSpace.lg),
                      ],

                      // Exam results
                      if (student.groupId.isNotEmpty) ...[
                        const SectionTitle(title: 'نتائج الاختبارات'),
                        _StudentExamResults(
                          groupId: student.groupId,
                          studentId: student.id,
                        ),
                        const SizedBox(height: AppSpace.lg),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Student Header ────────────────────────────────────────────────────────────

class _StudentHeader extends StatelessWidget {
  final StudentRecord student;
  final StudyGroup? group;
  final VoidCallback onSignOut;
  const _StudentHeader(
      {required this.student, this.group, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return AppSwooshHeader(
      height: 165,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أهلاً ${_firstName(student.name)} 👋',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    if (group != null)
                      Text(group!.title,
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white),
                onPressed: onSignOut,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                  child: _pill(
                Icons.quiz_outlined,
                '${student.weeklyQuizScore.toStringAsFixed(1)}/١٠',
                'درجة الحصة',
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _pill(
                Icons.emoji_events_outlined,
                '${student.overallRating.toStringAsFixed(1)}٪',
                'التراكمي',
              )),
            ],
          ),
        ],
      ),
    );
  }

  String _firstName(String name) {
    final parts = name.trim().split(' ');
    return parts.isNotEmpty ? parts.first : name;
  }

  Widget _pill(IconData icon, String val, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(val,
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text(label,
                    style: GoogleFonts.cairo(
                        fontSize: 9.5, color: Colors.white70)),
              ],
            ),
          ],
        ),
      );
}

// ── Subscription Card ─────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  final StudentRecord student;
  const _SubscriptionCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (student.paymentStatus) {
      PaymentStatus.paid => AppColors.success,
      PaymentStatus.partial => AppColors.warning,
      PaymentStatus.unpaid => AppColors.danger,
    };
    final String statusLabel = switch (student.paymentStatus) {
      PaymentStatus.paid => 'تم الدفع',
      PaymentStatus.partial => 'دفع جزئي',
      PaymentStatus.unpaid => 'لم يتم الدفع',
    };

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.payments_outlined,
                color: statusColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('حالة الاشتراك',
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: AppColors.inkMuted)),
                Text(statusLabel,
                    style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: statusColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${student.remainingPaidSessions}',
                  style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: student.remainingPaidSessions > 0
                          ? AppColors.success
                          : AppColors.danger)),
              Text('حصة متبقية',
                  style: GoogleFonts.cairo(
                      fontSize: 10, color: AppColors.inkMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Achievement Card ──────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final StudentRecord student;
  const _AchievementCard({required this.student});

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
          Expanded(
              child: _m('${student.weeklyQuizScore.toStringAsFixed(1)}/١٠',
                  'درجة الحصة', Icons.quiz_outlined, AppColors.primary)),
          _vDivider(),
          Expanded(
              child: _m(
                  student.monthlyExamScore.toStringAsFixed(1),
                  'درجة الامتحان',
                  Icons.assignment_outlined,
                  AppColors.warning)),
          _vDivider(),
          Expanded(
              child: _m(
                  '${student.overallRating.toStringAsFixed(1)}٪',
                  'التراكمي',
                  Icons.emoji_events_outlined,
                  AppColors.success)),
        ],
      ),
    );
  }

  Widget _m(String v, String l, IconData icon, Color color) => Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(v,
              style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          Text(l,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 9.5, color: AppColors.inkMuted)),
        ],
      );

  Widget _vDivider() => Container(
      height: 36, width: 1, color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

// ── Attendance Summary ────────────────────────────────────────────────────────

class _AttendanceSummary extends StatelessWidget {
  final String studentId;
  const _AttendanceSummary({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: FirestoreService.instance
          .watchStudentAttendanceHistory(studentId),
      builder: (ctx, snap) {
        final records = snap.data ?? [];
        if (records.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
                child: Text('لا يوجد سجل حضور بعد',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.inkMuted))),
          );
        }
        final present = records
            .where((r) => r.status == AttendanceStatus.present)
            .length;
        final absent = records
            .where((r) => r.status == AttendanceStatus.absent)
            .length;
        final late = records
            .where((r) => r.status == AttendanceStatus.late)
            .length;
        final rate =
            ((present + late) / records.length * 100).toInt();

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
                  _t('$present', 'حاضر', AppColors.success),
                  _t('$late', 'متأخر', AppColors.warning),
                  _t('$absent', 'غائب', AppColors.danger),
                  _t('$rate٪', 'الحضور', AppColors.primary),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: (rate / 100).clamp(0.0, 1.0),
                  backgroundColor: AppColors.border,
                  color: rate >= 80
                      ? AppColors.success
                      : rate >= 60
                          ? AppColors.warning
                          : AppColors.danger,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _t(String v, String l, Color c) => Expanded(
        child: Column(
          children: [
            Text(v,
                style: GoogleFonts.cairo(
                    fontSize: 15, fontWeight: FontWeight.w800, color: c)),
            Text(l,
                style: GoogleFonts.cairo(
                    fontSize: 10, color: AppColors.inkMuted)),
          ],
        ),
      );
}

// ── Latest Homework ───────────────────────────────────────────────────────────

class _LatestHomework extends StatelessWidget {
  final String groupId;
  const _LatestHomework({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeworkFile>>(
      stream: FirestoreService.instance.watchGroupHomework(groupId),
      builder: (ctx, snap) {
        final files = snap.data ?? [];
        if (files.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
                child: Text('لا توجد حلول مرفوعة بعد',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.inkMuted))),
          );
        }
        final latest = files.first;
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.danger, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(latest.title,
                        style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    if (latest.uploadedAt != null)
                      Text(
                        '${latest.uploadedAt!.day}/${latest.uploadedAt!.month}/${latest.uploadedAt!.year}',
                        style: GoogleFonts.cairo(
                            fontSize: 10.5, color: AppColors.inkMuted),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(latest.url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('تعذّر فتح الرابط',
                          style: GoogleFonts.cairo()),
                      backgroundColor: AppColors.danger,
                    ));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('تحميل',
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Student Exam Results ──────────────────────────────────────────────────────

class _StudentExamResults extends StatelessWidget {
  final String groupId;
  final String studentId;
  const _StudentExamResults(
      {required this.groupId, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Exam>>(
      stream: FirestoreService.instance.watchGroupExams(groupId),
      builder: (ctx, examSnap) {
        if (examSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final exams = examSnap.data ?? [];
        if (exams.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text('لا توجد اختبارات بعد',
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.inkMuted)),
            ),
          );
        }
        return Column(
          children: exams
              .map((exam) => _ExamResultRow(
                    exam: exam,
                    groupId: groupId,
                    studentId: studentId,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ExamResultRow extends StatelessWidget {
  final Exam exam;
  final String groupId;
  final String studentId;
  const _ExamResultRow({
    required this.exam,
    required this.groupId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExamResult>>(
      stream: FirestoreService.instance
          .watchExamResults(groupId, exam.id),
      builder: (ctx, snap) {
        final results = snap.data ?? [];
        final myResult =
            results.where((r) => r.studentId == studentId).firstOrNull;

        final Color color = myResult == null
            ? AppColors.inkMuted
            : myResult.percentage >= 80
                ? AppColors.success
                : myResult.percentage >= 50
                    ? AppColors.warning
                    : AppColors.danger;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(AppSpace.md),
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
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.assignment_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.title,
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    Text(
                      '${exam.date.day}/${exam.date.month}/${exam.date.year}',
                      style: GoogleFonts.cairo(
                          fontSize: 10.5, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              myResult == null
                  ? Text('لم تُسجَّل بعد',
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: AppColors.inkMuted))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${myResult.score.toStringAsFixed(1)}/${exam.totalScore.toInt()}',
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: color),
                        ),
                        Text(
                          '${myResult.percentage.toInt()}٪',
                          style:
                              GoogleFonts.cairo(fontSize: 10.5, color: color),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}

// ── Quick Link ────────────────────────────────────────────────────────────────

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

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
                style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
