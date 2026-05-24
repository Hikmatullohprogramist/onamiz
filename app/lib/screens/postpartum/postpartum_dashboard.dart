import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/baby_monthly_data.dart';
import '../../services/cry_analyzer.dart';

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

            // ── Cry translator (asosiy fokus) ──────────────
            _CryTranslator(primary: _primary, light: _light)
                .animate().fadeIn(duration: 400.ms),

            // Bola info, oylik rivojlanish va emlash jadvali
            // keyinroq qo'shiladi.
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
    ])
    ,
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

  // States: idle → recording → analyzing → cry_detected | no_cry | error
  String _state = 'idle';
  String? _errorMessage;
  CryDetectionResult? _result;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final _analyzer = CryAnalyzer();

  static const _recordSeconds = 4;

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

  Future<void> _onMicTap() async {
    if (_state != 'idle') return;

    setState(() {
      _state = 'recording';
      _errorMessage = null;
    });

    try {
      await _analyzer.startRecording();
    } on MicrophonePermissionDenied {
      if (!mounted) return;
      setState(() {
        _state = 'error';
        _errorMessage = "Mikrofonga ruxsat berilmadi.\n"
            "Sozlamalardan ruxsat bering.";
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = 'error';
        _errorMessage = "Yozish boshlanmadi.\nIltimos qayta urinib ko'ring.";
      });
      return;
    }

    await Future.delayed(const Duration(seconds: _recordSeconds));
    if (!mounted) {
      await _analyzer.cancelRecording();
      return;
    }

    String? path;
    try {
      path = await _analyzer.stopRecording();
    } catch (_) {
      path = null;
    }

    if (!mounted) return;
    if (path == null) {
      setState(() {
        _state = 'error';
        _errorMessage = "Audio yozilmadi.\nIltimos qayta urinib ko'ring.";
      });
      return;
    }

    setState(() => _state = 'analyzing');

    try {
      final res = await _analyzer.analyze(path);
      if (!mounted) return;
      setState(() {
        _result = res;
        _state = res.isCry ? 'cry_detected' : 'no_cry';
      });
    } on CryAnalysisUnavailable catch (e) {
      if (!mounted) return;
      setState(() {
        _state = 'error';
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = 'error';
        _errorMessage = "Tahlil bajarilmadi.\nIltimos qayta urinib ko'ring.";
      });
    }
  }

  void _reset() => setState(() {
    _state = 'idle';
    _errorMessage = null;
    _result = null;
  });

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
          if (_state != 'idle' && _state != 'recording' && _state != 'analyzing')
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
        if (_state == 'idle' || _state == 'recording' || _state == 'analyzing') ...[
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
              '$_recordSeconds soniya ovozni tahlil qilamiz',
              style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
        ],

        // ── Cry detected — show 5 educational reasons ───
        if (_state == 'cry_detected' && _result != null) ...[
          _CryDetectedHeader(
            confidence: _result!.confidencePct,
            primary: widget.primary,
            light: widget.light,
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 16),

          Row(children: [
            Text(
              _result!.predictions != null
                  ? "Taxminiy ehtimollik:"
                  : "Eng keng tarqalgan sabablar:",
              style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textMedium,
              ),
            ),
            const Spacer(),
            if (_result!.predictions != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.yellow.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('⚠️', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text("TAXMINIY", style: GoogleFonts.nunito(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: AppColors.yellow,
                  )),
                ]),
              ),
          ]),
          const SizedBox(height: 10),

          ..._result!.sortedReasons.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CryReasonCard(
              reason: e.value.reason,
              probability: _result!.predictions != null
                  ? e.value.prob : null,
              isTop: e.key == 0 && _result!.predictions != null,
              primary: widget.primary,
              light: widget.light,
            ).animate().fadeIn(
              delay: (60 * (e.key + 1)).ms,
              duration: 300.ms,
            ).slideX(begin: 0.04, end: 0),
          )),

          if (_result!.predictionsNote != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.yellow.withValues(alpha: 0.3)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('⚠️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _result!.predictionsNote!,
                  style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textMedium,
                    height: 1.5, fontWeight: FontWeight.w600,
                  ),
                )),
              ]),
            ),
            const SizedBox(height: 8),
          ],

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ℹ️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                "Bu maslahat tashxis emas. Bola uzoq vaqt yig'lasa "
                "yoki ahvoli yomonlasa, shifokorga murojaat qiling.",
                style: GoogleFonts.nunito(
                  fontSize: 11, color: AppColors.textGrey,
                  height: 1.5, fontStyle: FontStyle.italic,
                ),
              )),
            ]),
          ),
        ],

        // ── No cry detected ─────────────────────────────
        if (_state == 'no_cry') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.light,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.primary.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: widget.primary.withValues(alpha: 0.15),
                    blurRadius: 12)],
                ),
                child: const Center(
                  child: Text('🤫', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(height: 12),
              Text("Yig'i aniqlanmadi", style: GoogleFonts.nunito(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: widget.primary,
              )),
              const SizedBox(height: 6),
              Text(
                "Ovoz juda jim yoki boshqa shovqin bo'lishi mumkin.\n"
                "Mikrofonni chaqaloqqa yaqinroq tutib, qayta urinib ko'ring.",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textMedium,
                  height: 1.5, fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 14),

          GestureDetector(
            onTap: _reset,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primary,
                           widget.primary.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text("Qayta urinib ko'rish",
                style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Colors.white))),
            ),
          ),
        ],

        // ── Error ───────────────────────────────────────
        if (_state == 'error') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.redLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.red.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('⚠️', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(height: 12),
              Text('Xatolik', style: GoogleFonts.nunito(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: AppColors.red,
              )),
              const SizedBox(height: 6),
              Text(
                _errorMessage ?? 'Tahlil bajarilmadi',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textMedium,
                  height: 1.5, fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 14),

          GestureDetector(
            onTap: _reset,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(color: widget.primary, width: 1.5),
                borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text("Qayta urinib ko'rish",
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

// ─── Cry detection header ─────────────────────────────────────
class _CryDetectedHeader extends StatelessWidget {
  final int confidence;
  final Color primary, light;
  const _CryDetectedHeader({
    required this.confidence,
    required this.primary,
    required this.light,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.12),
                   primary.withValues(alpha: 0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: primary.withValues(alpha: 0.2),
              blurRadius: 10)]),
          child: const Center(child: Text('👶',
              style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Yig'i aniqlandi", style: GoogleFonts.nunito(
              fontSize: 17, fontWeight: FontWeight.w800,
              color: primary)),
            const SizedBox(height: 2),
            Text("Ishonch darajasi: $confidence%",
              style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textMedium,
                fontWeight: FontWeight.w500)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: primary, borderRadius: BorderRadius.circular(20)),
          child: Text('$confidence%',
            style: GoogleFonts.nunito(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: Colors.white)),
        ),
      ]),
    );
  }
}

