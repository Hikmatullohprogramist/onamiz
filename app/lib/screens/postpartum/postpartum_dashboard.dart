import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/baby_monthly_data.dart';

class PostpartumDashboard extends StatefulWidget {
  const PostpartumDashboard({super.key});
  @override
  State<PostpartumDashboard> createState() => _PostpartumDashboardState();
}

class _PostpartumDashboardState extends State<PostpartumDashboard> {
  String _momName    = '';
  String _babyName   = '';
  String _babyGender = 'girl';
  int    _babyMonths = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _momName    = p.getString(AppConstants.keyUserName) ?? '';
      _babyName   = p.getString('baby_name') ?? '';
      _babyGender = p.getString(AppConstants.keyBabyGender) ?? 'girl';
      _babyMonths = p.getInt(AppConstants.keyBabyBirthMonth) ?? 0;
    });
  }

  // Boy blue, girl pink
  bool get _isBoy => _babyGender == 'boy';

  Color get _primary => _isBoy ? AppColors.boyPrimary : AppColors.primary;
  Color get _light   => _isBoy ? AppColors.boyLight   : AppColors.primaryLight;

  LinearGradient get _gradient => _isBoy
      ? AppColors.boyGradient
      : AppColors.headerGradient;

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
      body: CustomScrollView(slivers: [

        // ── App bar ───────────────────────────────────────────
        SliverAppBar(
          pinned: true, floating: false,
          backgroundColor: Colors.white,
          elevation: 0, surfaceTintColor: Colors.transparent,
          toolbarHeight: 54,
          title: Row(children: [
            Text(_isBoy ? 'Onamiz 💙' : 'Onamiz 🌸',
              style: GoogleFonts.nunito(
                color: AppColors.textDark, fontSize: 18,
                fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _light, shape: BoxShape.circle),
              child: Icon(Icons.notifications_outlined, color: _primary, size: 18),
            ),
          ]),
          titleSpacing: 20,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.divider)),
        ),

        // ── Greeting ──────────────────────────────────────────
        SliverToBoxAdapter(child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32))),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_greeting, style: GoogleFonts.nunito(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              _momName.isNotEmpty ? '$_momName 👋' : 'Onamiz 🌸',
              style: GoogleFonts.nunito(
                color: Colors.white, fontSize: 26,
                fontWeight: FontWeight.w800)),
          ]),
        )),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // ── Baby info card ─────────────────────────────
            _BabyInfoCard(
              babyName: _babyName,
              months: _babyMonths,
              isBoy: _isBoy,
              primary: _primary,
              light: _light,
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            // ── Cry translator ─────────────────────────────
            _CryTranslator(primary: _primary, light: _light)
                .animate().fadeIn(delay: 80.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Monthly development ────────────────────────
            _SectionTitle('Bola rivojlanishi'),
            const SizedBox(height: 12),
            _MonthlyDevelopment(
              months: _babyMonths,
              isBoy: _isBoy,
              primary: _primary,
              light: _light,
            ).animate().fadeIn(delay: 120.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Vaccination schedule ───────────────────────
            _SectionTitle('Emlash jadvali'),
            const SizedBox(height: 12),
            _VaccineSchedule(
              currentMonth: _babyMonths,
              primary: _primary,
            ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
          ])),
        ),
      ]),
    );
  }
}

// ─── Baby info card ───────────────────────────────────────────
class _BabyInfoCard extends StatelessWidget {
  final String babyName;
  final int months;
  final bool isBoy;
  final Color primary, light;

  const _BabyInfoCard({
    required this.babyName, required this.months,
    required this.isBoy, required this.primary, required this.light,
  });

  @override
  Widget build(BuildContext context) {
    final data = BabyData.forMonth(months);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isBoy ? AppColors.boyGradient : AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: primary.withValues(alpha: 0.2),
          blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        // Gender avatar
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.4), width: 2)),
          child: Center(child: Text(
            isBoy ? '👦' : '👧',
            style: const TextStyle(fontSize: 36))),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              babyName.isNotEmpty ? babyName : (isBoy ? 'Mening bolam' : 'Mening bolam'),
              style: GoogleFonts.nunito(
                color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$months oy', style: GoogleFonts.nunito(
              color: Colors.white70, fontSize: 14,
              fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              _InfoBadge(data.weight, Icons.monitor_weight_outlined),
              const SizedBox(width: 8),
              _InfoBadge(data.height, Icons.straighten_rounded),
            ]),
          ],
        )),
      ]),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  const _InfoBadge(this.text, this.icon);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 11),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.nunito(
        fontSize: 11, color: Colors.white,
        fontWeight: FontWeight.w600)),
    ]),
  );
}

