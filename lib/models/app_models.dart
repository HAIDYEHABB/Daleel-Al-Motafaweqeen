import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum AttendanceStatus { present, absent, late }

enum PaymentStatus { paid, unpaid, partial }

enum NotificationType {
  homework,
  video,
  grade,
  attendance,
  subscription,
  file,
  exam,
  general,
}

// ─── StudyGroup ───────────────────────────────────────────────────────────────

class StudyGroup {
  final String id;
  final String location;
  final String dayLabel;
  final String timeLabel;
  final int studentCount;
  final double attendanceRate;
  final double averageRating;
  final String teacherId;

  const StudyGroup({
    required this.id,
    required this.location,
    required this.dayLabel,
    required this.timeLabel,
    this.studentCount = 0,
    this.attendanceRate = 0,
    this.averageRating = 0,
    this.teacherId = '',
  });

  String get title => 'مجموعة $location - $dayLabel $timeLabel';

  factory StudyGroup.fromDoc(String id, Map<String, dynamic> data) {
    return StudyGroup(
      id: id,
      location: data['location'] as String? ?? '',
      dayLabel: data['dayLabel'] as String? ?? '',
      timeLabel: data['timeLabel'] as String? ?? '',
      studentCount: (data['studentCount'] as num?)?.toInt() ?? 0,
      attendanceRate: (data['attendanceRate'] as num?)?.toDouble() ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      teacherId: data['teacherId'] as String? ?? '',
    );
  }
}

// ─── StudentRecord ────────────────────────────────────────────────────────────

class StudentRecord {
  final String id;
  final String name;
  final String phone;
  final String parentPhone;
  final String groupId;
  final String teacherId;
  final String photoUrl;
  AttendanceStatus attendance;
  double weeklyQuizScore;
  int remainingPaidSessions;
  double overallRating;
  double monthlyExamScore;
  PaymentStatus paymentStatus;
  final DateTime? createdAt;

  StudentRecord({
    required this.id,
    required this.name,
    this.phone = '',
    this.parentPhone = '',
    this.groupId = '',
    this.teacherId = '',
    this.photoUrl = '',
    this.attendance = AttendanceStatus.present,
    this.weeklyQuizScore = 0,
    this.remainingPaidSessions = 0,
    this.overallRating = 0,
    this.monthlyExamScore = 0,
    this.paymentStatus = PaymentStatus.unpaid,
    this.createdAt,
  });

