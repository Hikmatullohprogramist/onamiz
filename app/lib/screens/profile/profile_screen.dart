import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();

  UserType _userType    = UserType.pregnant;
  int      _age         = 25;
  int      _gestWeek    = 18;
  Trimester _trimester  = Trimester.T2;
  int      _parity      = 0;
  int      _anemiaLevel = 0;
  bool     _rural       = false;
  bool     _notifEnabled= true;
  int      _notifHour   = 9;
  bool     _loading     = true;
  bool     _saving      = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final typeStr = p.getString(AppConstants.keyUserType) ?? 'pregnant';
    final week    = p.getInt(AppConstants.keyGestWeek) ?? 18;
    setState(() {
      _nameCtrl.text = p.getString(AppConstants.keyUserName) ?? '';
      _userType     = UserType.values.firstWhere(
          (e) => e.name == typeStr, orElse: () => UserType.pregnant);
      _age          = p.getInt(AppConstants.keyUserAge) ?? 25;
      _gestWeek     = week;
      _trimester    = TrimesterExt.fromWeek(week);
      _parity       = p.getInt(AppConstants.keyParity) ?? 0;
      _anemiaLevel  = p.getInt(AppConstants.keyAnemiaLevel) ?? 0;
      _rural        = p.getBool(AppConstants.keyRural) ?? false;
      _notifEnabled = p.getBool(AppConstants.keyNotifEnabled) ?? true;
      _notifHour    = p.getInt(AppConstants.keyNotifHour) ?? 9;
      _loading      = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.keyUserName,     _nameCtrl.text.trim());
    await p.setInt(AppConstants.keyUserAge,          _age);
    await p.setInt(AppConstants.keyGestWeek,         _gestWeek);
    await p.setString(AppConstants.keyTrimester,     _trimester.code);
    await p.setInt(AppConstants.keyParity,           _parity);
    await p.setInt(AppConstants.keyAnemiaLevel,      _anemiaLevel);
    await p.setBool(AppConstants.keyRural,           _rural);
    await p.setBool(AppConstants.keyNotifEnabled,    _notifEnabled);
    await p.setInt(AppConstants.keyNotifHour,        _notifHour);
    if (_notifEnabled) {
      await NotificationService.scheduleDailyCheck(hour: _notifHour);
    }
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("O'zgarishlar saqlandi ✓",
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700,
              color: Colors.white)),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _reset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Qaytadan boshlash?", style: GoogleFonts.nunito(
          fontWeight: FontWeight.w800, color: AppColors.textDark,
        )),
        content: Text(
          "Barcha ma'lumotlar o'chiriladi. Ilova qaytadan sozlash ekraniga o'tadi.",
          style: GoogleFonts.nunito(
            color: AppColors.textMedium, height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Bekor qilish', style: GoogleFonts.nunito(
              color: AppColors.textGrey, fontWeight: FontWeight.w600,
            )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Ha, o'chirish", style: GoogleFonts.nunito(
              color: AppColors.red, fontWeight: FontWeight.w700,
            )),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final p = await SharedPreferences.getInstance();
    await p.clear();
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [

        // ── Gradient header ──────────────────────────────────
        SliverAppBar(
          pinned: true,
          expandedHeight: 190,
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
              ),
              SafeArea(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5), width: 2),
                      ),
                      child: Center(child: Text(
                        _userType == UserType.pregnant ? '🤰' : '👶',
                        style: const TextStyle(fontSize: 34),
                      )),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Foydalanuvchi',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _userType == UserType.pregnant
                          ? '$_gestWeek-hafta • ${_trimester.label}'
                          : "Tug'ruqdan keyingi holat",
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
            ]),
            // title: Padding(
            //   padding: const EdgeInsets.only(left: 4),
            //   child: Text('Profil', style: GoogleFonts.nunito(
            //     color: AppColors.textDark,
            //     fontSize: 17, fontWeight: FontWeight.w800,
            //   )),
            // ),
            titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
            collapseMode: CollapseMode.parallax,
          ),
        ),













        

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // ── Personal info ──────────────────────────────
            _SectionHeader("Shaxsiy ma'lumot", Icons.person_outline_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecoration.card,
              child: Column(children: [
                _LabeledField(
                  label: 'Ismingiz',
                  child: TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.nunito(
                        fontSize: 15, color: AppColors.textDark),
                    decoration: const InputDecoration(
                      hintText: 'Masalan: Malika',
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _Stepper(
                  label: 'Yosh',
                  value: _age, min: 16, max: 55, suffix: 'yosh',
                  onChanged: (v) => setState(() => _age = v),
                ),
                if (_userType == UserType.pregnant) ...[
                  const SizedBox(height: 20),
                  _Stepper(
                    label: 'Homiladorlik haftasi',
                    value: _gestWeek, min: 1, max: 42, suffix: 'hafta',
                    onChanged: (v) => setState(() {
                      _gestWeek  = v;
                      _trimester = TrimesterExt.fromWeek(v);
                    }),
                  ),
                  const SizedBox(height: 12),
                  _TrimesterChip(trimester: _trimester),
                ],
              ]),
            ).animate().fadeIn(delay: 50.ms, duration: 350.ms),

            const SizedBox(height: 20),

            // ── Health info ────────────────────────────────
            _SectionHeader("Sog'liq ma'lumotlari", Icons.favorite_border_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecoration.card,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_userType == UserType.pregnant) ...[
                  _ChipLabel('Nechinci homiladorlik?'),
                  const SizedBox(height: 10),
                  _ChipRow(
                    options: ['Birinchi', '2–3 marta', "4+"],
                    selected: _parity,
                    onSelect: (v) => setState(() => _parity = v),
                  ),
                  const SizedBox(height: 20),
                ],
                _ChipLabel('Kamqonlik darajasi'),
                const SizedBox(height: 10),
                _ChipRow(
                  options: ["Yo'q", 'Yengil', "O'rta", "Og'ir"],
                  selected: _anemiaLevel,
                  onSelect: (v) => setState(() => _anemiaLevel = v),
                ),
              ]),
            ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

            const SizedBox(height: 20),

            // ── Settings ──────────────────────────────────
            _SectionHeader('Sozlamalar', Icons.settings_outlined),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecoration.card,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ChipLabel('Joylashuv'),
                const SizedBox(height: 10),
                _ChipRow(
                  options: ['🏙️ Shahar', '🌾 Qishloq'],
                  selected: _rural ? 1 : 0,
                  onSelect: (v) => setState(() => _rural = v == 1),
                ),
                const SizedBox(height: 20),
                _Toggle(
                  label: '🔔 Kunlik eslatma',
                  value: _notifEnabled,
                  onChanged: (v) => setState(() => _notifEnabled = v),
                ),
                if (_notifEnabled) ...[
                  const SizedBox(height: 18),
                  _ChipLabel('Eslatma vaqti'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [7, 8, 9, 10, 11, 18, 20, 21].map((h) {
                      final active = _notifHour == h;
                      return GestureDetector(
                        onTap: () => setState(() => _notifHour = h),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: active ? AppColors.headerGradient : null,
                            color: active ? null : AppColors.background,
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
                  ),
                ],
              ]),
            ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

            const SizedBox(height: 24),

            // ── Save button ───────────────────────────────
            GestureDetector(
              onTap: _saving ? null : _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  gradient: _saving ? null : AppColors.headerGradient,
                  color: _saving ? AppColors.divider : null,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _saving ? [] : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text("O'zgarishlarni saqlash",
                        style: GoogleFonts.nunito(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 350.ms),

            const SizedBox(height: 12),

            // ── Reset button ──────────────────────────────
            GestureDetector(
              onTap: _reset,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Center(child: Text("Qaytadan o'rnatish",
                  style: GoogleFonts.nunito(
                    color: AppColors.red, fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ))),
              ),
            ).animate().fadeIn(delay: 220.ms, duration: 350.ms),
          ])),
        ),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: AppColors.primary),
    ),
    const SizedBox(width: 10),
    Text(title, style: GoogleFonts.nunito(
      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark,
    )),
  ]);
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark,
      )),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _Stepper extends StatelessWidget {
  final String label, suffix;
  final int value, min, max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.label, required this.suffix,
    required this.value, required this.min, required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canDec = value > min;
    final canInc = value < max;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark,
      )),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: canDec ? () => onChanged(value - 1) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: canDec ? AppColors.primaryLight : AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.remove_rounded,
                color: canDec ? AppColors.primary : AppColors.textGrey,
                size: 18),
            ),
          ),
          Expanded(child: Center(child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$value', style: GoogleFonts.nunito(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: AppColors.textDark, height: 1,
              )),
              const SizedBox(width: 5),
              Text(suffix, style: GoogleFonts.nunito(
                fontSize: 13, color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              )),
            ],
          ))),
          GestureDetector(
            onTap: canInc ? () => onChanged(value + 1) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: canInc ? AppColors.headerGradient : null,
                color: canInc ? null : AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_rounded,
                color: canInc ? Colors.white : AppColors.textGrey,
                size: 18),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _TrimesterChip extends StatelessWidget {
  final Trimester trimester;
  const _TrimesterChip({required this.trimester});

  @override
  Widget build(BuildContext context) {
    final color = switch (trimester) {
      Trimester.T1 => AppColors.t1Color,
      Trimester.T2 => AppColors.t2Color,
      Trimester.T3 => AppColors.t3Color,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('${trimester.label} — ${trimester.weeks}',
          style: GoogleFonts.nunito(
            fontSize: 12, fontWeight: FontWeight.w700, color: color,
          )),
      ]),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String text;
  const _ChipLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.nunito(
    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark,
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
    return Wrap(spacing: 8, runSpacing: 8,
      children: List.generate(options.length, (i) {
        final active = selected == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: active ? AppColors.headerGradient : null,
              color: active ? null : AppColors.background,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: active ? Colors.transparent : AppColors.border,
                width: 1.5,
              ),
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

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: value ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? AppColors.primary : AppColors.border, width: 1.5,
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
            value: value, onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ]),
    ),
  );
}
