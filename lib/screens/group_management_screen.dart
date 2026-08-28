import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/common_widgets.dart';
import 'exams_screen.dart';
import 'ranking_screen.dart';
import 'send_student_file_screen.dart';
import 'student_detail_screen.dart';

class GroupManagementScreen extends StatefulWidget {
  final StudyGroup group;
  final int initialTab;
  const GroupManagementScreen(
      {super.key, required this.group, this.initialTab = 0});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'الحضور'),
    Tab(text: 'الدرجات'),
    Tab(text: 'الاشتراك'),
    Tab(text: 'المحتوى'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: _tabs.length, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isAdmin => Session.instance.role == UserRole.admin;

  void _showAddStudentSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final parentPhoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? error;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpace.lg,
            left: AppSpace.lg,
            right: AppSpace.lg,
            top: AppSpace.lg,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('إضافة طالب جديد',
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text(
                        'سيتم إنشاء حساب للطالب وإضافته لهذه المجموعة تلقائياً',
                        style: GoogleFonts.cairo(
                            fontSize: 11.5, color: AppColors.inkMuted)),
                    const SizedBox(height: AppSpace.md),
                    // Name
                    TextFormField(
                      controller: nameCtrl,
                      style: GoogleFonts.cairo(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'الاسم الرباعي بالعربية',
                        hintStyle: GoogleFonts.cairo(
                            fontSize: 13, color: AppColors.inkMuted),
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            color: AppColors.primary),
                      ),
                      validator: validateArabicName,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    // Phone
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.cairo(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '01xxxxxxxxx',
                        hintStyle: GoogleFonts.cairo(
                            fontSize: 13, color: AppColors.inkMuted),
                        prefixIcon: const Icon(Icons.phone_iphone_rounded,
                            color: AppColors.primary),
                      ),
                      validator: validateEgyptianPhone,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    // Parent phone
                    TextFormField(
                      controller: parentPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.cairo(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'رقم ولي الأمر',
                        hintStyle: GoogleFonts.cairo(
                            fontSize: 13, color: AppColors.inkMuted),
                        prefixIcon: const Icon(Icons.phone_forwarded_outlined,
                            color: AppColors.primary),
                      ),
                      validator: (v) =>
                          validateParentPhone(v, phoneCtrl.text),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    // Password
                    StatefulBuilder(
                      builder: (_, setObscure) => TextFormField(
                        controller: passwordCtrl,
                        obscureText: obscure,
                        style: GoogleFonts.cairo(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'كلمة المرور',
                          hintStyle: GoogleFonts.cairo(
                              fontSize: 13, color: AppColors.inkMuted),
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () {
                              obscure = !obscure;
                              setObscure(() {});
                            },
                          ),
                        ),
                        validator: validateStrongPassword,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('٨ أحرف — حرف كبير + رقم + رمز خاص',
                        style: GoogleFonts.cairo(
                            fontSize: 10.5, color: AppColors.inkMuted)),
                    if (error != null) ...[
                      const SizedBox(height: AppSpace.sm),
                      Text(error!,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: AppSpace.lg),
                    saving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheet(() {
                                saving = true;
                                error = null;
                              });
                              try {
                                await AuthService.instance.signUpStudent(
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  parentPhone: parentPhoneCtrl.text.trim(),
                                  password: passwordCtrl.text,
                                  groupId: widget.group.id,
                                );
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'تم إضافة الطالب ${nameCtrl.text.trim()} بنجاح',
                                          style: GoogleFonts.cairo()),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } on AuthException catch (e) {
                                setSheet(() {
                                  error = e.message;
                                  saving = false;
                                });
                              } catch (_) {
                                setSheet(() {
                                  error = 'حدث خطأ، حاول مرة أخرى';
                                  saving = false;
                                });
                              }
                            },
                            icon: const Icon(Icons.person_add_rounded),
                            label: Text('إضافة الطالب',
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w700)),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded),
        label: Text('إضافة طالب',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
      ),
      appBar: AppBar(
        title: Text(widget.group.title,
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'الترتيب والتصنيف',
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RankingScreen(group: widget.group)),
            ),
          ),
          IconButton(
            tooltip: 'الاختبارات',
            icon: const Icon(Icons.assignment_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ExamsScreen(group: widget.group)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<StudentRecord>>(
        stream:
            FirestoreService.instance.watchGroupStudents(widget.group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snapshot.data ?? [];
          return Column(
            children: [
              // ── Stats strip ────────────────────────────────────────────
              _StatsStrip(students: students),
              const SizedBox(height: AppSpace.sm),
              // ── Tab bar ────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.inkMuted,
                  labelStyle: GoogleFonts.cairo(
                      fontSize: 11.5, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11.5),
                  padding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  tabs: _tabs,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AttendanceTab(
                        students: students, group: widget.group),
                    _GradesTab(
                        students: students, group: widget.group),
                    _PaymentsTab(
                        students: students, group: widget.group),
                    _ContentTab(group: widget.group, isAdmin: _isAdmin),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Stats Strip ─────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final List<StudentRecord> students;
  const _StatsStrip({required this.students});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) return const SizedBox.shrink();
    final present = students
        .where((s) => s.attendance == AttendanceStatus.present)
        .length;
    final absent = students
        .where((s) => s.attendance == AttendanceStatus.absent)
        .length;
    final avgScore = students.isEmpty
        ? 0.0
        : students.map((s) => s.weeklyQuizScore).reduce((a, b) => a + b) /
            students.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
      child: Row(
        children: [
          Expanded(
              child: StatCard(
                  value: '$present',
                  label: 'حاضر',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success)),
          const SizedBox(width: 8),
          Expanded(
              child: StatCard(
                  value: '$absent',
                  label: 'غائب',
                  icon: Icons.cancel_outlined,
                  color: AppColors.danger)),
          const SizedBox(width: 8),
          Expanded(
              child: StatCard(
                  value: avgScore.toStringAsFixed(1),
                  label: 'متوسط الدرجة',
                  icon: Icons.insights_rounded,
                  color: AppColors.warning)),
        ],
      ),
    );
  }
}

// ── Attendance Tab ───────────────────────────────────────────────────────────

class _AttendanceTab extends StatelessWidget {
  final List<StudentRecord> students;
  final StudyGroup group;
  const _AttendanceTab({required this.students, required this.group});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) return _emptyState('لا يوجد طلاب في هذه المجموعة');
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpace.lg),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, i) {
        final s = students[i];
        return _StudentShell(
          student: s,
          group: group,
          trailing: _AttendanceToggle(
            status: s.attendance,
            onChanged: (v) async {
              await FirestoreService.instance.updateAttendance(
                studentId: s.id,
                status: v,
                groupId: group.id,
              );
            },
          ),
        );
      },
    );
  }
}

