import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/common_widgets.dart';
import 'student_home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String? _selectedGroupId;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  // Photo state — bytes held locally until submit, then uploaded
  Uint8List? _photoBytes;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _uploadingPhoto = true);
    try {
      final picked = await StorageService.instance.pickImage();
      if (picked != null) {
        final (bytes, _) = picked;
        setState(() => _photoBytes = bytes);
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      // 1. Register the account first (gets a UID)
      String? photoUrl;
      if (_photoBytes != null) {
        // Temp upload path — will be moved after UID is known
        // We upload now as the auth signup generates the UID we need
        // so we do signup first, then upload
      }

      await AuthService.instance.signUpStudent(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        parentPhone: _parentPhoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        groupId: _selectedGroupId!,
        photoUrl: '', // will update below after upload
      );

      // 2. If a photo was picked, upload it now that we have a UID
      if (_photoBytes != null) {
        final uid = AuthService.instance.currentUser!.uid;
        photoUrl = await StorageService.instance.uploadBytes(
          path: 'profile_photos/$uid.jpg',
          bytes: _photoBytes!,
          contentType: 'image/jpeg',
        );
        // 3. Update the student doc with the real URL
        await FirestoreService.instance
            .updateStudentPhoto(studentId: uid, photoUrl: photoUrl);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpace.md),
                const Center(child: AppLogoMark(size: 72)),
                const SizedBox(height: AppSpace.md),
                Text('دليل المتفوقين',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('إنشاء حساب طالب جديد',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        fontSize: 14, color: AppColors.inkMuted)),
                const SizedBox(height: AppSpace.xl),

                // ── Profile photo ──────────────────────────────────
                _label('صورة الملف الشخصي (اختياري)'),
                _PhotoPickerButton(
                  bytes: _photoBytes,
                  uploading: _uploadingPhoto,
                  onTap: _pickPhoto,
                ),
                const SizedBox(height: AppSpace.md),

                // ── Name ───────────────────────────────────────────
                _label('الاسم الرباعي (٤ أسماء بالعربية)'),
                TextFormField(
                  controller: _nameCtrl,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: _dec(
                      'مثال: أحمد محمد علي إبراهيم',
                      Icons.person_outline),
                  validator: validateArabicName,
                ),
                const SizedBox(height: 4),
                Text('اكتب الاسم الأول والثاني والثالث والرابع مفصولين بمسافة',
                    style: GoogleFonts.cairo(
                        fontSize: 10.5, color: AppColors.inkMuted)),
                const SizedBox(height: AppSpace.md),

                // ── Phone ──────────────────────────────────────────
                _label('رقم هاتف الطالب'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration:
                      _dec('01xxxxxxxxx', Icons.phone_iphone_rounded),
                  validator: validateEgyptianPhone,
                ),
                const SizedBox(height: AppSpace.md),

                // ── Parent phone ───────────────────────────────────
                _label('رقم هاتف ولي الأمر'),
                TextFormField(
                  controller: _parentPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: _dec(
                      '01xxxxxxxxx', Icons.phone_forwarded_outlined),
                  validator: (v) =>
                      validateParentPhone(v, _phoneCtrl.text),
                ),
                const SizedBox(height: AppSpace.md),

                // ── Password ───────────────────────────────────────
                _label('كلمة المرور'),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration:
                      _dec('••••••••', Icons.lock_outline_rounded)
                          .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: validateStrongPassword,
                ),
                const SizedBox(height: 4),
                Text('٨ أحرف على الأقل — حرف كبير + رقم + رمز خاص',
                    style: GoogleFonts.cairo(
                        fontSize: 10.5, color: AppColors.inkMuted)),
                const SizedBox(height: AppSpace.md),

                // ── Group selector ────────────────────────────────
                _label('اختر مجموعتك الدراسية'),
                StreamBuilder<List<StudyGroup>>(
                  stream: FirestoreService.instance.watchAllGroups(),
                  builder: (ctx, snap) {
                    final groups = snap.data ?? [];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedGroupId,
                          isExpanded: true,
                          icon: const Icon(
                              Icons.keyboard_arrow_down_rounded),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(Icons.groups_2_outlined,
                                color: AppColors.primary),
                          ),
                          hint: Text(
                            snap.connectionState ==
                                    ConnectionState.waiting
                                ? 'جارِ تحميل المجموعات...'
                                : 'اختر المجموعة المناسبة لك',
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppColors.inkMuted),
                          ),
                          items: groups
                              .map((g) => DropdownMenuItem(
                                    value: g.id,
                                    child: Text(g.title,
                                        style: GoogleFonts.cairo(
                                            fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedGroupId = v),
                          validator: (v) => v == null
                              ? 'من فضلك اختر مجموعة'
                              : null,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpace.md),

                // ── Info banner ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'هيتم ربط حسابك تلقائيًا بمعلم المجموعة اللي هتختارها',
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: AppSpace.xl),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        label: 'إنشاء الحساب والانضمام',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _submit,
                      ),
                const SizedBox(height: AppSpace.md),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: AppColors.inkMuted),
                        children: [
                          const TextSpan(text: 'عندك حساب بالفعل؟ '),
                          TextSpan(
                            text: 'تسجيل الدخول',
                            style: GoogleFonts.cairo(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
            style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      );

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.cairo(fontSize: 13, color: AppColors.inkMuted),
        prefixIcon: Icon(icon, color: AppColors.primary),
      );
}

// ── Photo picker button ───────────────────────────────────────────────────────

class _PhotoPickerButton extends StatelessWidget {
  final Uint8List? bytes;
  final bool uploading;
  final VoidCallback onTap;
  const _PhotoPickerButton({
    required this.bytes,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Row(
        children: [
          // Avatar preview
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.10),
                backgroundImage:
                    bytes != null ? MemoryImage(bytes!) : null,
                child: bytes == null
                    ? const Icon(Icons.add_a_photo_outlined,
                        color: AppColors.primary, size: 26)
                    : null,
              ),
              if (uploading)
                const Positioned.fill(
                  child: CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded,
                      size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bytes != null
                      ? 'تم اختيار الصورة ✓'
                      : 'اضغط لاختيار صورة من الجهاز',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: bytes != null
                          ? AppColors.success
                          : AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'صور JPG أو PNG — اختياري',
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
