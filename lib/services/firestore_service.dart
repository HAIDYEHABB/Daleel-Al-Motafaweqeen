import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import 'auth_service.dart';
import 'session.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  String get _effectiveTeacherId =>
      Session.instance.effectiveTeacherId ?? _uid;

  // ─── Groups ───────────────────────────────────────────────────────────────

  Stream<List<StudyGroup>> watchTeacherGroups() {
    return _db
        .collection('groups')
        .where('teacherId', isEqualTo: _effectiveTeacherId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => StudyGroup.fromDoc(d.id, d.data()))
            .toList());
  }

  Stream<List<StudyGroup>> watchAllGroups() {
    return _db
        .collection('groups')
        .snapshots()
        .map((s) => s.docs
            .map((d) => StudyGroup.fromDoc(d.id, d.data()))
            .toList());
  }

  Future<StudyGroup?> getGroup(String groupId) async {
    final doc = await _db.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return StudyGroup.fromDoc(doc.id, doc.data()!);
  }

  Future<void> createGroup({
    required String location,
    required String dayLabel,
    required String timeLabel,
  }) async {
    await _db.collection('groups').add({
      'teacherId': _effectiveTeacherId,
      'location': location,
      'dayLabel': dayLabel,
      'timeLabel': timeLabel,
      'studentCount': 0,
      'attendanceRate': 0.0,
      'averageRating': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGroup({
    required String groupId,
    required String location,
    required String dayLabel,
    required String timeLabel,
  }) async {
    await _db.collection('groups').doc(groupId).update({
      'location': location,
      'dayLabel': dayLabel,
      'timeLabel': timeLabel,
    });
  }

  /// Returns true if a group with same location+day+time already exists
  /// for this teacher — used to prevent duplicates.
  Future<bool> groupExists({
    required String location,
    required String dayLabel,
    required String timeLabel,
  }) async {
    final snap = await _db
        .collection('groups')
        .where('teacherId', isEqualTo: _effectiveTeacherId)
        .where('location', isEqualTo: location.trim())
        .where('dayLabel', isEqualTo: dayLabel.trim())
        .where('timeLabel', isEqualTo: timeLabel.trim())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ─── Profile photos ───────────────────────────────────────────────────────

  Future<void> updateStudentPhoto({
    required String studentId,
    required String photoUrl,
  }) async {
    await _db.collection('students').doc(studentId).update({
      'photoUrl': photoUrl,
    });
  }

  /// Updates the photo for the currently signed-in teacher or admin.
  Future<void> updateMyPhoto({required String photoUrl}) async {
    final role = Session.instance.role;
    if (role == UserRole.teacher) {
      await _db.collection('teachers').doc(_uid).update({'photoUrl': photoUrl});
    } else if (role == UserRole.admin) {
      await _db.collection('admins').doc(_uid).update({'photoUrl': photoUrl});
    }
  }

  /// Watches the current teacher/admin profile for photo + name changes.
  Stream<Map<String, dynamic>> watchMyProfile() {
    final role = Session.instance.role;
    final collection =
        role == UserRole.admin ? 'admins' : 'teachers';
    return _db
        .collection(collection)
        .doc(_uid)
        .snapshots()
        .map((s) => s.data() ?? {});
  }

  // ─── Real-time group stats ────────────────────────────────────────────────

  /// Live stream of GroupStats for the dashboard — replaces the one-shot
  /// Future so the teacher's dashboard updates whenever any student changes.
  Stream<GroupStats> watchGroupStats(String groupId) {
    return _db
        .collection('students')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return const GroupStats(
          totalStudents: 0,
          presentToday: 0,
          absentToday: 0,
          avgAttendanceRate: 0,
          avgWeeklyScore: 0,
          avgMonthlyScore: 0,
        );
      }
      int present = 0, absent = 0;
      double quizSum = 0, monthlySum = 0;
      String topName = '';
      double topScore = -1;

      for (final doc in snap.docs) {
        final data = doc.data();
        final att = data['attendance'] as String?;
        if (att == AttendanceStatus.present.name) present++;
        if (att == AttendanceStatus.absent.name) absent++;
        quizSum += (data['weeklyQuizScore'] as num?)?.toDouble() ?? 0;
        monthlySum += (data['monthlyExamScore'] as num?)?.toDouble() ?? 0;
        final overall = (data['overallRating'] as num?)?.toDouble() ?? 0;
        if (overall > topScore) {
          topScore = overall;
          topName = data['name'] as String? ?? '';
        }
      }
      final count = snap.docs.length;
      return GroupStats(
        totalStudents: count,
        presentToday: present,
        absentToday: absent,
        avgAttendanceRate: (present / count) * 100,
        avgWeeklyScore: quizSum / count,
        avgMonthlyScore: monthlySum / count,
        topStudentName: topName,
        topStudentScore: topScore < 0 ? 0 : topScore,
      );
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).delete();
  }

  // ─── Student Notes ────────────────────────────────────────────────────────

  Stream<List<StudentNote>> watchStudentNotes(String studentId) {
    return _db
        .collection('students')
        .doc(studentId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => StudentNote.fromDoc(d.id, d.data())).toList());
  }

  Future<void> addStudentNote({
    required String studentId,
    required String content,
  }) async {
    await _db
        .collection('students')
        .doc(studentId)
        .collection('notes')
        .add({
      'content': content,
      'authorId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteStudentNote(String studentId, String noteId) async {
    await _db
        .collection('students')
        .doc(studentId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  Future<void> updateGroupStats(String groupId) async {
    final students = await _db
        .collection('students')
        .where('groupId', isEqualTo: groupId)
        .get();

    if (students.docs.isEmpty) {
      await _db.collection('groups').doc(groupId).update({
        'studentCount': 0,
        'attendanceRate': 0.0,
        'averageRating': 0.0,
      });
      return;
    }

    final count = students.docs.length;
    int presentCount = 0;
    double scoreSum = 0;

    for (final doc in students.docs) {
      final data = doc.data();
      if ((data['attendance'] as String?) == AttendanceStatus.present.name) {
        presentCount++;
      }
      scoreSum += (data['overallRating'] as num?)?.toDouble() ?? 0;
    }

    await _db.collection('groups').doc(groupId).update({
      'studentCount': count,
      'attendanceRate': (presentCount / count) * 100,
      'averageRating': scoreSum / count,
    });
  }

  // ─── Students ────────────────────────────────────────────────────────────

  Stream<List<StudentRecord>> watchGroupStudents(String groupId) {
    return _db
        .collection('students')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => StudentRecord.fromDoc(d.id, d.data()))
            .toList());
  }

  Future<StudentRecord?> getStudent(String studentId) async {
    final doc = await _db.collection('students').doc(studentId).get();
    if (!doc.exists) return null;
    return StudentRecord.fromDoc(doc.id, doc.data()!);
  }

  Future<void> updateAttendance({
    required String studentId,
    required AttendanceStatus status,
    required String groupId,
  }) async {
    final batch = _db.batch();
    final studentRef = _db.collection('students').doc(studentId);

    batch.update(studentRef, {'attendance': status.name});

    // Record in history sub-collection
    final historyRef = studentRef.collection('attendanceHistory').doc();
    batch.set(historyRef, {
      'status': status.name,
      'date': FieldValue.serverTimestamp(),
      'sessionLabel': _todayLabel(),
    });

    await batch.commit();
    await updateGroupStats(groupId);

    // Notification to student
    await _addNotification(
      groupId: groupId,
      targetStudentId: studentId,
      type: NotificationType.attendance,
      title: 'تسجيل الحضور',
      body: status == AttendanceStatus.present
          ? 'تم تسجيل حضورك في حصة اليوم'
          : status == AttendanceStatus.late
              ? 'تم تسجيلك متأخراً في حصة اليوم'
              : 'تم تسجيل غيابك في حصة اليوم',
    );
  }

  Stream<List<AttendanceRecord>> watchStudentAttendanceHistory(
      String studentId) {
    return _db
        .collection('students')
        .doc(studentId)
        .collection('attendanceHistory')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AttendanceRecord.fromDoc(d.id, d.data()))
            .toList());
  }

  Future<void> updateWeeklyScore({
    required String studentId,
    required double score,
    required String groupId,
    String? weekLabel,
  }) async {
    final label = weekLabel ?? _thisWeekLabel();
    final batch = _db.batch();
    final studentRef = _db.collection('students').doc(studentId);

    batch.update(studentRef, {'weeklyQuizScore': score});

    final historyRef = studentRef.collection('weeklyScores').doc();
    batch.set(historyRef, {
      'score': score,
      'weekLabel': label,
      'recordedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await _recalcOverallRating(studentId);
    await updateGroupStats(groupId);

    await _addNotification(
      groupId: groupId,
      targetStudentId: studentId,
      type: NotificationType.grade,
      title: 'درجة جديدة',
      body: 'تم تسجيل درجة اختبار الحصة: ${score.toStringAsFixed(1)}/١٠',
    );
  }

  Stream<List<WeeklyScore>> watchStudentWeeklyScores(String studentId) {
    return _db
        .collection('students')
        .doc(studentId)
        .collection('weeklyScores')
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => WeeklyScore.fromDoc(d.id, d.data())).toList());
  }

  Future<void> updateRemainingSessions({
    required String studentId,
    required int remaining,
    required String groupId,
  }) async {
    await _db.collection('students').doc(studentId).update({
      'remainingPaidSessions': remaining,
    });

    await _addNotification(
      groupId: groupId,
      targetStudentId: studentId,
      type: NotificationType.subscription,
      title: 'تحديث الاشتراك',
      body: remaining > 0
          ? 'تم تحديث اشتراكك — متبقي $remaining حصة'
          : 'انتهت حصصك المدفوعة، تواصل مع المعلم لتجديد الاشتراك',
    );
  }

  Future<void> updatePaymentStatus({
    required String studentId,
    required PaymentStatus status,
    required String groupId,
  }) async {
    await _db.collection('students').doc(studentId).update({
      'paymentStatus': status.name,
    });

    await _addNotification(
      groupId: groupId,
      targetStudentId: studentId,
      type: NotificationType.subscription,
      title: 'حالة الدفع',
      body: status == PaymentStatus.paid
          ? 'تم تأكيد استلام دفعتك'
          : status == PaymentStatus.partial
              ? 'تم تسجيل دفعة جزئية'
              : 'لم يتم استلام الدفعة بعد',
    );
  }

  Future<void> _recalcOverallRating(String studentId) async {
    final student =
        await _db.collection('students').doc(studentId).get();
    if (!student.exists) return;
    final data = student.data()!;
    final quizScore =
        (data['weeklyQuizScore'] as num?)?.toDouble() ?? 0;
    final monthlyScore =
        (data['monthlyExamScore'] as num?)?.toDouble() ?? 0;
    final overall = (quizScore * 10 * 0.6) + (monthlyScore * 0.4);
    await _db
        .collection('students')
        .doc(studentId)
        .update({'overallRating': overall});
  }

  // ─── All Teachers (for admin registration dropdown) ───────────────────────

  Stream<List<TeacherProfile>> watchAllTeachers() {
    return _db.collection('teachers').snapshots().map((s) => s.docs
        .map((d) => TeacherProfile(
              id: d.id,
              name: d['name'] as String? ?? '',
              phone: d['phone'] as String? ?? '',
              photoUrl: d['photoUrl'] as String? ?? '',
            ))
        .toList());
  }

  // ─── Exams ────────────────────────────────────────────────────────────────

  Stream<List<Exam>> watchGroupExams(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('exams')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Exam.fromDoc(d.id, d.data())).toList());
  }

  Future<String> createExam({
    required String groupId,
    required String title,
    required double totalScore,
    required DateTime date,
  }) async {
    final ref =
        await _db.collection('groups').doc(groupId).collection('exams').add({
      'title': title,
      'totalScore': totalScore,
      'date': Timestamp.fromDate(date),
      'groupId': groupId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteExam(String groupId, String examId) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('exams')
        .doc(examId)
        .delete();
  }

  Future<void> saveExamResult({
    required String groupId,
    required String examId,
    required String studentId,
    required String studentName,
    required double score,
    required double totalScore,
  }) async {
    final examResultsRef = _db
        .collection('groups')
        .doc(groupId)
        .collection('exams')
        .doc(examId)
        .collection('results');

    // Upsert by studentId
    final existing = await examResultsRef
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await examResultsRef.doc(existing.docs.first.id).update({
        'score': score,
        'totalScore': totalScore,
      });
    } else {
      await examResultsRef.add({
        'studentId': studentId,
        'studentName': studentName,
        'examId': examId,
        'score': score,
        'totalScore': totalScore,
        'recordedAt': FieldValue.serverTimestamp(),
      });
    }

    // Update monthlyExamScore on student doc for ranking
    await _db.collection('students').doc(studentId).update({
      'monthlyExamScore': score,
    });
    await _recalcOverallRating(studentId);

    await _addNotification(
      groupId: groupId,
      targetStudentId: studentId,
      type: NotificationType.exam,
      title: 'نتيجة اختبار',
      body: 'تم تسجيل درجتك في الاختبار: ${score.toStringAsFixed(1)}/$totalScore',
    );
  }

  Stream<List<ExamResult>> watchExamResults(
      String groupId, String examId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('exams')
        .doc(examId)
        .collection('results')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ExamResult.fromDoc(d.id, d.data())).toList());
  }

  /// All exam results for a specific student (across all exams in the group)
  Future<List<ExamResult>> getStudentExamResults(
      String groupId, String studentId) async {
    final exams = await _db
        .collection('groups')
        .doc(groupId)
        .collection('exams')
        .get();

    final results = <ExamResult>[];
    for (final exam in exams.docs) {
      final r = await _db
          .collection('groups')
          .doc(groupId)
          .collection('exams')
          .doc(exam.id)
          .collection('results')
          .where('studentId', isEqualTo: studentId)
          .get();
      results.addAll(
          r.docs.map((d) => ExamResult.fromDoc(d.id, d.data())));
    }
    return results;
  }

  // ─── Rankings ────────────────────────────────────────────────────────────

  /// Within-group ranking by weekly quiz score
  Stream<List<RankingEntry>> watchGroupWeeklyRanking(
      String groupId, String groupTitle) {
    return _db
        .collection('students')
        .where('groupId', isEqualTo: groupId)
        .orderBy('weeklyQuizScore', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => RankingEntry(
                  studentId: d.id,
                  studentName: d['name'] as String? ?? '',
                  groupTitle: groupTitle,
                  score: (d['weeklyQuizScore'] as num?)?.toDouble() ?? 0,
                  totalScore: 10,
                ))
            .toList());
  }

  /// Within-group ranking by overall rating (cumulative)
  Stream<List<RankingEntry>> watchGroupOverallRanking(
      String groupId, String groupTitle) {
    return _db
        .collection('students')
        .where('groupId', isEqualTo: groupId)
        .orderBy('overallRating', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => RankingEntry(
                  studentId: d.id,
                  studentName: d['name'] as String? ?? '',
                  groupTitle: groupTitle,
                  score: (d['overallRating'] as num?)?.toDouble() ?? 0,
                  totalScore: 100,
                ))
            .toList());
  }

  /// Ranking by a specific exam within a group
  Stream<List<RankingEntry>> watchExamRanking(
      String groupId, String examId, String groupTitle) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('exams')
        .doc(examId)
        .collection('results')
        .orderBy('score', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => RankingEntry(
                  studentId: d['studentId'] as String? ?? '',
                  studentName: d['studentName'] as String? ?? '',
                  groupTitle: groupTitle,
                  score: (d['score'] as num?)?.toDouble() ?? 0,
                  totalScore:
                      (d['totalScore'] as num?)?.toDouble() ?? 100,
                ))
            .toList());
  }

  // ─── Content: Homework ────────────────────────────────────────────────────

  Future<void> addGroupHomework({
    required String groupId,
    required String title,
    required String url,
  }) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('homework')
        .add({
      'title': title,
      'url': url,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    await _addGroupNotification(
      groupId: groupId,
      type: NotificationType.homework,
      title: 'حل واجب جديد',
      body: 'تم رفع حل واجب جديد: $title',
    );
  }

  Stream<List<HomeworkFile>> watchGroupHomework(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('homework')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => HomeworkFile.fromDoc(d.id, d.data()))
            .toList());
  }

  Future<void> deleteHomework(String groupId, String homeworkId) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('homework')
        .doc(homeworkId)
        .delete();
  }

  // ─── Content: Videos ─────────────────────────────────────────────────────

  Future<void> addGroupVideo({
    required String groupId,
    required String title,
    required String url,
  }) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('videos')
        .add({
      'title': title,
      'url': url,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    await _addGroupNotification(
      groupId: groupId,
      type: NotificationType.video,
      title: 'شرح جديد',
      body: 'تم إضافة شرح جديد: $title',
    );
  }

  Stream<List<LessonVideo>> watchGroupVideos(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('videos')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => LessonVideo.fromDoc(d.id, d.data()))
            .toList());
  }

  Future<void> deleteVideo(String groupId, String videoId) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('videos')
        .doc(videoId)
        .delete();
  }

  // ─── Student Personal Files ───────────────────────────────────────────────

  Stream<List<StudentFile>> watchStudentFiles(String studentId) {
    return _db
        .collection('students')
        .doc(studentId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => StudentFile.fromDoc(d.id, d.data()))
            .toList());
  }

  Future<void> addStudentFile({
    required String studentId,
    required String title,
    required String url,
    required String groupId,
  }) async {
    await _db
        .collection('students')
        .doc(studentId)
        .collection('files')
        .add({
      'title': title,
      'url': url,
      'sentBy': _uid,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    await _addNotification(
      groupId: groupId,
      targetStudentId: studentId,
      type: NotificationType.file,
      title: 'ملف جديد',
      body: 'تم إرسال ملف خاص إليك: $title',
    );
  }

  Future<void> deleteStudentFile(
      String studentId, String fileId) async {
    await _db
        .collection('students')
        .doc(studentId)
        .collection('files')
        .doc(fileId)
        .delete();
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  /// Student-facing: their own notifications (group-wide + personal)
  Stream<List<AppNotification>> watchStudentNotifications(
      String studentId, String groupId) {
    return _db
        .collection('notifications')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) {
      return s.docs
          .map((d) => AppNotification.fromDoc(d.id, d.data()))
          .where((n) =>
              n.targetStudentId == null || n.targetStudentId == studentId)
          .toList();
    });
  }

  /// Teacher/admin: all notifications for their groups
  Stream<List<AppNotification>> watchTeacherNotifications() {
    return _db
        .collection('notifications')
        .where('teacherId', isEqualTo: _effectiveTeacherId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AppNotification.fromDoc(d.id, d.data()))
            .toList());
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> _addNotification({
    required String groupId,
    required String? targetStudentId,
    required NotificationType type,
    required String title,
    required String body,
  }) async {
    await _db.collection('notifications').add({
      'groupId': groupId,
      'targetStudentId': targetStudentId,
      'teacherId': _effectiveTeacherId,
      'type': type.name,
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _addGroupNotification({
    required String groupId,
    required NotificationType type,
    required String title,
    required String body,
  }) async {
    await _addNotification(
      groupId: groupId,
      targetStudentId: null,
      type: type,
      title: title,
      body: body,
    );
  }

  // ─── Dashboard / Analytics ────────────────────────────────────────────────

  Future<GroupStats> getGroupStats(String groupId) async {
    final students = await _db
        .collection('students')
        .where('groupId', isEqualTo: groupId)
        .get();

    if (students.docs.isEmpty) {
      return const GroupStats(
        totalStudents: 0,
        presentToday: 0,
        absentToday: 0,
        avgAttendanceRate: 0,
        avgWeeklyScore: 0,
        avgMonthlyScore: 0,
      );
    }

    int present = 0, absent = 0;
    double quizSum = 0, monthlySum = 0;
    String topName = '';
    double topScore = -1;

    for (final doc in students.docs) {
      final data = doc.data();
      final attendance = data['attendance'] as String?;
      if (attendance == AttendanceStatus.present.name) present++;
      if (attendance == AttendanceStatus.absent.name) absent++;
      quizSum += (data['weeklyQuizScore'] as num?)?.toDouble() ?? 0;
      monthlySum += (data['monthlyExamScore'] as num?)?.toDouble() ?? 0;
      final overall = (data['overallRating'] as num?)?.toDouble() ?? 0;
      if (overall > topScore) {
        topScore = overall;
        topName = data['name'] as String? ?? '';
      }
    }

    final count = students.docs.length;
    return GroupStats(
      totalStudents: count,
      presentToday: present,
      absentToday: absent,
      avgAttendanceRate: (present / count) * 100,
      avgWeeklyScore: quizSum / count,
      avgMonthlyScore: monthlySum / count,
      topStudentName: topName,
      topStudentScore: topScore < 0 ? 0 : topScore,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  String _thisWeekLabel() {
    final now = DateTime.now();
    final weekNum = (now.difference(DateTime(now.year, 1, 1)).inDays / 7)
        .floor() + 1;
    return 'الأسبوع $weekNum — ${now.year}';
  }
}
