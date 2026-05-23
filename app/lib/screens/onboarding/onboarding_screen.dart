import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _finishing = false;

  UserType? _userType;

  final _nameCtrl  = TextEditingController();
  int _age         = 25;
  int _gestWeek    = 12;
  int _babyMonths  = 1;   // postpartum uchun
  Trimester _trimester = Trimester.T1;

  int _parity           = 0;
  int _anemiaLevel      = 0;
  bool _bpHistory       = false;
  bool _diabetesHistory = false;
  bool _thyroidHistory  = false;

  bool _rural        = false;
  bool _notifEnabled = true;
  int  _notifHour    = 9;

  int get _totalSteps => _userType == UserType.pregnant ? 4 : 3;

  void _nextPage() {
    if (_page < _totalSteps - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  void _prevPage() {
    if (_page > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
      setState(() => _page--);
    }
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserType,   _userType!.name);
    await prefs.setString(AppConstants.keyUserName,   _nameCtrl.text.trim());
    await prefs.setInt(AppConstants.keyUserAge,        _age);
    await prefs.setInt(AppConstants.keyGestWeek,       _gestWeek);
    await prefs.setInt(AppConstants.keyBabyBirthMonth, _babyMonths);
    await prefs.setString(AppConstants.keyTrimester, _trimester.code);
    await prefs.setInt(AppConstants.keyParity,        _parity);
    await prefs.setInt(AppConstants.keyAnemiaLevel,   _anemiaLevel);
    await prefs.setBool(AppConstants.keyRural,        _rural);
    await prefs.setBool(AppConstants.keyNotifEnabled, _notifEnabled);
    await prefs.setInt(AppConstants.keyNotifHour,     _notifHour);
    await prefs.setBool(AppConstants.keyOnboardingDone, true);

    if (_notifEnabled) {
      try {
        await NotificationService.requestPermission();
        await NotificationService.scheduleDailyCheck(hour: _notifHour);
      } catch (e) {
        debugPrint('Notification setup failed: $e');
      }
    }

    if (!mounted) return;
    context.go('/home');
  }

  bool get _canNext {
    switch (_page) {
      case 0: return _userType != null;
      case 1: return true;
      default: return true;
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _TopBar(
                page: _page,
                total: _totalSteps,
                onBack: _prevPage,
              ),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Step1(
                      selected: _userType,
                      onSelect: (t) => setState(() => _userType = t),
                    ),
                    if (_userType == UserType.pregnant)
                      _Step2Pregnant(
                        nameCtrl: _nameCtrl,
                        age: _age, onAge: (v) => setState(() => _age = v),
                        gestWeek: _gestWeek,
                        onGestWeek: (v) => setState(() {
                          _gestWeek = v;
                          _trimester = TrimesterExt.fromWeek(v);
                        }),
                        trimester: _trimester,
                      )
                    else
                      _Step2Postpartum(
                        nameCtrl: _nameCtrl,
                        babyMonths: _babyMonths,
                        onBabyMonths: (v) => setState(() => _babyMonths = v),
                      ),
                    _Step3Health(
                      parity: _parity, anemiaLevel: _anemiaLevel,
                      bpHistory: _bpHistory, diabetesHistory: _diabetesHistory,
                      thyroidHistory: _thyroidHistory,
                      onParity:   (v) => setState(() => _parity = v),
                      onAnemia:   (v) => setState(() => _anemiaLevel = v),
                      onBp:       (v) => setState(() => _bpHistory = v),
                      onDiabetes: (v) => setState(() => _diabetesHistory = v),
                      onThyroid:  (v) => setState(() => _thyroidHistory = v),
                    ),
                    _Step4Preferences(
                      rural: _rural, notifEnabled: _notifEnabled,
                      notifHour: _notifHour,
                      onRural:  (v) => setState(() => _rural = v),
                      onNotif:  (v) => setState(() => _notifEnabled = v),
                      onHour:   (v) => setState(() => _notifHour = v),
                    ),
                  ],
                ),
              ),
              _BottomButton(
                page: _page,
                total: _totalSteps,
                enabled: _canNext,
                finishing: _finishing,
                onTap: _nextPage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Top navigation bar ───────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int page, total;
  final VoidCallback onBack;
  const _TopBar({required this.page, required this.total, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(children: [
          Row(children: [
            if (page > 0)
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 42, height: 42,
                  decoration: AppDecoration.smallCard,
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textMedium, size: 20),
                ),
              )
            else
              const SizedBox(width: 42),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${page + 1} / $total',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: GoogleFonts.nunito().fontFamily,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          _ProgressBar(current: page, total: total),
        ]),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current, total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      return Row(
        children: List.generate(total, (i) {
          final active = i <= current;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              height: 5,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              decoration: BoxDecoration(
                gradient: active ? AppColors.headerGradient : null,
                color: active ? null : AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      );
    });
  }
}

// ─── Bottom button ────────────────────────────────────────────
class _BottomButton extends StatelessWidget {
  final int page, total;
  final bool enabled, finishing;
  final VoidCallback onTap;
  const _BottomButton({
    required this.page, required this.total,
    required this.enabled, required this.finishing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = page == total - 1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: GestureDetector(
          onTap: (enabled && !finishing) ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: enabled
                  ? AppColors.headerGradient
                  : null,
              color: enabled ? null : AppColors.divider,
              borderRadius: BorderRadius.circular(18),
              boxShadow: enabled ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ] : [],
            ),
            child: Center(
              child: finishing
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? 'Boshlash' : 'Davom etish',
                        style: TextStyle(
                          color: enabled ? Colors.white : AppColors.textGrey,
                          fontSize: 16, fontWeight: FontWeight.w700,
                          fontFamily: GoogleFonts.nunito().fontFamily,
                        ),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: enabled ? Colors.white : AppColors.textGrey,
                          size: 18,
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.rocket_launch_rounded,
                          color: enabled ? Colors.white : AppColors.textGrey,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}

// ═══ STEP 1 — User type ═══════════════════════════════════════
class _Step1 extends StatelessWidget {
  final UserType? selected;
  final ValueChanged<UserType> onSelect;
  const _Step1({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),

        // Illustration area
        Center(
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌸', style: TextStyle(fontSize: 48)),
            ),
          ),
        ).animate().scale(begin: const Offset(0.7, 0.7), duration: 400.ms,
            curve: Curves.elasticOut),

        const SizedBox(height: 24),
        Text('Salom! 👋',
          style: GoogleFonts.nunito(
            fontSize: 30, fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text('Holatingizni tanlang',
          style: GoogleFonts.nunito(
            fontSize: 16, color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 28),

        _UserTypeCard(
          emoji: '🤰', title: 'Homiladorman',
          subtitle: 'Trimestga mos xavflarni kuzataman',
          enabled: true,
          selected: selected == UserType.pregnant,
          onTap: () => onSelect(UserType.pregnant),
          delay: 0,
        ),
        const SizedBox(height: 12),
        _UserTypeCard(
          emoji: '👶', title: "Chaqalog'im bor",
          subtitle: "Tug'ruqdan keyingi holat va depressiya skriningi",
          enabled: true,
          selected: selected == UserType.postpartum,
          onTap: () => onSelect(UserType.postpartum),
          delay: 80,
        ),
        const SizedBox(height: 12),
        _UserTypeCard(
          emoji: '🌱', title: 'Rejalashtiraman',
          subtitle: 'Keyingi versiyada',
          enabled: false,
          selected: false,
          onTap: null,
          delay: 160,
        ),
      ]),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final bool enabled, selected;
  final VoidCallback? onTap;
  final int delay;

  const _UserTypeCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.enabled, required this.selected,
    required this.onTap, required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 16, offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Text(emoji, style: TextStyle(
              fontSize: 38,
              color: enabled ? null : Colors.grey.shade300)),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(title, style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: enabled
                        ? (selected ? AppColors.primary : AppColors.textDark)
                        : AppColors.textGrey,
                  )),
                ),
                if (!enabled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Tez orada', style: GoogleFonts.nunito(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    )),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(subtitle, style: GoogleFonts.nunito(
                fontSize: 13,
                color: enabled
                    ? AppColors.textMedium
                    : AppColors.textGrey.withValues(alpha: 0.5),
              )),
            ],
          )),
          const SizedBox(width: 8),
          if (selected)
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            )
          else if (enabled)
            Icon(Icons.chevron_right_rounded, color: AppColors.border, size: 24)
          else
            Icon(Icons.lock_rounded, color: AppColors.divider, size: 18),
        ]),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 350.ms)
     .slideX(begin: 0.04, end: 0);
  }
}