class _AttendanceToggle extends StatelessWidget {
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;
  const _AttendanceToggle(
      {required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, AttendanceStatus s, Color color) {
      final active = status == s;
      return GestureDetector(
        onTap: () => onChanged(s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : color)),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        seg('حاضر', AttendanceStatus.present, AppColors.success),
        const SizedBox(width: 4),
        seg('متأخر', AttendanceStatus.late, AppColors.warning),
        const SizedBox(width: 4),
        seg('غائب', AttendanceStatus.absent, AppColors.danger),
      ],
    );
  }
}

// ── Grades Tab ───────────────────────────────────────────────────────────────

class _GradesTab extends StatefulWidget {
  final List<StudentRecord> students;
  final StudyGroup group;
  const _GradesTab({required this.students, required this.group});

  @override
  State<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<_GradesTab> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final s in widget.students) {
      _controllers[s.id] = TextEditingController(
          text: s.weeklyQuizScore > 0
              ? s.weeklyQuizScore.toString()
              : '');
    }
  }

  @override
  void didUpdateWidget(_GradesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final s in widget.students) {
      if (!_controllers.containsKey(s.id)) {
        _controllers[s.id] = TextEditingController(
            text: s.weeklyQuizScore > 0
                ? s.weeklyQuizScore.toString()
                : '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) {
      return _emptyState('لا يوجد طلاب في هذه المجموعة');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpace.lg),
      itemCount: widget.students.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, i) {
        final s = widget.students[i];
        final ctrl = _controllers[s.id]!;
        return _StudentShell(
          student: s,
          group: widget.group,
          subtitle:
              'التقييم التراكمي: ${s.overallRating.toStringAsFixed(1)}٪',
          trailing: SizedBox(
            width: 80,
            child: TextFormField(
              controller: ctrl,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.cairo(
                  fontSize: 13, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                suffixText: '/١٠',
                suffixStyle: GoogleFonts.cairo(
                    fontSize: 10, color: AppColors.inkMuted),
              ),
              onEditingComplete: () async {
                final val = double.tryParse(ctrl.text);
                if (val != null && val >= 0 && val <= 10) {
                  await FirestoreService.instance.updateWeeklyScore(
                    studentId: s.id,
                    score: val,
                    groupId: widget.group.id,
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Payments Tab ─────────────────────────────────────────────────────────────

class _PaymentsTab extends StatelessWidget {
  final List<StudentRecord> students;
  final StudyGroup group;
  const _PaymentsTab({required this.students, required this.group});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) return _emptyState('لا يوجد طلاب في هذه المجموعة');
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpace.lg),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, i) {
        final s = students[i];
        return _PaymentCard(student: s, group: group);
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final StudentRecord student;
  final StudyGroup group;
  const _PaymentCard({required this.student, required this.group});

  Color get _statusColor {
    switch (student.paymentStatus) {
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.partial:
        return AppColors.warning;
      case PaymentStatus.unpaid:
        return AppColors.danger;
    }
  }

  String get _statusLabel {
    switch (student.paymentStatus) {
      case PaymentStatus.paid:
        return 'تم الدفع';
      case PaymentStatus.partial:
        return 'دفع جزئي';
      case PaymentStatus.unpaid:
        return 'لم يدفع';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.10),
                child: Text(
                  student.name.isNotEmpty
                      ? student.name.substring(0, 1)
                      : '؟',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                        style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    Text(
                        'متبقي: ${student.remainingPaidSessions} حصة',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: student.remainingPaidSessions > 0
                                ? AppColors.success
                                : AppColors.danger,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              InfoBadge(text: _statusLabel, color: _statusColor),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              // Sessions +/-
              _sessionBtn(
                icon: Icons.remove_rounded,
                color: AppColors.danger,
                onTap: () async {
                  if (student.remainingPaidSessions > 0) {
                    await FirestoreService.instance
                        .updateRemainingSessions(
                      studentId: student.id,
                      remaining: student.remainingPaidSessions - 1,
                      groupId: group.id,
                    );
                  }
                },
              ),
              const SizedBox(width: 4),
              Text('${student.remainingPaidSessions}',
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(width: 4),
              _sessionBtn(
                icon: Icons.add_rounded,
                color: AppColors.success,
                onTap: () async {
                  await FirestoreService.instance
                      .updateRemainingSessions(
                    studentId: student.id,
                    remaining: student.remainingPaidSessions + 1,
                    groupId: group.id,
                  );
                },
              ),
              const Spacer(),
              // Payment status cycle button
              ...PaymentStatus.values.map((p) {
                final active = student.paymentStatus == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: active
                        ? null
                        : () async {
                            await FirestoreService.instance
                                .updatePaymentStatus(
                              studentId: student.id,
                              status: p,
                              groupId: group.id,
                            );
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? _paymentColor(p)
                            : _paymentColor(p)
                                .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        _paymentLabel(p),
                        style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : _paymentColor(p)),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Color _paymentColor(PaymentStatus p) {
    switch (p) {
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.partial:
        return AppColors.warning;
      case PaymentStatus.unpaid:
        return AppColors.danger;
    }
  }

  String _paymentLabel(PaymentStatus p) {
    switch (p) {
      case PaymentStatus.paid:
        return 'دفع';
      case PaymentStatus.partial:
        return 'جزئي';
      case PaymentStatus.unpaid:
        return 'لم يدفع';
    }
  }

  Widget _sessionBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ── Content Tab ──────────────────────────────────────────────────────────────

class _ContentTab extends StatelessWidget {
  final StudyGroup group;
  final bool isAdmin;
  const _ContentTab({required this.group, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        // ── Homework ──────────────────────────────────────────────────
        SectionTitle(
          title: 'حلول الواجبات',
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary),
            onPressed: () => _showAddHomeworkSheet(context),
          ),
        ),
        StreamBuilder<List<HomeworkFile>>(
          stream:
              FirestoreService.instance.watchGroupHomework(group.id),
          builder: (ctx, snap) {
            final files = snap.data ?? [];
            if (files.isEmpty) {
              return _miniEmpty('لا توجد حلول مرفوعة بعد');
            }
            return Column(
              children: files
                  .map((f) => _FileRow(
                        title: f.title,
                        subtitle: _dateLabel(f.uploadedAt),
                        icon: Icons.picture_as_pdf_rounded,
                        iconColor: AppColors.danger,
                        url: f.url,
                        onDelete: isAdmin
                            ? () async {
                                await FirestoreService.instance
                                    .deleteHomework(group.id, f.id);
                              }
                            : null,
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: AppSpace.lg),
        // ── Videos ───────────────────────────────────────────────────
        SectionTitle(
          title: 'شروحات الفيديو',
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary),
            onPressed: () => _showAddVideoSheet(context),
          ),
        ),
        StreamBuilder<List<LessonVideo>>(
          stream: FirestoreService.instance.watchGroupVideos(group.id),
          builder: (ctx, snap) {
            final videos = snap.data ?? [];
            if (videos.isEmpty) {
              return _miniEmpty('لا توجد فيديوهات مضافة بعد');
            }
            return Column(
              children: videos
                  .map((v) => _FileRow(
                        title: v.title,
                        subtitle: v.url,
                        icon: Icons.play_circle_fill_rounded,
                        iconColor: AppColors.primary,
                        url: v.url,
                        onDelete: isAdmin
                            ? () async {
                                await FirestoreService.instance
                                    .deleteVideo(group.id, v.id);
                              }
                            : null,
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: AppSpace.lg),
        // ── Send file to student (admin only) ─────────────────────────
        if (isAdmin) ...[
          const SectionTitle(title: 'إرسال ملف لطالب'),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        SendStudentFileScreen(group: group)),
              ),
              icon: const Icon(Icons.send_rounded),
              label: Text('إرسال ملف خاص لطالب محدد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showAddHomeworkSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddContentSheet(
        title: 'إضافة حل واجب',
        titleHint: 'عنوان الواجب',
        urlHint: 'رابط ملف PDF (Google Drive أو غيره)',
        urlIcon: Icons.picture_as_pdf_rounded,
        titleCtrl: titleCtrl,
        urlCtrl: urlCtrl,
        onSave: () async {
          if (titleCtrl.text.trim().isEmpty ||
              urlCtrl.text.trim().isEmpty) { return; }
          await FirestoreService.instance.addGroupHomework(
            groupId: group.id,
            title: titleCtrl.text.trim(),
            url: urlCtrl.text.trim(),
          );
        },
      ),
    );
  }

  void _showAddVideoSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddContentSheet(
        title: 'إضافة رابط شرح',
        titleHint: 'عنوان الفيديو',
        urlHint: 'https://youtube.com/watch?v=...',
        urlIcon: Icons.play_circle_outline_rounded,
        titleCtrl: titleCtrl,
        urlCtrl: urlCtrl,
        onSave: () async {
          if (titleCtrl.text.trim().isEmpty ||
              urlCtrl.text.trim().isEmpty) { return; }
          await FirestoreService.instance.addGroupVideo(
            groupId: group.id,
            title: titleCtrl.text.trim(),
            url: urlCtrl.text.trim(),
          );
        },
      ),
    );
  }

  String _dateLabel(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Add Content Sheet ─────────────────────────────────────────────────────────

class _AddContentSheet extends StatefulWidget {
  final String title;
  final String titleHint;
  final String urlHint;
  final IconData urlIcon;
  final TextEditingController titleCtrl;
  final TextEditingController urlCtrl;
  final Future<void> Function() onSave;
  const _AddContentSheet({
    required this.title,
    required this.titleHint,
    required this.urlHint,
    required this.urlIcon,
    required this.titleCtrl,
    required this.urlCtrl,
    required this.onSave,
  });

  @override
  State<_AddContentSheet> createState() => _AddContentSheetState();
}

class _AddContentSheetState extends State<_AddContentSheet> {
  bool _saving = false;

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
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: widget.titleCtrl,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.titleHint,
                hintStyle: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.inkMuted),
                prefixIcon: const Icon(Icons.title_rounded,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: widget.urlCtrl,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.urlHint,
                hintStyle: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.inkMuted),
                prefixIcon:
                    Icon(widget.urlIcon, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    label: 'حفظ',
                    icon: Icons.check_rounded,
                    onPressed: () async {
                      setState(() => _saving = true);
                      await widget.onSave();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Student Shell ─────────────────────────────────────────────────────────────

class _StudentShell extends StatelessWidget {
  final StudentRecord student;
  final StudyGroup group;
  final Widget trailing;
  final String? subtitle;
  const _StudentShell({
    required this.student,
    required this.group,
    required this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                StudentDetailScreen(student: student, group: group)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.10),
              backgroundImage: student.photoUrl.isNotEmpty
                  ? NetworkImage(student.photoUrl)
                  : null,
              child: student.photoUrl.isEmpty
                  ? Text(
                      student.name.isNotEmpty
                          ? student.name.substring(0, 1)
                          : '؟',
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: 13),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            color: AppColors.inkMuted)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ── File Row ─────────────────────────────────────────────────────────────────

class _FileRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onDelete;
  final String? url;
  const _FileRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onDelete,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: url != null && url!.isNotEmpty
          ? () async {
              final uri = Uri.tryParse(url!);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('تعذّر فتح الرابط', style: GoogleFonts.cairo()),
                  backgroundColor: AppColors.danger,
                ));
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
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
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                            fontSize: 10.5, color: AppColors.inkMuted)),
                ],
              ),
            ),
            if (url != null && url!.isNotEmpty)
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

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _emptyState(String msg) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded,
                size: 48, color: AppColors.inkMuted),
            const SizedBox(height: AppSpace.md),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.inkMuted)),
          ],
        ),
      ),
    );

Widget _miniEmpty(String msg) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Center(
        child: Text(msg,
            style: GoogleFonts.cairo(
                fontSize: 12, color: AppColors.inkMuted)),
      ),
    );
