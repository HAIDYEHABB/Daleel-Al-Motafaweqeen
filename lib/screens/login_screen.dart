import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'admin_registration_screen.dart';
import 'registration_screen.dart';
import 'student_home_screen.dart';
import 'teacher_groups_hub_screen.dart';

/// Real entry point of the app. Three tabs — student / teacher / admin
/// — so each role only ever reaches its own screens from here on.
/// Teacher and admin both land on TeacherGroupsHubScreen (same
/// permissions, different account, and FirestoreService resolves the
/// correct underlying teacher's data via Session — see session.dart).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpace.sm),
              const AppLogoMark(size: 64),
              const SizedBox(height: AppSpace.sm),
              Text('دليل المتفوقين',
                  style: GoogleFonts.cairo(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('سجّل الدخول لمتابعة رحلتك التعليمية',
                  style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.inkMuted)),
              const SizedBox(height: AppSpace.md),
              Container(
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
                  labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 11.5),
                  padding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'دخول الطالب'),
                    Tab(text: 'دخول المعلم'),
                    Tab(text: 'دخول الأدمن'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LoginForm(
                      hint: '01xxxxxxxxx',
                      expectedRole: UserRole.student,
                      footer: _signupFooter(
                        context,
                        prompt: 'طالب جديد؟ ',
                        actionLabel: 'إنشاء حساب والانضمام لمجموعة',
                        destination: const RegistrationScreen(),
                      ),
                    ),
                    _LoginForm(
                      hint: 'رقم هاتف المعلم',
                      expectedRole: UserRole.teacher,
                      footer: _signupFooter(
                        context,
                        prompt: 'معلم جديد؟ ',
                        actionLabel: 'إنشاء حساب معلم',
                        destination: const _TeacherSignupScreen(),
                      ),
                    ),
                    _LoginForm(
                      hint: 'رقم هاتف الأدمن',
                      expectedRole: UserRole.admin,
                      footer: _signupFooter(
                        context,
                        prompt: 'أدمن جديد؟ ',
                        actionLabel: 'إنشاء حساب أدمن',
                        destination: const AdminRegistrationScreen(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signupFooter(
    BuildContext context, {
    required String prompt,
    required String actionLabel,
    required Widget destination,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => destination),
          ),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.inkMuted),
              children: [
                TextSpan(text: prompt),
                TextSpan(
                  text: actionLabel,
                  style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final String hint;
  final UserRole expectedRole;
  final Widget? footer;
  const _LoginForm({required this.hint, required this.expectedRole, this.footer});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  String _roleTabLabel(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return 'دخول المعلم';
      case UserRole.admin:
        return 'دخول الأدمن';
      case UserRole.student:
        return 'دخول الطالب';
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role = await AuthService.instance.login(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      if (role != widget.expectedRole) {
        setState(() {
          _error = 'هذا الحساب حساب ${role == UserRole.teacher ? 'معلم' : role == UserRole.admin ? 'أدمن' : 'طالب'}'
              '، استخدم تبويب "${_roleTabLabel(role)}"';
          _loading = false;
        });
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => role == UserRole.student
              ? const StudentHomeScreen()
              : const TeacherGroupsHubScreen(),
        ),
      );
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ غير متوقع، حاول مرة أخرى';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.cairo(fontSize: 13, color: AppColors.inkMuted),
              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.cairo(fontSize: 13, color: AppColors.inkMuted),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(_error!,
                style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.danger, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: AppSpace.lg),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : PrimaryButton(label: 'تسجيل الدخول', icon: Icons.login_rounded, onPressed: _submit),
          if (widget.footer != null) widget.footer!,
        ],
      ),
    );
  }
}

/// One-time teacher registration screen.
/// Accessible from the teacher login tab footer.
class _TeacherSignupScreen extends StatefulWidget {
  const _TeacherSignupScreen();

  @override
  State<_TeacherSignupScreen> createState() => _TeacherSignupScreenState();
}

class _TeacherSignupScreenState extends State<_TeacherSignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() => _error = 'من فضلك اكمل جميع الحقول');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'كلمة المرور يجب أن تكون ٦ أحرف على الأقل');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await AuthService.instance.signUpTeacher(
        name: name,
        phone: phone,
        password: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء حساب المعلم بنجاح! سجّل الدخول الآن.', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'حدث خطأ غير متوقع، حاول مرة أخرى'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب معلم')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: _nameController,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'الاسم الكامل',
                hintStyle: GoogleFonts.cairo(fontSize: 13, color: AppColors.inkMuted),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: '01xxxxxxxxx',
                hintStyle: GoogleFonts.cairo(fontSize: 13, color: AppColors.inkMuted),
                prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'كلمة المرور (٦ أحرف على الأقل)',
                hintStyle: GoogleFonts.cairo(fontSize: 13, color: AppColors.inkMuted),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(_error!,
                  style: GoogleFonts.cairo(
                      fontSize: 12.5, color: AppColors.danger, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: AppSpace.lg),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    label: 'إنشاء الحساب',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: _submit,
                  ),
          ],
        ),
      ),
    );
  }
}