// ═══ STEP 2 — Pregnant ════════════════════════════════════════
class _Step2Pregnant extends StatelessWidget {
  final TextEditingController nameCtrl;
  final int age, gestWeek;
  final Trimester trimester;
  final ValueChanged<int> onAge, onGestWeek;

  const _Step2Pregnant({
    required this.nameCtrl,
    required this.age, required this.onAge,
    required this.gestWeek, required this.onGestWeek,
    required this.trimester,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        _StepHeader(
          emoji: '✨',
          title: "Ma'lumotlaringiz",
          subtitle: "Siz haqingizda bir oz ma'lumot",
        ),
        const SizedBox(height: 28),
        _InputField(
          label: 'Ismingiz (ixtiyoriy)',
          ctrl: nameCtrl,
          hint: 'Masalan: Malika',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _NumberStepper(
          label: 'Yoshingiz',
          value: age, min: 16, max: 55,
          suffix: 'yosh',
          onChanged: onAge,
        ),
        const SizedBox(height: 20),
        _NumberStepper(
          label: 'Homiladorlik haftasi',
          value: gestWeek, min: 1, max: 42,
          suffix: 'hafta',
          onChanged: onGestWeek,
        ),
        const SizedBox(height: 14),
        _TrimesterBadge(trimester: trimester),
      ]),
    );
  }
}

