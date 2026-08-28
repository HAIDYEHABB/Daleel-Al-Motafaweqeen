import 'auth_service.dart';

/// Holds "who is effectively acting as which teacher" for the current
/// app session. A teacher's effectiveTeacherId is their own uid. An
/// admin's effectiveTeacherId is the uid of the teacher they assist —
/// admins have full teacher permissions but operate on THAT teacher's
/// groups/students, never their own separate data set.
///
/// In-memory only (reset on app restart) — AuthGate in main.dart
/// repopulates it from Firestore when a session is restored.
class Session {
  Session._();
  static final Session instance = Session._();

  UserRole? role;
  String? effectiveTeacherId;

  void clear() {
    role = null;
    effectiveTeacherId = null;
  }
}