// ─── Cry translator ───────────────────────────────────────────
class _CryTranslator extends StatefulWidget {
  final Color primary, light;
  const _CryTranslator({required this.primary, required this.light});
  @override
  State<_CryTranslator> createState() => _CryTranslatorState();
}

class _CryTranslatorState extends State<_CryTranslator>
    with SingleTickerProviderStateMixin {

  // States: idle → recording → analyzing → result
  String _state = 'idle'; // idle | recording | analyzing | result
  CryType? _result;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onMicTap() {
    if (_state == 'recording') return;

    setState(() { _state = 'recording'; _result = null; });

    // 3s record → analyze → mock result
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _state = 'analyzing');

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        // Mock API response — random cry type
        final mockResult = babyCryTypes[
            DateTime.now().millisecond % babyCryTypes.length];
        setState(() { _state = 'result'; _result = mockResult; });
      });
    });
  }

  void _reset() => setState(() { _state = 'idle'; _result = null; });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(children: [

        // Title row
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.light,
              borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('👂', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text("Yig'i tahlili", style: GoogleFonts.nunito(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: widget.primary)),
            ]),
          ),
          const Spacer(),
          if (_state == 'result')
            GestureDetector(
              onTap: _reset,
              child: Text('Qayta', style: GoogleFonts.nunito(
                fontSize: 13, color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline)),
            ),
        ]),

        const SizedBox(height: 20),

        // ── Big mic button ──────────────────────────────
        if (_state != 'result') ...[
          Center(child: GestureDetector(
            onTap: _state == 'idle' ? _onMicTap : null,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) {
                final scale = _state == 'recording' ? _pulseAnim.value : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Stack(alignment: Alignment.center, children: [
                // Outer pulse ring
                if (_state == 'recording')
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.primary.withValues(
                            alpha: 0.15 * (2 - _pulseAnim.value)),
                      ),
                    ),
                  ),
                // Main circle
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _state == 'recording'
                          ? [widget.primary, widget.primary.withValues(alpha: 0.7)]
                          : [widget.primary.withValues(alpha: 0.9), widget.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: widget.primary.withValues(alpha: 0.35),
                      blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: _state == 'analyzing'
                    ? const Center(child: SizedBox(
                        width: 28, height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white)))
                    : const Icon(Icons.mic_rounded,
                        color: Colors.white, size: 38),
                ),
              ]),
            ),
          )),

          const SizedBox(height: 16),

          // Status text
          Text(
            _state == 'idle'    ? 'Bosing va yig\'lasini kuting...'
            : _state == 'recording' ? '🔴  Yozib olinmoqda...'
            : 'Tahlil qilinmoqda...',
            style: GoogleFonts.nunito(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: _state == 'recording'
                  ? widget.primary : AppColors.textGrey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          if (_state == 'idle')
            Text(
              '3 soniya ovozni tahlil qilamiz',
              style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
        ],

        // ── Result ──────────────────────────────────────
        if (_state == 'result' && _result != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: widget.light,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: widget.primary.withValues(alpha: 0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Result badge
              Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: widget.primary.withValues(alpha: 0.2),
                      blurRadius: 10)]),
                  child: Center(child: Text(_result!.emoji,
                      style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Chaqalog'ingiz...", style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textGrey,
                    fontWeight: FontWeight.w500)),
                  Text(_result!.label, style: GoogleFonts.nunito(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: widget.primary)),
                ])),
              ]),
              const SizedBox(height: 12),
              Text(_result!.description, style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textGrey,
                fontStyle: FontStyle.italic, height: 1.4)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Icon(Icons.tips_and_updates_rounded,
                      color: widget.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_result!.advice,
                    style: GoogleFonts.nunito(
                      fontSize: 13, color: AppColors.textMedium,
                      height: 1.55, fontWeight: FontWeight.w500))),
                ]),
              ),
            ]),
          ).animate().fadeIn(duration: 350.ms).scale(
              begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 14),

          // Retry button
          GestureDetector(
            onTap: _reset,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(color: widget.primary, width: 1.5),
                borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text("Qayta tahlil qilish",
                style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: widget.primary))),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── Monthly development ──────────────────────────────────────