// ─── Single cry reason card with optional probability ─────────
class _CryReasonCard extends StatefulWidget {
  final CryReason reason;
  final double? probability; // null = foiz ko'rsatilmaydi
  final bool isTop;          // eng yuqori probability uchun ajratish
  final Color primary, light;
  const _CryReasonCard({
    required this.reason,
    required this.probability,
    required this.isTop,
    required this.primary,
    required this.light,
  });

  @override
  State<_CryReasonCard> createState() => _CryReasonCardState();
}

class _CryReasonCardState extends State<_CryReasonCard> {
  late bool _expanded = widget.isTop; // eng yuqori — boshidan ochiq

  @override
  Widget build(BuildContext context) {
    final pct = widget.probability != null
        ? (widget.probability! * 100).round()
        : null;
    final showBar = widget.probability != null;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _expanded || widget.isTop ? widget.light : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isTop
                ? widget.primary
                : (_expanded
                    ? widget.primary.withValues(alpha: 0.4)
                    : AppColors.border),
            width: widget.isTop ? 2 : 1.5,
          ),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(widget.reason.emoji,
                  style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(widget.reason.label,
                    style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: AppColors.textDark))),
                  if (widget.isTop) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.primary,
                        borderRadius: BorderRadius.circular(6)),
                      child: Text("EHTIMOL",
                        style: GoogleFonts.nunito(
                          fontSize: 9, fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(widget.reason.description,
                  style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textGrey,
                    height: 1.4, fontWeight: FontWeight.w500),
                  maxLines: _expanded ? null : 1,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis),
              ],
            )),
            const SizedBox(width: 8),
            if (pct != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isTop
                      ? widget.primary
                      : widget.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$pct%', style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: widget.isTop ? Colors.white : widget.primary)),
              )
            else
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: _expanded ? 0.5 : 0,
                child: Icon(Icons.expand_more_rounded,
                  color: AppColors.textGrey, size: 22),
              ),
          ]),
          if (showBar) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: widget.probability!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation(
                  widget.isTop
                      ? widget.primary
                      : widget.primary.withValues(alpha: 0.5)),
              ),
            ),
          ],
          if (_expanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Icon(Icons.tips_and_updates_rounded,
                    color: widget.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.reason.advice,
                  style: GoogleFonts.nunito(
                    fontSize: 12, color: AppColors.textMedium,
                    height: 1.5, fontWeight: FontWeight.w500))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
