import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'teacher_groups_hub_screen.dart';

/// Self-service admin signup — "الأدمن زي المدرس بالظبط، بس ليه أكونت
/// منفصل ومرتبط بمعلم معيّن". Same shape as student registration, but
/// picks a teacher to assist instead of a group to join.
class AdminRegistrationScreen extends StatefulWidget {
  const AdminRegistrationScreen({super.key});

  @override
  State<AdminRegistrationScreen> createState() => _AdminRegistrationScreenState();
}

class _AdminRegistrationScreenState extends State<AdminRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedTeacherId;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signUpAdmin(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        teacherId: _selectedTeacherId!,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TeacherGroupsHubScreen()),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'حدث خطأ غير متوقع، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب أدمن')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: const AppLogoMark(size: 64)),
                const SizedBox(height: AppSpace.md),
                Text('حساب أدمن — مساعد معلم',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('نفس صلاحيات المعلم بالكامل، على بيانات المعلم اللي هتختاره',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.inkMuted)),
                const SizedBox(height: AppSpace.xl),
                _label('اسم الأدمن'),
                _field(controller: _nameController, hint: 'الاسم بالكامل', icon: Icons.person_outline),
                const SizedBox(height: AppSpace.md),
                _label('رقم الهاتف'),
                _field(
                    controller: _phoneController,
                    hint: '01xxxxxxxxx',
                    icon: Icons.phone_iphone_rounded,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: AppSpace.md),
                _label('كلمة المرور'),
                _field(
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                _label('اختر المعلم الذي تساعده'),
                StreamBuilder<List<TeacherProfile>>(
                  stream: FirestoreService.instance.watchAllTeachers(),
                  builder: (context, snapshot) {
                    final teachers = snapshot.data ?? [];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedTeacherId,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(Icons.school_outlined, color: AppColors.primary),
                          ),
                          hint: Text(
                              snapshot.connectionState == ConnectionState.waiting
                                  ? 'جارِ تحميل المعلمين...'
                                  : 'اختر المعلم',
                              style: GoogleFonts.cairo(fontSize: 14, color: AppColors.inkMuted)),
                          items: teachers
                              .map((t) => DropdownMenuItem(
                                    value: t.id,
                                    child: Text('${t.name} — ${t.phone}', style: GoogleFonts.cairo(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedTeacherId = v),
                          validator: (v) => v == null ? 'من فضلك اختر المعلم' : null,
                        ),
                      ),
                    );
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.danger, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: AppSpace.xl),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(label: 'إنشاء حساب الأدمن', icon: Icons.admin_panel_settings_outlined, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, right: 4),
        child: Text(text,
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(fontSize: 14),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'حقل مطلوب' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(fontSize: 13, color: AppColors.inkMuted),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}