class _MonthlyDevelopment extends StatelessWidget {
  final int months;
  final bool isBoy;
  final Color primary, light;

  const _MonthlyDevelopment({
    required this.months, required this.isBoy,
    required this.primary, required this.light,
  });

  @override
  Widget build(BuildContext context) {
    final data = BabyData.forMonth(months);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecoration.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Baby voice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: light,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(isBoy ? '👦' : '👧',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text("$months-oy bolangiz aytmoqchi:",
                style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: primary)),
              const Spacer(),
              const Text('💬', style: TextStyle(fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            Text(data.babyVoice, style: GoogleFonts.nunito(
              fontSize: 13, color: AppColors.textMedium,
              height: 1.6, fontWeight: FontWeight.w500)),
          ]),
        ),

        const SizedBox(height: 16),

        Text("Bu oyda nima qila oladi?", style: GoogleFonts.nunito(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: AppColors.textDark)),
        const SizedBox(height: 10),

        ...data.milestones.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                  color: primary, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(m, style: GoogleFonts.nunito(
              fontSize: 13, color: AppColors.textMedium,
              height: 1.4, fontWeight: FontWeight.w500))),
          ]),
        )),

        const SizedBox(height: 12),
        Divider(color: AppColors.divider),
        const SizedBox(height: 8),

        // Weight & height
        Row(children: [
          _StatChip(
            label: 'O\'rtacha og\'irlik',
            value: data.weight,
            icon: '⚖️',
            color: primary),
          const SizedBox(width: 10),
          _StatChip(
            label: "O'rtacha bo'y",
            value: data.height,
            icon: '📏',
            color: primary),
        ]),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value, icon;
  final Color color;
  const _StatChip({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.nunito(
          fontSize: 10, color: AppColors.textGrey,
          fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 3),
      Text(value, style: GoogleFonts.nunito(
        fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    ]),
  ));
}

// ─── Vaccination schedule ─────────────────────────────────────
class _VaccineSchedule extends StatelessWidget {
  final int currentMonth;
  final Color primary;
  const _VaccineSchedule({
    required this.currentMonth, required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card,
      child: Column(children: vaccineSchedule.asMap().entries.map((entry) {
        final i    = entry.key;
        final v    = entry.value;
        final done = v.month < currentMonth;
        final now  = v.month == currentMonth ||
            (v.month < currentMonth && currentMonth < vaccineSchedule
                .where((x) => x.month > v.month).fold(99, (a, b) => b.month < a ? b.month : a));
        final isLast = i == vaccineSchedule.length - 1;

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: BoxDecoration(
            border: isLast ? null : Border(
              bottom: BorderSide(color: AppColors.divider))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Status icon
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: done ? AppColors.greenLight
                    : now ? primary.withValues(alpha: 0.12)
                    : AppColors.divider,
                shape: BoxShape.circle),
              child: Center(child: done
                ? const Icon(Icons.check_rounded,
                    color: AppColors.green, size: 18)
                : now
                  ? Icon(Icons.access_time_rounded,
                      color: primary, size: 18)
                  : const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textGrey, size: 16)),
            ),

            const SizedBox(width: 12),

            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('${v.month} oy', style: GoogleFonts.nunito(
                    fontSize: 11, color: done ? AppColors.green
                        : now ? primary : AppColors.textGrey,
                    fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  if (now) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text('Hozir', style: GoogleFonts.nunito(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: primary)),
                  ),
                  if (done) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(6)),
                    child: Text('Bajarildi', style: GoogleFonts.nunito(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.green)),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(v.name, style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: done ? AppColors.textGrey : AppColors.textDark)),
                const SizedBox(height: 2),
                Text(v.description, style: GoogleFonts.nunito(
                  fontSize: 12, color: AppColors.textGrey)),
              ],
            )),
          ]),
        );
      }).toList()),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.nunito(
      fontSize: 17, fontWeight: FontWeight.w800,
      color: AppColors.textDark));
}
