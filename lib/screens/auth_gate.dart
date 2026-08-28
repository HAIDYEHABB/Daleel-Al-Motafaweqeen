import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';
import 'student_home_screen.dart';
import 'teacher_groups_hub_screen.dart';

/// Firebase Auth persists the signed-in user across app restarts, but
/// our in-memory Session (which teacher an admin is acting for) does
/// NOT. Without this gate, reopening the app after a restart could
/// silently drop an admin's Session.effectiveTeacherId, breaking their
/// data access. This widget resolves the role/session from Firestore
/// once at startup before deciding where to route.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<UserRole?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = AuthService.instance.resolveCurrentRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogoMark(size: 56),
                  const SizedBox(height: AppSpace.md),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
        final role = snapshot.data;
        if (role == null) return const LoginScreen();
        return role == UserRole.student
            ? const StudentHomeScreen()
            : const TeacherGroupsHubScreen();
      },
    );
  }
}
