import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  /// Pass groupId when showing notifications for a student.
  /// Leave null for teacher/admin (they get all their groups' notifications).
  final String? groupId;
  const NotificationsScreen({super.key, this.groupId});

  Stream<List<AppNotification>> _stream() {
    final isStudent = Session.instance.role == UserRole.student;
    if (isStudent && groupId != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      return FirestoreService.instance
          .watchStudentNotifications(uid, groupId!);
    }
    return FirestoreService.instance.watchTeacherNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات',
            style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.w800)),
        automaticallyImplyLeading:
            Session.instance.role == UserRole.student ? false : true,
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _stream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) return _emptyState();
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpace.lg),
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpace.sm),
            itemBuilder: (ctx, i) =>
                _NotifCard(notification: notifications[i]),
          );
        },
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  size: 56, color: AppColors.inkMuted),
              const SizedBox(height: AppSpace.md),
              Text('لا توجد إشعارات',
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('ستظهر هنا الإشعارات الجديدة',
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.inkMuted)),
            ],
          ),
        ),
      );
}

class _NotifCard extends StatelessWidget {
  final AppNotification notification;
  const _NotifCard({required this.notification});

  IconData get _icon => switch (notification.type) {
        NotificationType.homework => Icons.assignment_outlined,
        NotificationType.video => Icons.play_circle_outline_rounded,
        NotificationType.grade => Icons.grade_outlined,
        NotificationType.attendance => Icons.fact_check_outlined,
        NotificationType.subscription => Icons.payments_outlined,
        NotificationType.file => Icons.attach_file_rounded,
        NotificationType.exam => Icons.quiz_outlined,
        NotificationType.general => Icons.notifications_outlined,
      };

  Color get _color => switch (notification.type) {
        NotificationType.homework => AppColors.danger,
        NotificationType.video => AppColors.primary,
        NotificationType.grade => AppColors.warning,
        NotificationType.attendance => AppColors.success,
        NotificationType.subscription => const Color(0xFF7C3AED),
        NotificationType.file => AppColors.accent,
        NotificationType.exam => AppColors.warning,
        NotificationType.general => AppColors.inkMuted,
      };

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return GestureDetector(
      onTap: () async {
        if (unread) {
          await FirestoreService.instance
              .markNotificationRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: unread
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: unread
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notification.body,
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: AppColors.inkMuted)),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: GoogleFonts.cairo(
                        fontSize: 10.5, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
