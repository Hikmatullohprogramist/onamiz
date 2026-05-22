import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  // Step 1 — Klassifikatsiya
  UserType? _userType;

  // Step 2 — Asosiy ma'lumotlar
  final _nameCtrl = TextEditingController();
  final _ageCtrl  = TextEditingController();
  final _weekCtrl = TextEditingController();
  Trimester? _trimester;

  // Step 3 — Sog'liq tarixi
  int _parity         = 0;  // 0=birinchi, 1=2-3, 2=4+
  int _anemiaLevel    = 0;
  bool _bpHistory     = false;
  bool _diabetesHistory = false;
  bool _thyroidHistory  = false;

  // Step 4 — Joylashuv + bildirishnoma
  bool _rural         = false;
  bool _notifEnabled  = true;
  int  _notifHour     = 9;

  int get _totalSteps => _userType == UserType.pregnant ? 4 : 3;

  void _nextPage() {
    if (_page < _totalSteps - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
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
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _page--);
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserType,   _userType!.name);
    await prefs.setString(AppConstants.keyUserName,   _nameCtrl.text.trim());
    await prefs.setInt(AppConstants.keyUserAge,       int.tryParse(_ageCtrl.text) ?? 25);
    await prefs.setInt(AppConstants.keyGestWeek,      int.tryParse(_weekCtrl.text) ?? 1);
    await prefs.setString(AppConstants.keyTrimester,  _trimester?.code ?? 'T1');
    await prefs.setInt(AppConstants.keyParity,        _parity);
    await prefs.setInt(AppConstants.keyAnemiaLevel,   _anemiaLevel);
    await prefs.setBool(AppConstants.keyRural,        _rural);
    await prefs.setBool(AppConstants.keyNotifEnabled, _notifEnabled);
    await prefs.setInt(AppConstants.keyNotifHour,     _notifHour);
    await prefs.setBool(AppConstants.keyOnboardingDone, true);

    if (_notifEnabled) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleDailyCheck(hour: _notifHour);
    }

    if (!mounted) return;
    context.go('/dashboard');
  }

  bool get _canNext {
    switch (_page) {
      case 0: return _userType != null;
      case 1: return (_ageCtrl.text.isNotEmpty) &&
                     (_userType == UserType.pregnant ? _trimester != null : true);
      default: return true;
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weekCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  if (_page > 0)
                    GestureDetector(
                      onTap: _prevPage,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8, offset: const Offset(0,2))
                          ],
                        ),
                        child: const Icon(Icons.chevron_left, color: AppColors.textDark),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                  Expanded(child: _ProgressDots(current: _page, total: _totalSteps)),
                  Text('${_page + 1}/$_totalSteps',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textGrey,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(selected: _userType,
                      onSelect: (t) => setState(() => _userType = t)),
                  if (_userType == UserType.pregnant)
                    _Step2Pregnant(
                      nameCtrl: _nameCtrl, ageCtrl: _ageCtrl,
                      weekCtrl: _weekCtrl, trimester: _trimester,
                      onTrimester: (t) => setState(() => _trimester = t),
                    )
                  else
                    _Step2Postpartum(nameCtrl: _nameCtrl, ageCtrl: _ageCtrl),
                  _Step3Health(
                    parity: _parity, anemiaLevel: _anemiaLevel,
                    bpHistory: _bpHistory, diabetesHistory: _diabetesHistory,
                    thyroidHistory: _thyroidHistory,
                    onParity:    (v) => setState(() => _parity = v),
                    onAnemia:    (v) => setState(() => _anemiaLevel = v),
                    onBp:        (v) => setState(() => _bpHistory = v),
                    onDiabetes:  (v) => setState(() => _diabetesHistory = v),
                    onThyroid:   (v) => setState(() => _thyroidHistory = v),
                  ),
                  _Step4Preferences(
                    rural: _rural, notifEnabled: _notifEnabled,
                    notifHour: _notifHour,
                    onRural:   (v) => setState(() => _rural = v),
                    onNotif:   (v) => setState(() => _notifEnabled = v),
                    onHour:    (v) => setState(() => _notifHour = v),
                  ),
                ],
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ElevatedButton(
                onPressed: _canNext ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canNext ? AppColors.primary : AppColors.textGrey.withValues(alpha: 0.3),
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  elevation: _canNext ? 8 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_page == _totalSteps - 1 ? 'Boshlash 🚀' : 'Davom etish'),
                    if (_page < _totalSteps - 1) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress dots ────────────────────────────────────────────
