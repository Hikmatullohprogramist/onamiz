import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class PregnancySetupScreen extends StatefulWidget {
  const PregnancySetupScreen({super.key});

  @override
  State<PregnancySetupScreen> createState() => _PregnancySetupScreenState();
}

class _PregnancySetupScreenState extends State<PregnancySetupScreen> {
  final _weekCtrl = TextEditingController();
  final _ageCtrl  = TextEditingController();
  Trimester? _trimester;
  bool _rural = false;

  String? _weekError;
  String? _ageError;

  void _detectTrimester(int week) {
    if (week >= 1 && week <= 12)       _trimester = Trimester.T1;
    else if (week >= 13 && week <= 26) _trimester = Trimester.T2;
    else if (week >= 27 && week <= 42) _trimester = Trimester.T3;
    else                               _trimester = null;
    setState(() {});
  }

  Future<void> _onContinue() async {
    setState(() {
      _weekError = null;
      _ageError  = null;
    });

    final week = int.tryParse(_weekCtrl.text);
    final age  = int.tryParse(_ageCtrl.text);

    if (week == null || week < 1 || week > 42) {
      setState(() => _weekError = '1 dan 42 gacha raqam kiriting');
      return;
    }
    if (age == null || age < 14 || age > 55) {
      setState(() => _ageError = '14 dan 55 gacha yosh kiriting');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyGestWeek, week);
    await prefs.setInt(AppConstants.keyUserAge, age);
    await prefs.setString(AppConstants.keyTrimester, _trimester!.code);
    await prefs.setBool(AppConstants.keyRural, _rural);
    await prefs.setBool(AppConstants.keyOnboardingDone, true);

    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  void dispose() {
    _weekCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma\'lumotlaringiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bir necha savol ✨',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu ma\'lumotlar sizga mos savollar va tavsiyalar berishimiz uchun kerak.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Hafta
            _InputLabel('Homiladorlik haftaligingiz'),
            const SizedBox(height: 8),
            TextField(
              controller: _weekCtrl,
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final w = int.tryParse(v);
                if (w != null) _detectTrimester(w);
              },
              decoration: InputDecoration(
                hintText: 'Masalan: 18',
                suffixText: 'hafta',
                errorText: _weekError,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            // Trimest ko'rsatgich
            if (_trimester != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _trimester!.label,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Yosh
            _InputLabel('Yoshingiz'),
            const SizedBox(height: 8),
            TextField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Masalan: 28',
                suffixText: 'yosh',
                errorText: _ageError,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Joylashuv
            _InputLabel('Joylashuvingiz'),
            const SizedBox(height: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  _LocationTile(
                    label:    'Shahar',
                    emoji:    '🏙️',
                    selected: !_rural,
                    onTap:    () => setState(() => _rural = false),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _LocationTile(
                    label:    'Qishloq / tuman',
                    emoji:    '🌾',
                    selected: _rural,
                    onTap:    () => setState(() => _rural = true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _trimester != null ? _onContinue : null,
              child: const Text('Boshlash 🚀'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
  );
}

class _LocationTile extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _LocationTile({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Text(emoji, style: const TextStyle(fontSize: 24)),
    title: Text(label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.primary : AppColors.textDark,
        )),
    trailing: selected
        ? const Icon(Icons.check_circle, color: AppColors.primary)
        : null,
    onTap: onTap,
  );
}
