import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'session.dart';

enum UserRole { teacher, admin, student }

/// Firebase Auth requires an email, but our screens only ask for a
/// phone number (matching the original brief). We convert phone -> a
/// fake-but-valid email under a fixed domain so Firebase is happy while
/// the user never sees anything but their phone number.
String _phoneToPseudoEmail(String phone) {
  final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return '$digitsOnly@daleel-app.local';
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Creates a teacher account. Called once per teacher (you, the
  /// tutor) — there's no teacher-facing "sign up" screen yet, so run
  /// this manually once (see README) or wire a hidden setup screen.
  Future<void> signUpTeacher({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _phoneToPseudoEmail(phone),
        password: password,
      );
      await _db.collection('teachers').doc(cred.user!.uid).set({
        'name': name,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  /// Creates an admin account — "الأدمن زي المدرس بالظبط ليه الصلاحية
  /// إنه يعمل كل حاجة بيعملها المدرس": same permissions as the teacher,
  /// but a separate login, and scoped to ONE specific teacher's data
  /// (picked here, same pattern as a student picking their group).
  Future<void> signUpAdmin({
    required String name,
    required String phone,
    required String password,
    required String teacherId,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _phoneToPseudoEmail(phone),
        password: password,
      );
      await _db.collection('admins').doc(cred.user!.uid).set({
        'name': name,
        'phone': phone,
        'teacherId': teacherId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  /// Creates a student account AND links them to the chosen group's
  /// teacher in one step — this is requirement (7) from the brief:
  /// picking a group at signup automatically associates the student
  /// with that teacher.
  Future<void> signUpStudent({
    required String name,
    required String phone,
    required String parentPhone,
    required String password,
    required String groupId,
    String photoUrl = '',
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _phoneToPseudoEmail(phone),
        password: password,
      );

      final groupDoc = await _db.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw AuthException('المجموعة المختارة لم تعد موجودة');
      }
      final teacherId = groupDoc.data()!['teacherId'] as String;

      await _db.collection('students').doc(cred.user!.uid).set({
        'name': name,
        'phone': phone,
        'parentPhone': parentPhone,
        'groupId': groupId,
        'teacherId': teacherId,
        'photoUrl': photoUrl,
        'remainingPaidSessions': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('groups').doc(groupId).update({
        'studentCount': FieldValue.increment(1),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  /// Logs in, determines the account's role, and — crucially for
  /// admins — populates Session.effectiveTeacherId so every screen
  /// downstream (groups, students, ranking) reads/writes the correct
  /// teacher's data without needing to know whether the logged-in
  /// person is the teacher or their admin.
  Future<UserRole> login({required String phone, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _phoneToPseudoEmail(phone),
        password: password,
      );
      return _resolveRoleAndSession(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  /// Called on app start when Firebase already has a signed-in user
  /// (persisted session) — rebuilds Session the same way login() does,
  /// so a hot restart doesn't leave an admin pointed at the wrong
  /// teacher's data. Returns null if the account isn't set up in
  /// Firestore under any role (shouldn't normally happen).
  Future<UserRole?> resolveCurrentRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      return await _resolveRoleAndSession(uid);
    } on AuthException {
      return null;
    }
  }

  Future<UserRole> _resolveRoleAndSession(String uid) async {
    final teacherDoc = await _db.collection('teachers').doc(uid).get();
    if (teacherDoc.exists) {
      Session.instance
        ..role = UserRole.teacher
        ..effectiveTeacherId = uid;
      return UserRole.teacher;
    }

    final adminDoc = await _db.collection('admins').doc(uid).get();
    if (adminDoc.exists) {
      Session.instance
        ..role = UserRole.admin
        ..effectiveTeacherId = adminDoc.data()!['teacherId'] as String;
      return UserRole.admin;
    }

    final studentDoc = await _db.collection('students').doc(uid).get();
    if (studentDoc.exists) {
      Session.instance
        ..role = UserRole.student
        ..effectiveTeacherId = null;
      return UserRole.student;
    }

    throw AuthException('الحساب غير مرتبط بأي دور، تواصل مع الدعم الفني');
  }

  Future<void> signOut() async {
    Session.instance.clear();
    await _auth.signOut();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'رقم الهاتف مسجل بالفعل، جرّب تسجيل الدخول';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، استخدم ٦ أحرف على الأقل';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'رقم الهاتف أو كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'رقم الهاتف غير صالح';
      default:
        return 'حدث خطأ: ${e.message ?? e.code}';
    }
  }
}