class _ProgressDots extends StatelessWidget {
  final int current, total;
  const _ProgressDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ═══ STEP 1 — Klassifikatsiya ═════════════════════════════════
class _Step1 extends StatelessWidget {
  final UserType? selected;
  final ValueChanged<UserType> onSelect;
  const _Step1({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      (UserType.pregnant,   '🤰', 'Homiladorman',
       'Trimestga mos xavflarni kuzataman', true),
      (UserType.postpartum, '👶', "Chaqalog'im bor",
       "Tug'ruqdan keyingi holat va depressiya skriningi", true),
      (UserType.planning,   '🌱', 'Rejalashtiraman',
       'Keyingi versiyada', false),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('Salom! 👋', style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w800,
              color: AppColors.textDark)),
          const SizedBox(height: 6),
          const Text('Holatingizni tanlang',
              style: TextStyle(fontSize: 16, color: AppColors.textGrey)),
          const SizedBox(height: 28),
          ...options.map((o) {
            final (type, emoji, title, sub, enabled) = o;
            final isSelected = selected == type;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TypeCard(
                emoji: emoji, title: title, subtitle: sub,
                enabled: enabled, selected: isSelected,
                onTap: enabled ? () => onSelect(type) : null,
              ).animate().fadeIn(delay: (options.indexOf(o) * 80).ms, duration: 350.ms)
               .slideX(begin: 0.05, end: 0),
            );
          }),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final bool enabled, selected;
  final VoidCallback? onTap;
  const _TypeCard({required this.emoji, required this.title,
    required this.subtitle, required this.enabled,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected ? [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 12, offset: const Offset(0, 4))
          ] : [],
        ),
        child: Row(children: [
          Text(emoji, style: TextStyle(
              fontSize: 40, color: enabled ? null : Colors.grey.shade400)),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(title, style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: enabled ? (selected ? AppColors.primary : AppColors.textDark)
                                 : AppColors.textGrey,
                )),
                if (!enabled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Tez orada',
                        style: TextStyle(fontSize: 10, color: AppColors.textGrey,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(
                  fontSize: 13,
                  color: enabled ? AppColors.textGrey : AppColors.textGrey.withValues(alpha: 0.5))),
            ],
          )),
          if (selected) const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 22)
          else if (enabled) Icon(Icons.chevron_right,
              color: Colors.grey.shade300, size: 22)
          else Icon(Icons.lock_rounded, color: Colors.grey.shade300, size: 18),
        ]),
      ),
    );
  }
}

// ═══ STEP 2 — Homilador: asosiy ma'lumotlar ══════════════════
class _Step2Pregnant extends StatelessWidget {
  final TextEditingController nameCtrl, ageCtrl, weekCtrl;
  final Trimester? trimester;
  final ValueChanged<Trimester> onTrimester;

  const _Step2Pregnant({required this.nameCtrl, required this.ageCtrl,
    required this.weekCtrl, required this.trimester,
    required this.onTrimester});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const Text('Ma\'lumotlaringiz ✨', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 6),
        const Text('Siz haqingizda bir oz ma\'lumot',
            style: TextStyle(fontSize: 15, color: AppColors.textGrey)),
        const SizedBox(height: 28),

        _Field(label: 'Ismingiz (ixtiyoriy)', ctrl: nameCtrl,
            hint: 'Masalan: Malika', icon: Icons.person_outline_rounded),
        const SizedBox(height: 16),
        _Field(label: 'Yoshingiz', ctrl: ageCtrl,
            hint: '25', icon: Icons.cake_outlined, isNumber: true),
        const SizedBox(height: 16),
        _Field(
          label: 'Homiladorlik haftaligingiz',
          ctrl: weekCtrl,
          hint: '18',
          icon: Icons.calendar_today_outlined,
          isNumber: true,
          onChanged: (v) {
            final w = int.tryParse(v);
            if (w != null && w > 0 && w <= 42) {
              onTrimester(TrimesterExt.fromWeek(w));
            }
          },
        ),

