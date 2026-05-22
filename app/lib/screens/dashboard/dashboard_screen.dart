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
import '../../data/pregnancy_data.dart';
import '../postpartum/postpartum_dashboard.dart';

// UserType bo'yicha to'g'ri dashboardni ko'rsatadi
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardRouterState();
}

class _DashboardRouterState extends State<DashboardScreen> {
  String _userType = 'pregnant';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _userType = p.getString(AppConstants.keyUserType) ?? 'pregnant';
      });
    });
  }

  void _toggle() {
    setState(() {
      _userType = _userType == 'pregnant' ? 'postpartum' : 'pregnant';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _userType == 'postpartum'
            ? const PostpartumDashboard()
            : const _PregnantDashboard(),

        // Demo switch — top right
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 68,
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: _userType == 'postpartum'
                    ? AppColors.boyGradient
                    : AppColors.headerGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  _userType == 'pregnant' ? '🤰' : '👶',
                  style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  _userType == 'pregnant' ? 'Postpartum' : 'Homilador',
                  style: GoogleFonts.nunito(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _PregnantDashboard extends StatefulWidget {
  const _PregnantDashboard();
  @override
  State<_PregnantDashboard> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<_PregnantDashboard> {
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
          _buildAppBar(),
          // _buildGreeting(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _PregnancyPageView(week: _week)
                .animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              _BabyVoiceCard(week: _week)
                .animate().fadeIn(delay: 80.ms, duration: 400.ms),
              const SizedBox(height: 16),
              _WeeklyJournal(history: _history)
                .animate().fadeIn(delay: 160.ms, duration: 400.ms),
              const SizedBox(height: 20),
              _SectionTitle('Maslahatlar'),
              const SizedBox(height: 12),
              _TipsSection(week: _week)
                .animate().fadeIn(delay: 200.ms, duration: 400.ms),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 54,
      title: Row(children: [
        Text('Onamiz 🌸', style: GoogleFonts.nunito(
          color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800,
        )),
        const Spacer(),
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight, shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_outlined,
              color: AppColors.primary, size: 18),
        ),
      ]),
      titleSpacing: 20,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildGreeting() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_greeting, style: GoogleFonts.nunito(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14, fontWeight: FontWeight.w500,
          )),
          const SizedBox(height: 4),
          Text(
            _name.isNotEmpty ? '$_name 👋' : 'Onamiz 🌸',
            style: GoogleFonts.nunito(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800,
            ),
          ),
        ]),
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

  // weekday: 1=Dushanba ... 7=Yakshanba
  static const _days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  Widget build(BuildContext context) {
    final today   = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    final days    = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
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
            final isToday = key == todayKey;
            final label   = _days[d.weekday - 1]; // 1-indexed, Mon=1
            return _JournalDot(
              dayLabel: label,
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
      bg = AppColors.riskColor(risk).withValues(alpha: 0.15);
      inner = Text(entry!['emoji'] as String,
          style: const TextStyle(fontSize: 16));
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

// ═══════════════════════════════════════════════════════════════
// PREGNANCY PAGE VIEW
// ═══════════════════════════════════════════════════════════════
class _PregnancyPageView extends StatefulWidget {
  final int week;
  const _PregnancyPageView({required this.week});
  @override
  State<_PregnancyPageView> createState() => _PregnancyPageViewState();
}

class _PregnancyPageViewState extends State<_PregnancyPageView> {
  late final PageController _ctrl;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    _schedule();
  }

  void _schedule() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_page + 1) % 3;
      _ctrl.animateToPage(next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
      _schedule();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.week;
    final daysLeft   = ((40 - w) * 7).clamp(0, 280);
    final monthsLeft = (daysLeft / 30).floor();
    final daysRem    = daysLeft % 30;
    final dueDate    = DateTime.now().add(Duration(days: daysLeft));
    final dueDateStr = '${dueDate.day}.${dueDate.month}.${dueDate.year}';
    final trimColor  = w <= 12 ? AppColors.t1Color
        : w <= 26 ? AppColors.t2Color : AppColors.t3Color;
    final trimLabel  = w <= 12 ? '1-trimester'
        : w <= 26 ? '2-trimester' : '3-trimester';

    return SizedBox(
      height: 148,
      child: Column(children: [
        Expanded(child: PageView(
          controller: _ctrl,
          onPageChanged: (p) => setState(() => _page = p),
          children: [
            // ── Karta 1: Hafta ──────────────────────────────
            _PCard(
              gradient: AppColors.headerGradient,
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Homiladorlik haftasi', style: GoogleFonts.nunito(
                      fontSize: 12, color: Colors.white70,
                      fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic, children: [
                      Text('$w', style: GoogleFonts.nunito(
                        fontSize: 50, fontWeight: FontWeight.w800,
                        color: Colors.white, height: 1)),
                      const SizedBox(width: 6),
                      Text('hafta', style: GoogleFonts.nunito(
                        fontSize: 15, color: Colors.white70,
                        fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(trimLabel, style: GoogleFonts.nunito(
                        fontSize: 11, color: Colors.white,
                        fontWeight: FontWeight.w700)),
                    ),
                  ],
                )),
                const Text('🤰', style: TextStyle(fontSize: 52)),
              ]),
            ),

            // ── Karta 2: Sanama ─────────────────────────────
            _PCard(
              gradient: LinearGradient(
                colors: [trimColor, trimColor.withValues(alpha: 0.65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Tug'ilishga", style: GoogleFonts.nunito(
                      fontSize: 12, color: Colors.white70,
                      fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic, children: [
                      Text('$daysLeft', style: GoogleFonts.nunito(
                        fontSize: 46, fontWeight: FontWeight.w800,
                        color: Colors.white, height: 1)),
                      const SizedBox(width: 6),
                      Text('kun', style: GoogleFonts.nunito(
                        fontSize: 15, color: Colors.white70,
                        fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 4),
                    Text('$monthsLeft oy $daysRem kun',
                      style: GoogleFonts.nunito(
                        fontSize: 12, color: Colors.white70)),
                  ],
                )),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📅', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 6),
                  Text(dueDateStr, style: GoogleFonts.nunito(
                    fontSize: 11, color: Colors.white,
                    fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),

            // ── Karta 3: Trimester yo'li ────────────────────
            _PCard(
              gradient: const LinearGradient(
                colors: [Color(0xFF9B78CC), Color(0xFFD86080)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Homiladorlik yo'li", style: GoogleFonts.nunito(
                    fontSize: 12, color: Colors.white70,
                    fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _TrimDot('T1', w > 12, w <= 12, AppColors.t1Color),
                    Expanded(child: Container(height: 3,
                        color: w > 12 ? Colors.white : Colors.white30)),
                    _TrimDot('T2', w > 26, w > 12 && w <= 26, AppColors.t2Color),
                    Expanded(child: Container(height: 3,
                        color: w > 26 ? Colors.white : Colors.white30)),
                    _TrimDot('T3', false, w > 26, AppColors.t3Color),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (w / 40).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white30,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('${((w / 40) * 100).toInt()}% tugallandi',
                    style: GoogleFonts.nunito(
                      fontSize: 11, color: Colors.white70,
                      fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        )),

        const SizedBox(height: 8),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _page == i ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _page == i ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(3)),
          )),
        ),
      ]),
    );
  }
}

class _PCard extends StatelessWidget {
  final LinearGradient gradient;
  final Widget child;
  const _PCard({required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.2),
        blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: child,
  );
}

class _TrimDot extends StatelessWidget {
  final String label;
  final bool done, active;
  final Color color;
  const _TrimDot(this.label, this.done, this.active, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(
      color: done || active ? Colors.white : Colors.white30,
      shape: BoxShape.circle),
    child: Center(child: done
      ? const Icon(Icons.check_rounded, size: 14, color: AppColors.primary)
      : Text(label, style: GoogleFonts.nunito(
          fontSize: 9, fontWeight: FontWeight.w800,
          color: active ? AppColors.primary : Colors.white70))),
  );
}

// ═══════════════════════════════════════════════════════════════
// BABY VOICE CARD
// ═══════════════════════════════════════════════════════════════
class _BabyVoiceCard extends StatelessWidget {
  final int week;
  const _BabyVoiceCard({required this.week});

  @override
  Widget build(BuildContext context) {
    final data = PregnancyData.forWeek(week);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryLight, width: 1.5),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.06),
          blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppColors.softPinkGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('👶', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text('$week-hafta bolangiz', style: GoogleFonts.nunito(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
            ]),
          ),
          const Spacer(),
          const Text('💬', style: TextStyle(fontSize: 18)),
        ]),
        const SizedBox(height: 14),
        Text(data.babyVoice, style: GoogleFonts.nunito(
          fontSize: 14, color: AppColors.textMedium,
          height: 1.65, fontWeight: FontWeight.w500)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.favorite_rounded,
                color: AppColors.primary, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text('Rivojlanyapti: ${data.developing}',
              style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.primary,
                fontWeight: FontWeight.w600))),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TIPS SECTION
// ═══════════════════════════════════════════════════════════════
class _TipsSection extends StatefulWidget {
  final int week;
  const _TipsSection({required this.week});
  @override
  State<_TipsSection> createState() => _TipsSectionState();
}

class _TipsSectionState extends State<_TipsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = PregnancyData.forWeek(widget.week);
    final tabs = [
      ('🤱', 'Onaga',       data.momTip),
      ('👨', 'Otaga',       data.dadTip),
      ('🥗', 'Ovqat',       data.nutrition),
      ('🧬', 'Rivojlanish', data.developing),
    ];

    return Container(
      decoration: AppDecoration.card,
      child: Column(children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24))),
          child: TabBar(
            controller: _tab,
            isScrollable: false,
            padding: const EdgeInsets.all(8),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(14)),
            labelStyle: GoogleFonts.nunito(
              fontSize: 11, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.nunito(
              fontSize: 11, fontWeight: FontWeight.w500),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textGrey,
            dividerColor: Colors.transparent,
            tabs: tabs.map((t) => Tab(
              height: 36,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(t.$1, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(t.$2),
              ]),
            )).toList(),
          ),
        ),
        SizedBox(
          height: 120,
          child: TabBarView(
            controller: _tab,
            children: tabs.map((t) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: SingleChildScrollView(
                child: Text(t.$3, style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textMedium,
                  height: 1.6, fontWeight: FontWeight.w500)),
              ),
            )).toList(),
          ),
        ),
      ]),
    );
  }
}
