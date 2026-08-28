import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/session.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';
import 'group_management_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'send_student_file_screen.dart';

class TeacherGroupsHubScreen extends StatefulWidget {
  const TeacherGroupsHubScreen({super.key});

  @override
  State<TeacherGroupsHubScreen> createState() =>
      _TeacherGroupsHubScreenState();
}

class _TeacherGroupsHubScreenState extends State<TeacherGroupsHubScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _GroupsPage(),
      const DashboardScreen(),
      const NotificationsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.groups_2_outlined),
            selectedIcon: const Icon(Icons.groups_2_rounded,
                color: AppColors.primary),
            label: 'المجموعات',
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded,
                color: AppColors.primary),
            label: 'لوحة المتابعة',
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications_rounded,
                color: AppColors.primary),
            label: 'الإشعارات',
          ),
        ],
      ),
    );
  }
}

// ── Groups Page ───────────────────────────────────────────────────────────────

class _GroupsPage extends StatelessWidget {
  const _GroupsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGroupSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: Text('مجموعة جديدة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: StreamBuilder<List<StudyGroup>>(
          stream: FirestoreService.instance.watchTeacherGroups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final groups = snapshot.data ?? [];
            final totalStudents =
                groups.fold<int>(0, (a, g) => a + g.studentCount);

            return ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                _Header(
                    totalStudents: totalStudents, groupCount: groups.length),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(title: 'مجموعاتي'),
                      if (groups.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpace.xl),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.groups_outlined,
                                    size: 48, color: AppColors.inkMuted),
                                const SizedBox(height: AppSpace.sm),
                                Text(
                                    'لا توجد مجموعات بعد\nاضغط "مجموعة جديدة" للبدء',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        color: AppColors.inkMuted)),
                              ],
                            ),
                          ),
                        ),
                      ...groups.map((g) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpace.md),
                            child: _GroupCard(group: g),
                          )),
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

  void _showAddGroupSheet(BuildContext context) {
    final locationController = TextEditingController();
    final dayController = TextEditingController();
    final timeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpace.lg,
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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('إضافة مجموعة جديدة',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(height: AppSpace.md),
                  TextFormField(
                    controller: locationController,
                    style: GoogleFonts.cairo(fontSize: 14),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'حقل مطلوب' : null,
                    decoration: InputDecoration(
                      hintText: 'المكان (مثال: المعادي)',
                      hintStyle: GoogleFonts.cairo(
                          fontSize: 13, color: AppColors.inkMuted),
                      prefixIcon: const Icon(Icons.location_on_outlined,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  TextFormField(
                    controller: dayController,
                    style: GoogleFonts.cairo(fontSize: 14),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'حقل مطلوب' : null,
                    decoration: InputDecoration(
                      hintText: 'اليوم (مثال: السبت)',
                      hintStyle: GoogleFonts.cairo(
                          fontSize: 13, color: AppColors.inkMuted),
                      prefixIcon: const Icon(Icons.calendar_today_outlined,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  TextFormField(
                    controller: timeController,
                    style: GoogleFonts.cairo(fontSize: 14),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'حقل مطلوب' : null,
                    decoration: InputDecoration(
                      hintText: 'الميعاد (مثال: ٤:٠٠ م)',
                      hintStyle: GoogleFonts.cairo(
                          fontSize: 13, color: AppColors.inkMuted),
                      prefixIcon: const Icon(Icons.access_time_rounded,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  submitting
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(
                          label: 'إضافة المجموعة',
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => submitting = true);
                            // Check for duplicate
                            final exists = await FirestoreService.instance
                                .groupExists(
                              location: locationController.text.trim(),
                              dayLabel: dayController.text.trim(),
                              timeLabel: timeController.text.trim(),
                            );
                            if (exists) {
                              setSheetState(() {
                                submitting = false;
                              });
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(const SnackBar(
                                  content: Text(
                                      'مجموعة بنفس المكان واليوم والميعاد موجودة بالفعل'),
                                  backgroundColor: AppColors.danger,
                                ));
                              }
                              return;
                            }
                            await FirestoreService.instance.createGroup(
                              location: locationController.text.trim(),
                              dayLabel: dayController.text.trim(),
                              timeLabel: timeController.text.trim(),
                            );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int totalStudents;
  final int groupCount;
  const _Header({required this.totalStudents, required this.groupCount});

  @override
  Widget build(BuildContext context) {
    final isAdmin = Session.instance.role == UserRole.admin;
    return AppSwooshHeader(
      height: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showEditPhotoSheet(context),
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: FirestoreService.instance.watchMyProfile(),
                  builder: (ctx, snap) {
                    final photoUrl =
                        snap.data?['photoUrl'] as String? ?? '';
                    return Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 22)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 9, color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أهلاً بيك 👋',
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    Text(
                        isAdmin
                            ? 'مسؤول — دليل المتفوقين'
                            : 'معلم — دليل المتفوقين',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await AuthService.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(
                child: _statPill(
                    icon: Icons.groups_2_rounded,
                    value: '$totalStudents',
                    label: 'إجمالي الطلاب'),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: _statPill(
                    icon: Icons.grid_view_rounded,
                    value: '$groupCount',
                    label: 'عدد المجموعات'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditPhotoSheet(BuildContext context) {
    bool uploading = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Container(
          margin: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xl),
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تحديث الصورة الشخصية',
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: AppSpace.lg),
              uploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: () async {
                        setSheet(() => uploading = true);
                        try {
                          final picked = await StorageService.instance
                              .pickImage();
                          if (picked == null) {
                            setSheet(() => uploading = false);
                            return;
                          }
                          final (bytes, name) = picked;
                          final ext = name.contains('.')
                              ? name.split('.').last
                              : 'jpg';
                          final uid =
                              AuthService.instance.currentUser!.uid;
                          final role = Session.instance.role ==
                                  UserRole.admin
                              ? 'admins'
                              : 'teachers';
                          final url = await StorageService.instance
                              .uploadBytes(
                            path:
                                'profile_photos/${role}_$uid.$ext',
                            bytes: bytes,
                            contentType: 'image/$ext',
                          );
                          await FirestoreService.instance
                              .updateMyPhoto(photoUrl: url);
                          if (sheetCtx.mounted) {
                            Navigator.pop(sheetCtx);
                          }
                        } catch (_) {
                          setSheet(() => uploading = false);
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text('اختر صورة من الجهاز',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(
      {required IconData icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Group Card ────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final StudyGroup group;
  const _GroupCard({required this.group});

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
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.location_on_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(group.title,
                    style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ),
              InfoBadge(
                  text: '${group.studentCount} طالب',
                  icon: Icons.person_outline),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              InfoBadge(
                text: 'حضور ${group.attendanceRate.toInt()}٪',
                color: AppColors.success,
                icon: Icons.event_available_outlined,
              ),
              const SizedBox(width: 8),
              InfoBadge(
                text: 'تقييم ${group.averageRating.toInt()}٪',
                color: AppColors.warning,
                icon: Icons.star_border_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          // Quick action buttons
          Row(
            children: [
              Expanded(
                child: _quickAction(context,
                    icon: Icons.fact_check_outlined,
                    label: 'الحضور',
                    onTap: () => _openGroup(context, initialTab: 0)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _quickAction(context,
                    icon: Icons.grade_outlined,
                    label: 'الدرجات',
                    onTap: () => _openGroup(context, initialTab: 1)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _quickAction(context,
                    icon: Icons.payments_outlined,
                    label: 'الاشتراك',
                    onTap: () => _openGroup(context, initialTab: 2)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _quickAction(context,
                    icon: Icons.folder_open_outlined,
                    label: 'المحتوى',
                    onTap: () => _openGroup(context, initialTab: 3)),
              ),
              // Send private file — teacher & admin
              const SizedBox(width: 6),
              Expanded(
                child: _quickAction(context,
                    icon: Icons.send_rounded,
                    label: 'إرسال ملف',
                    onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SendStudentFileScreen(group: group),
                          ),
                        )),
              ),
            ],
          ),
          // Edit / delete — teacher & admin
          const SizedBox(height: AppSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEditSheet(context),
                icon: const Icon(Icons.edit_outlined,
                    size: 15, color: AppColors.primary),
                label: Text('تعديل',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.primary)),
                style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6)),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 15, color: AppColors.danger),
                label: Text('حذف',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.danger)),
                style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openGroup(BuildContext context, {required int initialTab}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GroupManagementScreen(group: group, initialTab: initialTab),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final locationCtrl = TextEditingController(text: group.location);
    final dayCtrl = TextEditingController(text: group.dayLabel);
    final timeCtrl = TextEditingController(text: group.timeLabel);
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('تعديل بيانات المجموعة',
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: AppSpace.md),
                TextField(
                  controller: locationCtrl,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'المكان',
                    hintStyle: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.inkMuted),
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                TextField(
                  controller: dayCtrl,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'اليوم',
                    hintStyle: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.inkMuted),
                    prefixIcon: const Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                TextField(
                  controller: timeCtrl,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'الميعاد',
                    hintStyle: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.inkMuted),
                    prefixIcon: const Icon(Icons.access_time_rounded,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                saving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () async {
                          if (locationCtrl.text.trim().isEmpty ||
                              dayCtrl.text.trim().isEmpty ||
                              timeCtrl.text.trim().isEmpty) { return; }
                          setSheet(() => saving = true);
                          await FirestoreService.instance.updateGroup(
                            groupId: group.id,
                            location: locationCtrl.text.trim(),
                            dayLabel: dayCtrl.text.trim(),
                            timeLabel: timeCtrl.text.trim(),
                          );
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        },
                        child: Text('حفظ التعديلات',
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('حذف المجموعة',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800, color: AppColors.ink)),
        content: Text(
          'هل أنت متأكد من حذف "${group.title}"؟\nلن يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(fontSize: 13, color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(color: AppColors.inkMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: Text('حذف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await FirestoreService.instance.deleteGroup(group.id);
    }
  }

  Widget _quickAction(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