        if (trimester != null) ...[
          const SizedBox(height: 12),
          _TrimesterBadge(trimester: trimester!),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ═══ STEP 2 — Postpartum ═════════════════════════════════════
class _Step2Postpartum extends StatelessWidget {
  final TextEditingController nameCtrl, ageCtrl;
  const _Step2Postpartum({required this.nameCtrl, required this.ageCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const Text('Ma\'lumotlaringiz ✨', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 28),
        _Field(label: 'Ismingiz (ixtiyoriy)', ctrl: nameCtrl,
            hint: 'Masalan: Malika', icon: Icons.person_outline_rounded),
        const SizedBox(height: 16),
        _Field(label: 'Yoshingiz', ctrl: ageCtrl,
            hint: '25', icon: Icons.cake_outlined, isNumber: true),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(children: [
            Text('👶', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(child: Text(
              'Tug\'ruqdan keyingi davrda onaning ruhiy va jismoniy holati kuzatiladi.',
              style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
            )),
          ]),
        ),
      ]),
    );
  }
}

// ═══ STEP 3 — Sog'liq tarixi ═════════════════════════════════
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const Text('Sog\'liq tarixi 🏥', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 6),
        const Text('Bu ma\'lumotlar aniqroq tahlil uchun kerak',
            style: TextStyle(fontSize: 15, color: AppColors.textGrey)),
        const SizedBox(height: 28),

        _SectionLabel('Nechinci homiladorligingiz?'),
        const SizedBox(height: 10),
        _ChipGroup(
          options: ['Birinchi', '2-3 marta', '4 va undan ko\'p'],
          selected: parity, onSelect: onParity,
        ),

        const SizedBox(height: 20),
        _SectionLabel('Kamqonlik (anemiya) bor?'),
        const SizedBox(height: 10),
        _ChipGroup(
          options: ['Yo\'q', 'Yengil', 'O\'rta', 'Og\'ir'],
          selected: anemiaLevel, onSelect: onAnemia,
        ),

        const SizedBox(height: 20),
        _SectionLabel('Kasallik tarixingizda bor?'),
        const SizedBox(height: 10),
        _ToggleTile(
          label: '🩸 Yuqori qon bosimi',
          value: bpHistory, onChanged: onBp,
        ),
        const SizedBox(height: 8),
        _ToggleTile(
          label: '🍬 Qandli diabet',
          value: diabetesHistory, onChanged: onDiabetes,
        ),
        const SizedBox(height: 8),
        _ToggleTile(
          label: '🦋 Qalqonsimon bez muammosi',
          value: thyroidHistory, onChanged: onThyroid,
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ═══ STEP 4 — Joylashuv + Bildirishnoma ══════════════════════
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const Text('So\'nggi sozlamalar ⚙️', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 28),

        _SectionLabel('Joylashuvingiz'),
        const SizedBox(height: 10),
        _ChipGroup(
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
          const SizedBox(height: 16),
          _SectionLabel('Eslatma vaqti'),
          const SizedBox(height: 10),
          _TimeSelector(selected: notifHour, onSelect: onHour),
        ],

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.1),
                       AppColors.secondary.withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(children: [
            Text('🌸', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(child: Text(
              'Onamiz doimo yoningizda! Har kuni bir daqiqa vaqt ajrating — sog\'ligingiz muhim.',
              style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
            )),
          ]),
        ),
      ]),
    );
  }
}

// ─── Yordamchi widgetlar ──────────────────────────────────────

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final IconData icon;
  final bool isNumber;
  final ValueChanged<String>? onChanged;

  const _Field({required this.label, required this.ctrl,
    required this.hint, required this.icon,
    this.isNumber = false, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 15),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_outline, color: color, size: 16),
        const SizedBox(width: 8),
        Text('${trimester.label} — ${trimester.weeks}',
            style: TextStyle(color: color, fontSize: 14,
                fontWeight: FontWeight.w600)),
      ]),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
        color: AppColors.textDark));
}

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;
  const _ChipGroup({required this.options, required this.selected,
    required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8,
      children: List.generate(options.length, (i) {
        final active = selected == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.divider, width: 1.5),
            ),
            child: Text(options[i], style: TextStyle(
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
  const _ToggleTile({required this.label, required this.value,
    required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppColors.primary : AppColors.divider, width: 1.5),
        ),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: value ? AppColors.primary : AppColors.textMedium,
          ))),
          Switch(
            value: value, onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _TimeSelector({required this.selected, required this.onSelect});

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.divider, width: 1.5),
            ),
            child: Text('$h:00', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textMedium,
            )),
          ),
        );
      }).toList(),
    );
  }
}
