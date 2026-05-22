import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  bool   _rural     = false;
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
      _rural     = p.getBool(AppConstants.keyRural) ?? false;
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
        anemiaLevel:       _anemiaLvl,
      );
      setState(() => _result = res);
      await _saveResult(res);
    } catch (e) {
      setState(() => _error = 'Server bilan aloqa yo\'q');
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              _TrimesterProgress(week: _week, trimester: _trimester)
                  .animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: 20),
              _WeekInfoCard(week: _week)
                  .animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 20),
              _DailyJournal(history: _history)
                  .animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 20),
              if (_error != null) _ErrorBanner(message: _error!),
              if (_result != null) ...[
                RiskCard(result: _result!)
                    .animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.97, 0.97)),
                const SizedBox(height: 20),
              ],
              _SectionTitle('Bugungi holatingiz'),
              const SizedBox(height: 12),
              QuickCheckForm(
                trimester: _trimester,
                loading:   _loading,
                onSubmit:  _onQuickCheck,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ])),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(_greeting,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    _name.isNotEmpty ? '$_name 👋' : 'Onamiz 🌸',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            const Text('Onamiz 🌸',
                style: TextStyle(color: AppColors.textDark,
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textDark),
              onPressed: () {},
            ),
          ]),
        ),
        titlePadding: const EdgeInsets.only(left: 20),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }
}

// ═══ Trimest Progress ════════════════════════════════════════
class _TrimesterProgress extends StatelessWidget {
  final int week;
  final String trimester;
  const _TrimesterProgress({required this.week, required this.trimester});

  @override
  Widget build(BuildContext context) {
    final t1Done = week > 12;
    final t2Done = week > 26;
    final currentT = switch (trimester) {
      'T1' => 0, 'T2' => 1, _ => 2
    };

    double progress;
    if (week <= 12)      progress = week / 12;
    else if (week <= 26) progress = (week - 12) / 14;
    else                 progress = (week - 26) / 14;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Homiladorlik bosqichlari',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$week-hafta', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 20),

        // 3 bosqich
        Row(children: [
          _TStep(label: '1-trimest', sub: '1–12h',
              color: AppColors.t1Color, done: t1Done, active: currentT == 0),
          _TLine(done: t1Done),
          _TStep(label: '2-trimest', sub: '13–26h',
              color: AppColors.t2Color, done: t2Done, active: currentT == 1),
          _TLine(done: t2Done),
          _TStep(label: '3-trimest', sub: '27–40h',
              color: AppColors.t3Color, done: false, active: currentT == 2),
        ]),

        const SizedBox(height: 16),

        // Progress bar
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${_trimesterLabel(trimester)} ichidagi progress',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            Text('${(progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ]),
      ]),
    );
  }

  String _trimesterLabel(String t) => switch (t) {
    'T1' => '1-trimest', 'T2' => '2-trimest', _ => '3-trimest'
  };
}

class _TStep extends StatelessWidget {
  final String label, sub;
  final Color color;
  final bool done, active;
  const _TStep({required this.label, required this.sub,
    required this.color, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: active ? color : done ? color.withValues(alpha: 0.15) : AppColors.divider,
          shape: BoxShape.circle,
          border: active ? Border.all(color: color, width: 3) : null,
          boxShadow: active ? [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))
          ] : [],
        ),
        child: Icon(
          done ? Icons.check_rounded : active ? Icons.radio_button_checked : Icons.circle_outlined,
          color: active ? Colors.white : done ? color : AppColors.textGrey,
          size: 20,
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: active ? color : AppColors.textGrey)),
      Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
    ]);
  }
}

class _TLine extends StatelessWidget {
  final bool done;
  const _TLine({required this.done});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 3, margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: done ? AppColors.primary : AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

// ═══ Hafta info kartasi ═══════════════════════════════════════
class _WeekInfoCard extends StatelessWidget {
  final int week;
  const _WeekInfoCard({required this.week});

  String get _babySize {
    if (week <= 4)  return '🫘 Loviya';
    if (week <= 8)  return '🍇 Uzum';
    if (week <= 12) return '🍋 Limon';
    if (week <= 16) return '🍊 Apelsin';
    if (week <= 20) return '🍌 Banan';
    if (week <= 24) return '🌽 Makkajo\'xori';
    if (week <= 28) return '🥦 Brokkoli';
    if (week <= 32) return '🥥 Kokos';
    if (week <= 36) return '🎃 Qovoq';
    return '🍉 Tarvuz';
  }

  int get _daysLeft => ((40 - week) * 7).clamp(0, 280);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Chaqalog\'ingiz hajmi',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(_babySize, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ])),
        Container(width: 1, height: 40, color: AppColors.divider),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text('$_daysLeft', style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const Text('kun qoldi', style: TextStyle(
              fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}

// ═══ Kundalik jurnal ══════════════════════════════════════════
class _DailyJournal extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _DailyJournal({required this.history});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final histMap = {for (var h in history) h['date'] as String: h};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Haftalik jurnal',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const Spacer(),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero, minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Barchasi', style: TextStyle(fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((d) {
            final key     = DateFormat('yyyy-MM-dd').format(d);
            final entry   = histMap[key];
            final isToday = DateFormat('yyyy-MM-dd').format(today) == key;
            final dayName = DateFormat('E', 'uz').format(d);

            return _DayDot(
              dayName: dayName.substring(0, 2).toUpperCase(),
              dayNum:  d.day,
              isToday: isToday,
              entry:   entry,
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String dayName;
  final int dayNum;
  final bool isToday;
  final Map<String, dynamic>? entry;

  const _DayDot({required this.dayName, required this.dayNum,
    required this.isToday, required this.entry});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Widget icon;

    if (entry != null) {
      final risk = entry!['risk'] as String;
      bg = AppColors.riskColor(risk).withValues(alpha: 0.15);
      icon = Text(entry!['emoji'] as String,
          style: const TextStyle(fontSize: 16));
    } else if (isToday) {
      bg = AppColors.primaryLight;
      icon = const Icon(Icons.add_rounded, color: AppColors.primary, size: 18);
    } else {
      bg = AppColors.divider;
      icon = Text('$dayNum',
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey,
              fontWeight: FontWeight.w500));
    }

    return Column(children: [
      Text(dayName, style: const TextStyle(
          fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Center(child: icon),
      ),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
        color: AppColors.textDark));
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.redLight,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, color: AppColors.red, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
          style: const TextStyle(color: AppColors.red, fontSize: 13))),
    ]),
  );
}
