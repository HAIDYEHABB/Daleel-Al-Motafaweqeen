import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'registration_screen.dart';
import 'teacher_groups_hub_screen.dart';
import 'group_management_screen.dart';
import 'homework_upload_screen.dart';
import 'student_home_screen.dart';

/// Dev-only entry point so you can jump straight to any of the 5 screens
/// while there's no real auth/backend wired up yet. Once login is real,
/// set `home:` in main.dart back to the actual first screen and delete
/// this file.
class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem('تسجيل حساب طالب جديد', Icons.person_add_alt_1_rounded,
          (ctx) => const RegistrationScreen()),
      _MenuItem('لوحة تحكم المعلم - المجموعات', Icons.dashboard_customize_rounded,
          (ctx) => const TeacherGroupsHubScreen()),
      _MenuItem('إدارة المجموعة (حضور / درجات / مصاريف)', Icons.fact_check_rounded,
          (ctx) => GroupManagementScreen(group: MockData.groups.first)),
      _MenuItem('رفع المحتوى وحلول الواجبات', Icons.upload_file_rounded,
          (ctx) => HomeworkUploadScreen(group: MockData.groups.first)),
      _MenuItem('الرئيسية وملف إنجاز الطالب', Icons.home_rounded,
          (ctx) => const StudentHomeScreen()),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            const SizedBox(height: AppSpace.md),
            const Center(child: AppLogoMark(size: 64)),
            const SizedBox(height: AppSpace.md),
            Text('دليل المتفوقين',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
            Text('معاينة الشاشات (وضع التطوير)',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 12, color: AppColors.inkMuted)),
            const SizedBox(height: AppSpace.xl),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: item.builder)),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(item.label,
                                  style: GoogleFonts.cairo(
                                      fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            ),
                            const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.inkMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  _MenuItem(this.label, this.icon, this.builder);
}
