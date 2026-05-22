import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../widgets/quick_check_form.dart';
import '../../services/api_service.dart';
import '../../models/risk_result.dart';
import '../../widgets/risk_card.dart';

// ─── Event model ──────────────────────────────────────────────
class CalendarEvent {
  final String date;   // yyyy-MM-dd
  final String type;   // 'doctor' | 'check' | 'note' | 'medicine'
  final String title;
  final String? note;

  const CalendarEvent({
    required this.date, required this.type,
    required this.title, this.note,
  });

  Map<String, dynamic> toJson() =>
      {'date': date, 'type': type, 'title': title, 'note': note};

  factory CalendarEvent.fromJson(Map<String, dynamic> j) => CalendarEvent(
    date: j['date'], type: j['type'],
    title: j['title'], note: j['note'],
  );

  static const _icons = {
    'doctor':   '🏥',
    'check':    '❤️',
    'note':     '📝',
    'medicine': '💊',
  };

  String get emoji => _icons[type] ?? '📅';

  Color color(BuildContext context) => switch (type) {
    'doctor'   => AppColors.secondary,
    'check'    => AppColors.primary,
    'medicine' => AppColors.yellow,
    _          => AppColors.green,
  };
}

// ─── Screen ───────────────────────────────────────────────────
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay  = DateTime.now();
  List<CalendarEvent> _events = [];

  // Quick check state
  final _api        = ApiService();
  String _trimester = 'T2';
  int    _age       = 28;
  int    _week      = 18;
  int    _anemiaLvl = 0;
  bool   _checking  = false;
  RiskResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(AppConstants.keyCalendarEvents);
    setState(() {
      _trimester = p.getString(AppConstants.keyTrimester) ?? 'T2';
      _age       = p.getInt(AppConstants.keyUserAge) ?? 28;
      _week      = p.getInt(AppConstants.keyGestWeek) ?? 18;
      _anemiaLvl = p.getInt(AppConstants.keyAnemiaLevel) ?? 0;
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _events = list.map((e) => CalendarEvent.fromJson(e)).toList();
      }
    });
  }

  Future<void> _saveEvents() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.keyCalendarEvents,
        jsonEncode(_events.map((e) => e.toJson()).toList()));
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  List<CalendarEvent> _eventsForDay(DateTime d) =>
      _events.where((e) => e.date == _fmt(d)).toList();

  Future<void> _addEvent(DateTime day) async {
    String? selectedType;
    final titleCtrl = TextEditingController();
    final noteCtrl  = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Voqea qo'shish", style: GoogleFonts.nunito(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            )),
            const SizedBox(height: 20),

            // Type selection
            Wrap(spacing: 8, runSpacing: 8, children: [
              _typeChip(ctx, setModal, '🏥', 'doctor', "Shifokor", selectedType, (t) => selectedType = t),
              _typeChip(ctx, setModal, '❤️', 'check', "Tekshiruv", selectedType, (t) => selectedType = t),
              _typeChip(ctx, setModal, '💊', 'medicine', "Dori", selectedType, (t) => selectedType = t),
              _typeChip(ctx, setModal, '📝', 'note', "Eslatma", selectedType, (t) => selectedType = t),
            ]),
            const SizedBox(height: 16),

            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'Sarlavha (masalan: OB-GYN tekshiruvi)',
                hintStyle: GoogleFonts.nunito(color: AppColors.textGrey),
              ),
              style: GoogleFonts.nunito(color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText: "Izoh (ixtiyoriy)",
                hintStyle: GoogleFonts.nunito(color: AppColors.textGrey),
              ),
              style: GoogleFonts.nunito(color: AppColors.textDark),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                if (selectedType == null || titleCtrl.text.isEmpty) return;
                final ev = CalendarEvent(
                  date: _fmt(day), type: selectedType!,
                  title: titleCtrl.text.trim(),
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                );
                setState(() => _events.add(ev));
                _saveEvents();
                Navigator.pop(ctx);
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text("Saqlash",
                  style: GoogleFonts.nunito(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700,
                  ))),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _typeChip(BuildContext ctx, StateSetter setModal, String emoji,
      String type, String label, String? selected, Function(String) onTap) {
    final active = selected == type;
    return GestureDetector(
      onTap: () => setModal(() => onTap(type)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? AppColors.headerGradient : null,
          color: active ? null : AppColors.background,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: active ? Colors.transparent : AppColors.border, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.nunito(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textMedium,
          )),
        ]),
      ),
    );
  }

  Future<void> _runQuickCheck(Map<String, int> symptoms) async {
    setState(() { _checking = true; _result = null; });
    try {
      final res = await _api.predictQuick(
        trimester: _trimester, age: _age, gestationalWeek: _week,
        vaginalBleeding:   symptoms['vaginal_bleeding']    ?? 0,
        headacheSeverity:  symptoms['headache_severity']   ?? 0,
        visualDisturbance: symptoms['visual_disturbance']  ?? 0,
        fetalMovement:     symptoms['fetal_movement']      ?? 0,
        itchingPalmsSoles: symptoms['itching_palms_soles'] ?? 0,
        anemiaLevel:       symptoms['anemia_level']        ?? _anemiaLvl,
      );
      setState(() => _result = res);
      // Save to check history
      final p = await SharedPreferences.getInstance();
      final today = _fmt(DateTime.now());
      final raw = p.getString(AppConstants.keyCheckHistory);
      final hist = raw != null
          ? List<Map<String, dynamic>>.from(jsonDecode(raw)) : <Map<String, dynamic>>[];
      hist.removeWhere((e) => e['date'] == today);
      hist.add({'date': today, 'risk': res.riskLevel, 'emoji': res.emoji});
      if (hist.length > 30) hist.removeRange(0, hist.length - 30);
      await p.setString(AppConstants.keyCheckHistory, jsonEncode(hist));
    } catch (_) {
      // ignore network error
    } finally {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _eventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [

        // App bar
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 54,
          title: Row(children: [
            Text('Kalendar', style: GoogleFonts.nunito(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark,
            )),
            const Spacer(),
            // Month nav
            GestureDetector(
              onTap: () => setState(() =>
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
              child: const Icon(Icons.chevron_left_rounded,
                  color: AppColors.textMedium, size: 28),
            ),
            Text(DateFormat('MMM yyyy', 'uz').format(_focusedMonth),
              style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark,
              )),
            GestureDetector(
              onTap: () => setState(() =>
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
              child: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMedium, size: 28),
            ),
          ]),
          titleSpacing: 20,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.divider),
          ),
        ),

        SliverToBoxAdapter(child: _buildCalendar()),

        // Selected day events
        if (selectedEvents.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _EventTile(event: selectedEvents[i])
                    .animate().fadeIn(delay: (i * 50).ms, duration: 250.ms),
                childCount: selectedEvents.length,
              ),
            ),
          ),

        // Quick check section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([
            Row(children: [
              Text('Bugungi tekshiruv', style: GoogleFonts.nunito(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark,
              )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(DateFormat('d-MMM').format(DateTime.now()),
                  style: GoogleFonts.nunito(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary,
                  )),
              ),
            ]),
            const SizedBox(height: 12),
            if (_result != null) ...[
              RiskCard(result: _result!)
                  .animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
            ],
            QuickCheckForm(
              trimester: _trimester,
              loading: _checking,
              onSubmit: _runQuickCheck,
            ),
          ])),
        ),
      ]),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEvent(_selectedDay),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun, 1=Mon...
    final todayStr = _fmt(DateTime.now());
    const dayNames = ['Ya', 'Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: AppDecoration.card,
      child: Column(children: [
        // Day headers
        Row(children: dayNames.map((d) => Expanded(
          child: Center(child: Text(d, style: GoogleFonts.nunito(
            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey,
          ))),
        )).toList()),
        const SizedBox(height: 8),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startWeekday) return const SizedBox();
            final day = i - startWeekday + 1;
            final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
            final dateStr = _fmt(date);
            final events = _eventsForDay(date);
            final isToday = dateStr == todayStr;
            final isSelected = dateStr == _fmt(_selectedDay);

            return GestureDetector(
              onTap: () => setState(() => _selectedDay = date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.headerGradient : null,
                  color: isToday && !isSelected ? AppColors.primaryLight : null,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day', style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: isToday || isSelected
                          ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? Colors.white
                          : isToday ? AppColors.primary
                          : AppColors.textDark,
                    )),
                    if (events.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.take(3).map((e) => Container(
                          width: 5, height: 5,
                          margin: const EdgeInsets.only(top: 2, left: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : e.color(context),
                            shape: BoxShape.circle,
                          ),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ]),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = event.color(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(event.emoji,
              style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: GoogleFonts.nunito(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark,
            )),
            if (event.note != null)
              Text(event.note!, style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textMedium,
              )),
          ],
        )),
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ]),
    );
  }
}
