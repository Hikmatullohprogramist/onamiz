import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/risk_result.dart';
import '../../services/api_service.dart';
import '../../widgets/risk_card.dart';
import '../../widgets/quick_check_form.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();

  String _name      = '';
  int    _week      = 18;
  int    _age       = 28;
  String _trimester = 'T2';
  int    _anemiaLvl = 0;
  bool   _loading   = false;
  RiskResult? _result;
  String? _error;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _name      = p.getString(AppConstants.keyUserName) ?? '';
      _week      = p.getInt(AppConstants.keyGestWeek) ?? 18;
      _age       = p.getInt(AppConstants.keyUserAge) ?? 28;
      _trimester = p.getString(AppConstants.keyTrimester) ?? 'T2';
      _anemiaLvl = p.getInt(AppConstants.keyAnemiaLevel) ?? 0;
      final raw  = p.getString(AppConstants.keyCheckHistory);
      if (raw != null) {
        _history = List<Map<String, dynamic>>.from(jsonDecode(raw));
      }
    });
  }

  Future<void> _saveResult(RiskResult r) async {
    final p = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _history.removeWhere((e) => e['date'] == today);
    _history.add({'date': today, 'risk': r.riskLevel, 'emoji': r.emoji});
    if (_history.length > 30) _history = _history.sublist(_history.length - 30);
    await p.setString(AppConstants.keyCheckHistory, jsonEncode(_history));
    setState(() {});
  }

  Future<void> _onQuickCheck(Map<String, int> symptoms) async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.predictQuick(
        trimester:         _trimester,
        age:               _age,
        gestationalWeek:   _week,
        vaginalBleeding:   symptoms['vaginal_bleeding']    ?? 0,
        headacheSeverity:  symptoms['headache_severity']   ?? 0,
        visualDisturbance: symptoms['visual_disturbance']  ?? 0,
        fetalMovement:     symptoms['fetal_movement']      ?? 0,
        itchingPalmsSoles: symptoms['itching_palms_soles'] ?? 0,
        anemiaLevel:       symptoms['anemia_level']        ?? _anemiaLvl,
      );
      setState(() => _result = res);
      await _saveResult(res);
    } catch (e) {
      setState(() => _error = "Server bilan aloqa yo'q");
    } finally {
      setState(() => _loading = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Xayrli tong';
    if (h < 17) return 'Xayrli kun';
    return 'Xayrli oqshom';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              _HeroCard(week: _week, trimester: _trimester)
                .animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: 16),
              _BabySizeCard(week: _week)
                .animate().fadeIn(delay: 80.ms, duration: 400.ms),
              const SizedBox(height: 16),
              _WeeklyJournal(history: _history)
                .animate().fadeIn(delay: 160.ms, duration: 400.ms),
              const SizedBox(height: 24),
              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                const SizedBox(height: 12),
              ],
              if (_result != null) ...[
                RiskCard(result: _result!)
                  .animate().fadeIn(duration: 350.ms).scale(
                    begin: const Offset(0.97, 0.97)),
                const SizedBox(height: 20),
              ],
              _SectionTitle('Bugungi holatingiz'),
              const SizedBox(height: 12),
              QuickCheckForm(
                trimester: _trimester,
                loading: _loading,
                onSubmit: _onQuickCheck,
              ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_greeting, style: GoogleFonts.nunito(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14, fontWeight: FontWeight.w500,
                  )),
                  const SizedBox(height: 8),
                  Text(
                    _name.isNotEmpty ? '$_name 👋' : 'Onamiz 🌸',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 26, fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(children: [
            Text('Onamiz 🌸', style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontSize: 17, fontWeight: FontWeight.w800,
            )),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppColors.primary, size: 18),
              ),
            ),
          ]),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }
}

// ═══ Hero card — week + trimester ════════════════════════════
class _HeroCard extends StatelessWidget {
  final int week;
  final String trimester;
  const _HeroCard({required this.week, required this.trimester});

  int get _daysLeft => ((40 - week) * 7).clamp(0, 280);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppDecoration.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Week number + days left
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Homiladorlik haftasi', style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                Text('$week', style: GoogleFonts.nunito(
                  fontSize: 52, fontWeight: FontWeight.w800,
                  color: AppColors.textDark, height: 1,
                )),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('hafta', style: GoogleFonts.nunito(
                    fontSize: 17, color: AppColors.textMedium,
                    fontWeight: FontWeight.w700,
                  )),
                ),
              ]),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.softPinkGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              Text('$_daysLeft', style: GoogleFonts.nunito(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: AppColors.primary, height: 1,
              )),
              Text('kun qoldi', style: GoogleFonts.nunito(
                fontSize: 11, color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              )),
            ]),
          ),
        ]),

        const SizedBox(height: 22),

        // Segmented trimester bar
        _TrimesterSegmentBar(week: week),
      ]),
    );
  }
}

class _TrimesterSegmentBar extends StatelessWidget {
  final int week;
  const _TrimesterSegmentBar({required this.week});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _TrimesterSegment(
        label: '1-trimester',
        weeks: '1–12 hafta',
        color: AppColors.t1Color,
        fill: (week / 12).clamp(0.0, 1.0),
        isActive: week <= 12,
        isDone: week > 12,
        isFirst: true,
        isLast: false,
      ),
      const SizedBox(width: 4),
      _TrimesterSegment(
        label: '2-trimester',
        weeks: '13–26 hafta',
        color: AppColors.t2Color,
        fill: week <= 12 ? 0 : ((week - 12) / 14).clamp(0.0, 1.0),
        isActive: week > 12 && week <= 26,
        isDone: week > 26,
        isFirst: false,
        isLast: false,
      ),
      const SizedBox(width: 4),
      _TrimesterSegment(
        label: '3-trimester',
        weeks: '27–40 hafta',
        color: AppColors.t3Color,
        fill: week <= 26 ? 0 : ((week - 26) / 14).clamp(0.0, 1.0),
        isActive: week > 26,
        isDone: false,
        isFirst: false,
        isLast: true,
      ),
    ]);
  }
}