// ═══ STEP 2 — Postpartum ═════════════════════════════════════
class _Step2Postpartum extends StatelessWidget {
  final TextEditingController nameCtrl;
  final int babyMonths;
  final ValueChanged<int> onBabyMonths;
  const _Step2Postpartum({
    required this.nameCtrl,
    required this.babyMonths,
    required this.onBabyMonths,
  });

  String get _monthLabel {
    if (babyMonths == 0) return 'Yangi tug\'ilgan';
    if (babyMonths == 1) return '1 oylik';
    return '$babyMonths oylik';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        _StepHeader(
          emoji: '👶',
          title: "Chaqalog'ingiz",
          subtitle: "Bola haqida ma'lumot",
        ),
        const SizedBox(height: 28),
        _InputField(
          label: 'Ismingiz (ixtiyoriy)',
          ctrl: nameCtrl,
          hint: 'Masalan: Malika',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _NumberStepper(
          label: "Chaqalog'ingiz necha oylik?",
          value: babyMonths, min: 0, max: 24,
          suffix: 'oy',
          onChanged: onBabyMonths,
        ),
        const SizedBox(height: 12),
        // Month badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🍼', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(_monthLabel, style: GoogleFonts.nunito(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.softPinkGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            const Text('💜', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(child: Text(
              "Tug'ruqdan keyingi davrda onaning ruhiy va jismoniy holati kuzatiladi.",
              style: GoogleFonts.nunito(
                fontSize: 13, color: AppColors.textMedium, height: 1.5),
            )),
          ]),
        ),
      ]),
    );
  }
}

// ═══ STEP 3 — Health history ══════════════════════════════════
class _Step3Health extends StatelessWidget {
  final int parity, anemiaLevel;
  final bool bpHistory, diabetesHistory, thyroidHistory;
  final ValueChanged<int> onParity, onAnemia;
  final ValueChanged<bool> onBp, onDiabetes, onThyroid;

  const _Step3Health({
    required this.parity, required this.anemiaLevel,
    required this.bpHistory, required this.diabetesHistory,
    required this.thyroidHistory, required this.onParity,
    required this.onAnemia, required this.onBp,
    required this.onDiabetes, required this.onThyroid,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        _StepHeader(
          emoji: '🏥',
          title: "Sog'liq tarixi",
          subtitle: "Bu ma'lumotlar aniqroq tahlil uchun kerak",
        ),
        const SizedBox(height: 28),

        _SectionLabel('Nechinci homiladorligingiz?'),
        const SizedBox(height: 10),
        _ChipRow(
          options: ['Birinchi', '2–3 marta', '4 yoki ko\'proq'],
          selected: parity, onSelect: onParity,
        ),

        const SizedBox(height: 22),
        _SectionLabel('Kamqonlik (anemiya) darajasi'),
        const SizedBox(height: 10),
        _ChipRow(
          options: ["Yo'q", 'Yengil', "O'rta", "Og'ir"],
          selected: anemiaLevel, onSelect: onAnemia,
        ),

        const SizedBox(height: 22),
        _SectionLabel('Kasallik tarixingizda bormi?'),
        const SizedBox(height: 10),
        _ToggleTile(
          label: '🩸 Yuqori qon bosimi',
          value: bpHistory, onChanged: onBp,
        ),
        const SizedBox(height: 10),
        _ToggleTile(
          label: '🍬 Qandli diabet',
          value: diabetesHistory, onChanged: onDiabetes,
        ),
        const SizedBox(height: 10),
        _ToggleTile(
          label: '🦋 Qalqonsimon bez muammosi',
          value: thyroidHistory, onChanged: onThyroid,
        ),
      ]),
    );
  }
}

// ═══ STEP 4 — Preferences ════════════════════════════════════
class _Step4Preferences extends StatelessWidget {
  final bool rural, notifEnabled;
  final int notifHour;
  final ValueChanged<bool> onRural, onNotif;
  final ValueChanged<int> onHour;

