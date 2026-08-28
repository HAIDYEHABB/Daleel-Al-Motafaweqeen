/// Shared field validators used across all sign-up / add-student forms.
library;

/// Egyptian mobile number: starts with 010/011/012/015, exactly 11 digits.
String? validateEgyptianPhone(String? value) {
  if (value == null || value.trim().isEmpty) return 'رقم الهاتف مطلوب';
  final digits = value.trim().replaceAll(RegExp(r'\s'), '');
  if (!RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(digits)) {
    return 'أدخل رقم هاتف مصري صحيح (11 رقم يبدأ بـ 010/011/012/015)';
  }
  return null;
}

/// Arabic-only name: exactly 4 words, no Latin characters.
String? validateArabicName(String? value) {
  if (value == null || value.trim().isEmpty) return 'الاسم مطلوب';
  final name = value.trim();
  if (RegExp(r'[a-zA-Z]').hasMatch(name)) {
    return 'الاسم يجب أن يكون باللغة العربية فقط';
  }
  final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length != 4) return 'أدخل الاسم الرباعي كاملاً (٤ أسماء)';
  return null;
}

/// Strong password: ≥8 chars, has uppercase, lowercase, digit, special char.
String? validateStrongPassword(String? value) {
  if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
  if (value.length < 8) return 'كلمة المرور يجب أن تكون ٨ أحرف على الأقل';
  if (!value.contains(RegExp(r'[A-Z]'))) {
    return 'يجب أن تحتوي على حرف كبير (A-Z)';
  }
  if (!value.contains(RegExp(r'[a-z]'))) {
    return 'يجب أن تحتوي على حرف صغير (a-z)';
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'يجب أن تحتوي على رقم';
  }
  if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;/]'))) {
    return 'يجب أن تحتوي على رمز خاص (!@#\$% ...)';
  }
  return null;
}

/// Parent phone: mandatory, must be a valid Egyptian number, must differ from student phone.
String? validateParentPhone(String? value, String studentPhone) {
  if (value == null || value.trim().isEmpty) {
    return 'رقم هاتف ولي الأمر مطلوب';
  }
  final phoneError = validateEgyptianPhone(value);
  if (phoneError != null) return phoneError;
  if (value.trim() == studentPhone.trim()) {
    return 'رقم ولي الأمر يجب أن يختلف عن رقم الطالب';
  }
  return null;
}