class _TrimesterSegment extends StatelessWidget {
  final String label, weeks;
  final Color color;
  final double fill;
  final bool isActive, isDone, isFirst, isLast;

  const _TrimesterSegment({
    required this.label, required this.weeks, required this.color,
    required this.fill, required this.isActive, required this.isDone,
    required this.isFirst, required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.horizontal(
      left:  isFirst ? const Radius.circular(8) : Radius.zero,
      right: isLast  ? const Radius.circular(8) : Radius.zero,
    );
    return Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar segment
        Stack(children: [
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.divider, borderRadius: radius,
            ),
          ),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            widthFactor: fill,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: radius,
                boxShadow: isActive ? [
                  BoxShadow(color: color.withValues(alpha: 0.4),
                      blurRadius: 8, offset: const Offset(0, 2)),
                ] : [],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 7),
        Row(children: [
          if (isDone) ...[
            Icon(Icons.check_circle_rounded, color: color, size: 11),
            const SizedBox(width: 3),
          ],
          Flexible(child: Text(label, style: GoogleFonts.nunito(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: isActive || isDone ? color : AppColors.textGrey,
          ), overflow: TextOverflow.ellipsis)),
        ]),
        Text(weeks, style: GoogleFonts.nunito(
          fontSize: 9, color: AppColors.textGrey, fontWeight: FontWeight.w500,
        )),
      ],
    ));
  }
}

// ═══ Baby size card ═══════════════════════════════════════════
class _BabySizeCard extends StatelessWidget {
  final int week;
  const _BabySizeCard({required this.week});

  String get _babyEmoji {
    if (week <= 4)  return '🫘';
    if (week <= 8)  return '🍇';
    if (week <= 12) return '🍋';
    if (week <= 16) return '🍊';
    if (week <= 20) return '🍌';
    if (week <= 24) return '🌽';
    if (week <= 28) return '🥦';
    if (week <= 32) return '🥥';
    if (week <= 36) return '🎃';
    return '🍉';
  }

  String get _babyName {
    if (week <= 4)  return 'Loviya';
    if (week <= 8)  return 'Uzum';
    if (week <= 12) return 'Limon';
    if (week <= 16) return 'Apelsin';
    if (week <= 20) return 'Banan';
    if (week <= 24) return "Makkajo'xori";
    if (week <= 28) return 'Brokkoli';
    if (week <= 32) return 'Kokos';
    if (week <= 36) return 'Qovoq';
    return 'Tarvuz';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.softPinkGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 10, offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: Text(_babyEmoji,
              style: const TextStyle(fontSize: 32))),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Chaqalog'ingiz hajmi", style: GoogleFonts.nunito(
            fontSize: 12, color: AppColors.textGrey,
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 4),
          Text(_babyName, style: GoogleFonts.nunito(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          )),
          const SizedBox(height: 4),
          Text('$week-hafta bola', style: GoogleFonts.nunito(
            fontSize: 12, color: AppColors.textMedium,
            fontWeight: FontWeight.w500,
          )),
        ]),
      ]),
    );
  }
}

// ═══ Weekly journal ═══════════════════════════════════════════
class _WeeklyJournal extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _WeeklyJournal({required this.history});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final histMap = {for (var h in history) h['date'] as String: h};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecoration.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Haftalik jurnal', style: GoogleFonts.nunito(
            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark,
          )),
          const Spacer(),
          Text('7 kun', style: GoogleFonts.nunito(
            fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600,
          )),
        ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((d) {
            final key     = DateFormat('yyyy-MM-dd').format(d);
            final entry   = histMap[key];
            final isToday = DateFormat('yyyy-MM-dd').format(today) == key;
            final dayName = DateFormat('E', 'uz').format(d);
            return _JournalDot(
              dayLabel: dayName.substring(0, 2).toUpperCase(),
              dayNum: d.day,
              isToday: isToday,
              entry: entry,
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _JournalDot extends StatelessWidget {
  final String dayLabel;
  final int dayNum;
  final bool isToday;
  final Map<String, dynamic>? entry;

  const _JournalDot({
    required this.dayLabel, required this.dayNum,
    required this.isToday, required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Widget inner;

    if (entry != null) {
      final risk = entry!['risk'] as String;
      bg = AppColors.riskColor(risk).withValues(alpha: 0.12);
      inner = Text(entry!['emoji'] as String,
          style: const TextStyle(fontSize: 15));
    } else if (isToday) {
      bg = AppColors.primaryLight;
      inner = const Icon(Icons.add_rounded, color: AppColors.primary, size: 18);
    } else {
      bg = AppColors.divider;
      inner = Text('$dayNum', style: GoogleFonts.nunito(
        fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600,
      ));
    }

    return Column(children: [
      Text(dayLabel, style: GoogleFonts.nunito(
        fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w700,
      )),
      const SizedBox(height: 6),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Center(child: inner),
      ),
    ]);
  }
}

// ─── Misc ─────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.nunito(
      fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark,
    ));
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.redLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, color: AppColors.red, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: GoogleFonts.nunito(
        color: AppColors.red, fontSize: 13, fontWeight: FontWeight.w600,
      ))),
    ]),
  );
}
