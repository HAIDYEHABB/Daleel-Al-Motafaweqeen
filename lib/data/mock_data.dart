import '../models/app_models.dart';

/// Static mock data — used only by DevMenuScreen for quick screen previews.
/// All production screens are wired to Firestore via FirestoreService.
class MockData {
  MockData._();

  static final List<StudyGroup> groups = [
    const StudyGroup(
      id: 'g1',
      location: 'المعادي',
      dayLabel: 'السبت',
      timeLabel: '٤:٠٠ م',
      studentCount: 25,
      attendanceRate: 90,
      averageRating: 88,
    ),
    const StudyGroup(
      id: 'g2',
      location: 'المقطم',
      dayLabel: 'الأحد',
      timeLabel: '٦:٠٠ م',
      studentCount: 18,
      attendanceRate: 84,
      averageRating: 91,
    ),
  ];
}