  factory StudentRecord.fromDoc(String id, Map<String, dynamic> data) {
    return StudentRecord(
      id: id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      parentPhone: data['parentPhone'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      attendance: AttendanceStatus.values.firstWhere(
        (s) => s.name == (data['attendance'] as String?),
        orElse: () => AttendanceStatus.present,
      ),
      weeklyQuizScore: (data['weeklyQuizScore'] as num?)?.toDouble() ?? 0,
      remainingPaidSessions: (data['remainingPaidSessions'] as num?)?.toInt() ?? 0,
      overallRating: (data['overallRating'] as num?)?.toDouble() ?? 0,
      monthlyExamScore: (data['monthlyExamScore'] as num?)?.toDouble() ?? 0,
      paymentStatus: PaymentStatus.values.firstWhere(
        (s) => s.name == (data['paymentStatus'] as String?),
        orElse: () => PaymentStatus.unpaid,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Computed overall score: 60% quiz average + 40% monthly exam
  double get computedScore {
    return (weeklyQuizScore * 10 * 0.6) + (monthlyExamScore * 0.4);
  }
}

// ─── AttendanceRecord ─────────────────────────────────────────────────────────

class AttendanceRecord {
  final String id;
  final AttendanceStatus status;
  final DateTime date;
  final String sessionLabel;

  const AttendanceRecord({
    required this.id,
    required this.status,
    required this.date,
    this.sessionLabel = '',
  });

  factory AttendanceRecord.fromDoc(String id, Map<String, dynamic> data) {
    return AttendanceRecord(
      id: id,
      status: AttendanceStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String?),
        orElse: () => AttendanceStatus.present,
      ),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessionLabel: data['sessionLabel'] as String? ?? '',
    );
  }
}

// ─── Exam ─────────────────────────────────────────────────────────────────────

class Exam {
  final String id;
  final String title;
  final double totalScore;
  final DateTime date;
  final String groupId;

  const Exam({
    required this.id,
    required this.title,
    required this.totalScore,
    required this.date,
    required this.groupId,
  });

  factory Exam.fromDoc(String id, Map<String, dynamic> data) {
    return Exam(
      id: id,
      title: data['title'] as String? ?? '',
      totalScore: (data['totalScore'] as num?)?.toDouble() ?? 100,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      groupId: data['groupId'] as String? ?? '',
    );
  }
}

// ─── ExamResult ───────────────────────────────────────────────────────────────

class ExamResult {
  final String id;
  final String studentId;
  final String studentName;
  final String examId;
  final double score;
  final double totalScore;

  const ExamResult({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.examId,
    required this.score,
    required this.totalScore,
  });

  double get percentage => totalScore > 0 ? (score / totalScore) * 100 : 0;

  factory ExamResult.fromDoc(String id, Map<String, dynamic> data) {
    return ExamResult(
      id: id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      examId: data['examId'] as String? ?? '',
      score: (data['score'] as num?)?.toDouble() ?? 0,
      totalScore: (data['totalScore'] as num?)?.toDouble() ?? 100,
    );
  }
}

// ─── WeeklyScore ─────────────────────────────────────────────────────────────

class WeeklyScore {
  final String id;
  final double score;
  final String weekLabel;
  final DateTime recordedAt;

  const WeeklyScore({
    required this.id,
    required this.score,
    required this.weekLabel,
    required this.recordedAt,
  });

  factory WeeklyScore.fromDoc(String id, Map<String, dynamic> data) {
    return WeeklyScore(
      id: id,
      score: (data['score'] as num?)?.toDouble() ?? 0,
      weekLabel: data['weekLabel'] as String? ?? '',
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ─── LessonVideo ─────────────────────────────────────────────────────────────

class LessonVideo {
  final String id;
  final String title;
  final String url;
  final DateTime? uploadedAt;

  const LessonVideo({
    required this.title,
    required this.url,
    this.id = '',
    this.uploadedAt,
  });

  factory LessonVideo.fromDoc(String id, Map<String, dynamic> data) {
    return LessonVideo(
      id: id,
      title: data['title'] as String? ?? '',
      url: data['url'] as String? ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ─── HomeworkFile ─────────────────────────────────────────────────────────────

class HomeworkFile {
  final String id;
  final String title;
  final String url;
  final DateTime? uploadedAt;

  const HomeworkFile({
    required this.id,
    required this.title,
    required this.url,
    this.uploadedAt,
  });

  factory HomeworkFile.fromDoc(String id, Map<String, dynamic> data) {
    return HomeworkFile(
      id: id,
      title: data['title'] as String? ?? '',
      url: data['url'] as String? ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ─── StudentFile ──────────────────────────────────────────────────────────────

class StudentFile {
  final String id;
  final String title;
  final String url;
  final DateTime? uploadedAt;
  final String sentBy;

  const StudentFile({
    required this.id,
    required this.title,
    required this.url,
    this.uploadedAt,
    this.sentBy = '',
  });

  factory StudentFile.fromDoc(String id, Map<String, dynamic> data) {
    return StudentFile(
      id: id,
      title: data['title'] as String? ?? '',
      url: data['url'] as String? ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate(),
      sentBy: data['sentBy'] as String? ?? '',
    );
  }
}

// ─── AppNotification ──────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;
  final String? targetStudentId; // null = broadcast to whole group
  final String? groupId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.targetStudentId,
    this.groupId,
  });

  factory AppNotification.fromDoc(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == (data['type'] as String?),
        orElse: () => NotificationType.general,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      targetStudentId: data['targetStudentId'] as String?,
      groupId: data['groupId'] as String?,
    );
  }
}

// ─── RankingEntry ─────────────────────────────────────────────────────────────

class RankingEntry {
  final String studentId;
  final String studentName;
  final String groupTitle;
  final double score;
  final double totalScore;

  const RankingEntry({
    required this.studentId,
    required this.studentName,
    required this.groupTitle,
    required this.score,
    this.totalScore = 100,
  });

  double get percentage => totalScore > 0 ? (score / totalScore) * 100 : 0;
}

// ─── TeacherProfile ──────────────────────────────────────────────────────────

class TeacherProfile {
  final String id;
  final String name;
  final String phone;
  final String photoUrl;

  const TeacherProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl = '',
  });
}

// ─── StudentNote ──────────────────────────────────────────────────────────────

class StudentNote {
  final String id;
  final String content;
  final String authorId;
  final DateTime createdAt;

  const StudentNote({
    required this.id,
    required this.content,
    this.authorId = '',
    required this.createdAt,
  });

  factory StudentNote.fromDoc(String id, Map<String, dynamic> data) {
    return StudentNote(
      id: id,
      content: data['content'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ─── GroupStats ──────────────────────────────────────────────────────────────

class GroupStats {
  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final double avgAttendanceRate;
  final double avgWeeklyScore;
  final double avgMonthlyScore;
  final String topStudentName;
  final double topStudentScore;

  const GroupStats({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.avgAttendanceRate,
    required this.avgWeeklyScore,
    required this.avgMonthlyScore,
    this.topStudentName = '',
    this.topStudentScore = 0,
  });
}
