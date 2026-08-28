import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class RankingScreen extends StatefulWidget {
  final StudyGroup group;
  const RankingScreen({super.key, required this.group});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
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
      appBar: AppBar(
        title: Text('الترتيب — ${widget.group.title}',
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
            child: Container(
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
                labelStyle: GoogleFonts.cairo(
                    fontSize: 11, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11),
                padding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'درجة الحصة'),
                  Tab(text: 'التراكمي'),
                  Tab(text: 'حسب اختبار'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RankingList(
                  stream: FirestoreService.instance
                      .watchGroupWeeklyRanking(
                          widget.group.id, widget.group.title),
                  scoreLabel: 'درجة الحصة',
                  totalLabel: '/١٠',
                ),
                _RankingList(
                  stream: FirestoreService.instance
                      .watchGroupOverallRanking(
                          widget.group.id, widget.group.title),
                  scoreLabel: 'التقييم التراكمي',
                  totalLabel: '/١٠٠',
                ),
                _ExamRankingTab(group: widget.group),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ranking List ──────────────────────────────────────────────────────────────

class _RankingList extends StatelessWidget {
  final Stream<List<RankingEntry>> stream;
  final String scoreLabel;
  final String totalLabel;
  const _RankingList({
    required this.stream,
    required this.scoreLabel,
    required this.totalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RankingEntry>>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return _emptyState('لا توجد بيانات للترتيب بعد');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpace.lg),
          itemCount: entries.length,
          itemBuilder: (ctx, i) =>
              _RankRow(entry: entries[i], rank: i + 1, total: totalLabel),
        );
      },
    );
  }
}

class _RankRow extends StatelessWidget {
  final RankingEntry entry;
  final int rank;
  final String total;
  const _RankRow(
      {required this.entry, required this.rank, required this.total});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return AppColors.inkMuted;
  }

  IconData get _rankIcon {
    if (rank <= 3) return Icons.emoji_events_rounded;
    return Icons.person_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final pct =
        entry.totalScore > 0 ? entry.score / entry.totalScore : 0.0;
    final barColor = pct >= 0.8
        ? AppColors.success
        : pct >= 0.5
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: rank <= 3 ? _rankColor.withValues(alpha: 0.4) : AppColors.border,
          width: rank <= 3 ? 1.5 : 1,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: _rankColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: rank <= 3
                ? Icon(_rankIcon, color: _rankColor, size: 18)
                : Center(
                    child: Text('$rank',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkMuted)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.studentName,
                    style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: AppColors.border,
                    color: barColor,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${entry.score.toStringAsFixed(1)}$total',
            style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: barColor),
          ),
        ],
      ),
    );
  }
}

// ── Exam Ranking Tab ─────────────────────────────────────────────────────────

class _ExamRankingTab extends StatefulWidget {
  final StudyGroup group;
  const _ExamRankingTab({required this.group});

  @override
  State<_ExamRankingTab> createState() => _ExamRankingTabState();
}

class _ExamRankingTabState extends State<_ExamRankingTab> {
  String? _selectedExamId;
  String? _selectedExamTitle;
  double _selectedTotal = 100;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Exam picker
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
          child: StreamBuilder<List<Exam>>(
            stream:
                FirestoreService.instance.watchGroupExams(widget.group.id),
            builder: (ctx, snap) {
              final exams = snap.data ?? [];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedExamId,
                    hint: Text('اختر الاختبار',
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: AppColors.inkMuted)),
                    items: exams
                        .map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.title,
                                  style: GoogleFonts.cairo(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      final exam = exams.firstWhere((e) => e.id == v);
                      setState(() {
                        _selectedExamId = v;
                        _selectedExamTitle = exam.title;
                        _selectedTotal = exam.totalScore;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        // Ranking list
        Expanded(
          child: _selectedExamId == null
              ? Center(
                  child: Text('اختر اختباراً لعرض الترتيب',
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: AppColors.inkMuted)),
                )
              : _RankingList(
                  stream: FirestoreService.instance.watchExamRanking(
                      widget.group.id,
                      _selectedExamId!,
                      widget.group.title),
                  scoreLabel: _selectedExamTitle ?? '',
                  totalLabel: '/${_selectedTotal.toInt()}',
                ),
        ),
      ],
    );
  }
}

Widget _emptyState(String msg) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.leaderboard_outlined,
                size: 48, color: AppColors.inkMuted),
            const SizedBox(height: AppSpace.md),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.inkMuted)),
          ],
        ),
      ),
    );