  const _Step4Preferences({
    required this.rural, required this.notifEnabled,
    required this.notifHour, required this.onRural,
    required this.onNotif, required this.onHour,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        _StepHeader(
          emoji: '⚙️',
          title: "So'nggi sozlamalar",
          subtitle: "Deyarli tayyor!",
        ),
        const SizedBox(height: 28),

        _SectionLabel('Joylashuvingiz'),
        const SizedBox(height: 10),
        _ChipRow(
          options: ['🏙️ Shahar', '🌾 Qishloq / tuman'],
          selected: rural ? 1 : 0,
          onSelect: (v) => onRural(v == 1),
        ),

        const SizedBox(height: 24),
        _SectionLabel('Kunlik eslatmalar'),
        const SizedBox(height: 10),
        _ToggleTile(
          label: '🔔 Kunlik tekshiruv eslatmasi',
          value: notifEnabled, onChanged: onNotif,
        ),

        if (notifEnabled) ...[
          const SizedBox(height: 18),
          _SectionLabel('Eslatma vaqti'),
          const SizedBox(height: 10),
          _TimeGrid(selected: notifHour, onSelect: onHour),
        ],

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Text('🌸', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(child: Text(
              "Onamiz doimo yoningizda! Har kuni bir daqiqa vaqt ajrating — sog'ligingiz muhim.",
              style: GoogleFonts.nunito(
                fontSize: 13, color: Colors.white, height: 1.5,
              ),
            )),
          ]),
        ),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final String emoji, title, subtitle;
  const _StepHeader({
    required this.emoji, required this.title, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.softPinkGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
      ),
      const SizedBox(height: 16),
      Text(title, style: GoogleFonts.nunito(
        fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark,
      )),
      const SizedBox(height: 4),
      Text(subtitle, style: GoogleFonts.nunito(
        fontSize: 15, color: AppColors.textMedium,
      )),
    ]);
  }
}

class _InputField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final IconData icon;
  const _InputField({
    required this.label, required this.ctrl,
    required this.hint, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(
        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark,
      )),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    ]);
  }
}

class _TrimesterBadge extends StatelessWidget {
  final Trimester trimester;
  const _TrimesterBadge({required this.trimester});

  @override
  Widget build(BuildContext context) {
    final color = switch (trimester) {
      Trimester.T1 => AppColors.t1Color,
      Trimester.T2 => AppColors.t2Color,
      Trimester.T3 => AppColors.t3Color,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text('${trimester.label} — ${trimester.weeks}',
          style: GoogleFonts.nunito(
            color: color, fontSize: 14, fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.nunito(
      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark,
    ));
}

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;
  const _ChipRow({
    required this.options, required this.selected, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(options.length, (i) {
        final active = selected == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: active ? AppColors.headerGradient : null,
              color: active ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: active ? Colors.transparent : AppColors.border,
                width: 1.5,
              ),
              boxShadow: active ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8, offset: const Offset(0, 3),
                ),
              ] : [],
            ),
            child: Text(options[i], style: GoogleFonts.nunito(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textMedium,
            )),
          ),
        );
      }),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.label, required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
        decoration: BoxDecoration(
          color: value ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(children: [
          Expanded(child: Text(label, style: GoogleFonts.nunito(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: value ? AppColors.primary : AppColors.textMedium,
          ))),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primaryLight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ]),
      ),
    );
  }
}

class _TimeGrid extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _TimeGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final times = [7, 8, 9, 10, 11, 18, 20, 21];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: times.map((h) {
        final active = selected == h;
        return GestureDetector(
          onTap: () => onSelect(h),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: active ? AppColors.headerGradient : null,
              color: active ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: active ? Colors.transparent : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Text('$h:00', style: GoogleFonts.nunito(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textMedium,
            )),
          ),
        );
      }).toList(),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final String label;
  final int value, min, max;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _NumberStepper({
    required this.label, required this.value,
    required this.min, required this.max,
    required this.suffix, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canDec = value > min;
    final canInc = value < max;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(
        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark,
      )),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(children: [
          // Minus
          GestureDetector(
            onTap: canDec ? () => onChanged(value - 1) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: canDec ? AppColors.primaryLight : AppColors.divider,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.remove_rounded,
                color: canDec ? AppColors.primary : AppColors.textGrey,
                size: 20),
            ),
          ),
          // Value
          Expanded(child: Center(child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$value', style: GoogleFonts.nunito(
                fontSize: 34, fontWeight: FontWeight.w800,
                color: AppColors.textDark, height: 1,
              )),
              const SizedBox(width: 6),
              Text(suffix, style: GoogleFonts.nunito(
                fontSize: 14, color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              )),
            ],
          ))),
          // Plus
          GestureDetector(
            onTap: canInc ? () => onChanged(value + 1) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: canInc ? AppColors.headerGradient : null,
                color: canInc ? null : AppColors.divider,
                borderRadius: BorderRadius.circular(12),
                boxShadow: canInc ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8, offset: const Offset(0, 3),
                  ),
                ] : [],
              ),
              child: Icon(Icons.add_rounded,
                color: canInc ? Colors.white : AppColors.textGrey,
                size: 20),
            ),
          ),
        ]),
      ),
    ]);
  }
}
