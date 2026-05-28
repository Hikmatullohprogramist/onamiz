import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/risk_result.dart';
import '../../services/api_service.dart';

// ─── Entry point ─────────────────────────────────────────────

class DailyCheckScreen extends StatefulWidget {
  const DailyCheckScreen({super.key});

  @override
  State<DailyCheckScreen> createState() => _DailyCheckScreenState();
}

class _DailyCheckScreenState extends State<DailyCheckScreen> {
  // Foydalanuvchi profili
  String _trimester = 'T2';
  int _age = 25;
  int _gestWeek = 20;
  int _anemiaLevel = 0;
  int _parity = 0;
  bool _rural = false;

  // Ekran holati
  bool _profileLoaded = false;
  bool _loading = false;
  bool _submitted = false;
  RiskResult? _result;
  String? _errorMsg;

  // Savol javoblari
  final Map<String, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await SharedPreferences.getInstance();
    final trim = p.getString(AppConstants.keyTrimester) ?? 'T2';
    final week = p.getInt(AppConstants.keyGestWeek) ?? 20;
    setState(() {
      _trimester = trim;
      _gestWeek = week;
      _age = p.getInt(AppConstants.keyUserAge) ?? 25;
      _anemiaLevel = p.getInt(AppConstants.keyAnemiaLevel) ?? 0;
      _parity = p.getInt(AppConstants.keyParity) ?? 0;
      _rural = p.getBool(AppConstants.keyRural) ?? false;
      _profileLoaded = true;

      // Default qiymatlar
      for (final q in _questionsFor(trim)) {
        _answers[q.key] = 0;
      }
    });
  }

  List<_Question> _questionsFor(String trim) {
    return switch (trim) {
      'T1' => _t1Questions,
      'T3' => _t3Questions,
      _ => _t2Questions,
    };
  }

  // ─── T1 savollar ─────────────────────────────────────────
  static const _t1Questions = [
    _Question(
      key: 'vaginal_bleeding',
      emoji: '🩸',
      title: 'Qin qon ketishi',
      text: "Qin dan qon ketish yoki dog' bo'lyaptimi?",
      options: ["Yo'q", 'Ozgina (dog\')', "Ko'p (qon oqyapti)"],
      dangerAt: 1,
    ),
    _Question(
      key: 'one_sided_pain',
      emoji: '⚡',
      title: 'Bir tomonlama og\'riq',
      text: "Bir tomonlama kuchli qorin og'rig'i boryaptimi?",
      options: ["Yo'q", 'Ha — kuchli og\'riq bor'],
      dangerAt: 1,
    ),
    _Question(
      key: 'nausea_severity',
      emoji: '🤢',
      title: 'Ko\'ngil aynishi',
      text: "Ko'ngil aynishi va qusish qanchalik kuchli?",
      options: [
        "Yo'q",
        'Ozgina',
        "O'rtacha",
        'Kuchli — ovqat yeyolmayapman',
        "Juda kuchli — yota olmayapman",
      ],
      dangerAt: 3,
    ),
    _Question(
      key: 'dizziness',
      emoji: '😴',
      title: 'Zaiflik / bosh aylanishi',
      text: 'Zaiflik yoki bosh aylanishi boryaptimi?',
      options: ["Yo'q", 'Ozgina', "Ko'p — turish qiyin", 'Juda kuchli'],
      dangerAt: 2,
    ),
    _Question(
      key: 'fever',
      emoji: '🌡️',
      title: 'Isitma',
      text: 'Isitma yoki tana harorati ko\'tarilgani boryaptimi?',
      options: ["Yo'q", 'Ozgina (37–38°C)', 'Yuqori (38°C dan yuqori)'],
      dangerAt: 1,
    ),
    _Question(
      key: 'urinary_burning',
      emoji: '🔥',
      title: 'Peshob og\'rig\'i',
      text: "Peshob qilganda achishish yoki yonish bo'lyaptimi?",
      options: ["Yo'q", 'Ha — achishish bor'],
      dangerAt: 1,
    ),
  ];

  // ─── T2 savollar ─────────────────────────────────────────
  static const _t2Questions = [
    _Question(
      key: 'headache_severity',
      emoji: '🤕',
      title: 'Bosh og\'rig\'i',
      text: "Bosh og'rig'i boryaptimi?",
      options: ["Yo'q", 'Ozgina', "Kuchli — tabletkadan o'tmaydi"],
      dangerAt: 1,
    ),
    _Question(
      key: 'visual_disturbance',
      emoji: '👁️',
      title: 'Ko\'rish buzilishi',
      text: "Ko'z oldida uchish, xiralashish yoki ikki ko'rinish boryaptimi?",
      options: ["Yo'q", 'Ha — ko\'z oldida uchyapti'],
      dangerAt: 1,
    ),
    _Question(
      key: 'edema_level',
      emoji: '💧',
      title: 'Shish',
      text: 'Qo\'l, oyoq yoki yuzda shish boryaptimi?',
      options: ["Yo'q", 'Ozgina (ertalab yo\'qoladi)', "Ko'p (kechasi ham bor)", "Juda kuchli"],
      dangerAt: 2,
    ),
    _Question(
      key: 'fetal_movement',
      emoji: '👶',
      title: 'Homila harakati',
      text: 'Homilaning harakati qanday?',
      options: ['Yaxshi — odatdagidek', 'Kamaydi — sekinroq', "Deyarli yo'q — xavotirdaman"],
      dangerAt: 1,
    ),
    _Question(
      key: 'painless_bleeding',
      emoji: '🩸',
      title: 'Og\'riqsiz qon ketish',
      text: "Og'riqsiz yorqin qizil qon ketish boryaptimi?",
      options: ["Yo'q", "Ozgina dog'", "Ko'p — qon oqyapti"],
      dangerAt: 1,
    ),
    _Question(
      key: 'dizziness',
      emoji: '😴',
      title: 'Zaiflik / bosh aylanishi',
      text: 'Zaiflik yoki bosh aylanishi boryaptimi?',
      options: ["Yo'q", 'Ozgina', "Ko'p", 'Juda kuchli'],
      dangerAt: 2,
    ),
    _Question(
      key: 'sudden_weight_gain',
      emoji: '⚖️',
      title: 'Keskin vazn oshishi',
      text: 'Bir haftada 3 kg dan ko\'p vazn oshganmisiz?',
      options: ["Yo'q", 'Ha — keskin oshdi'],
      dangerAt: 1,
    ),
  ];

  // ─── T3 savollar ─────────────────────────────────────────
  static const _t3Questions = [
    _Question(
      key: 'fetal_movement_t3',
      emoji: '👶',
      title: 'Homila harakati',
      text: "Homilaning harakati qanday? (Soatiga kamida 10 ta harakat bo'lishi kerak)",
      options: ['Yaxshi — faol harakat', 'Kamaydi — sekinroq', "Deyarli yo'q — xavotirdaman"],
      dangerAt: 1,
    ),
    _Question(
      key: 'headache_severity',
      emoji: '🤕',
      title: 'Bosh og\'rig\'i',
      text: "Bosh og'rig'i boryaptimi?",
      options: ["Yo'q", 'Ozgina', "Kuchli — tabletkadan o'tmaydi"],
      dangerAt: 1,
    ),
    _Question(
      key: 'visual_disturbance',
      emoji: '👁️',
      title: 'Ko\'rish buzilishi',
      text: "Ko'z oldida uchish yoki xiralashish?",
      options: ["Yo'q", 'Ha — ko\'z oldida uchyapti'],
      dangerAt: 1,
    ),
    _Question(
      key: 'contractions',
      emoji: '🔴',
      title: 'Qorin og\'rig\'i / qisish',
      text: 'Muntazam qorin og\'rig\'i yoki qisish boryaptimi?',
      options: ["Yo'q", "Ba'zan — tartibsiz", 'Muntazam — har 10 daqiqada'],
      dangerAt: 1,
    ),
    _Question(
      key: 'bleeding_with_pain',
      emoji: '🚨',
      title: 'Qon ketish + og\'riq',
      text: "Qorin og'rig'i BILAN birga qon ketish boryaptimi?",
      options: ["Yo'q", 'Ha — ikkalasi birga bor'],
      dangerAt: 1,
    ),
    _Question(
      key: 'itching_palms_soles',
      emoji: '🖐️',
      title: 'Kaft / oyoq qichishi',
      text: 'Kaft yoki oyoq tagingiz qichishadimi?',
      options: ["Yo'q", 'Ozgina', 'Kuchli', "Juda kuchli — uxlay olmayapman"],
      dangerAt: 2,
    ),
    _Question(
      key: 'shortness_of_breath',
      emoji: '💨',
      title: 'Nafas qisishi',
      text: 'Nafas qisishi yoki ko\'krak og\'rig\'i boryaptimi?',
      options: ["Yo'q", 'Ozgina — harakat qilganda', "Kuchli — tinch turganda ham"],
      dangerAt: 1,
    ),
  ];

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final result = await ApiService().predictQuick(
        trimester: _trimester,
        age: _age,
        gestationalWeek: _gestWeek,
        vaginalBleeding: _answers['vaginal_bleeding'] ?? 0,
        headacheSeverity: _answers['headache_severity'] ?? 0,
        visualDisturbance: _answers['visual_disturbance'] ?? 0,
        fetalMovement: _answers['fetal_movement'] ?? 0,
        itchingPalmsSoles: _answers['itching_palms_soles'] ?? 0,
        anemiaLevel: _anemiaLevel,
        // Qo'shimcha featurelar
        oneSidedPain: _answers['one_sided_pain'] ?? 0,
        nauseaSeverity: _answers['nausea_severity'] ?? 0,
        dizziness: _answers['dizziness'] ?? 0,
        fever: _answers['fever'] ?? 0,
        urinaryBurning: _answers['urinary_burning'] ?? 0,
        edemaLevel: _answers['edema_level'] ?? 0,
        painlessBleeding: _answers['painless_bleeding'] ?? 0,
        suddenWeightGain: _answers['sudden_weight_gain'] ?? 0,
        fetalMovementT3: _answers['fetal_movement_t3'] ?? 0,
        contractions: _answers['contractions'] ?? 0,
        bleedingWithPain: _answers['bleeding_with_pain'] ?? 0,
        shortnessOfBreath: _answers['shortness_of_breath'] ?? 0,
        parity: _parity,
        rural: _rural ? 1 : 0,
      );

      await _saveHistory(result);

      setState(() {
        _result = result;
        _submitted = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Internet aloqasi yo\'q yoki server ishlamayapti.\nIltimos, qayta urinib ko\'ring.';
        _loading = false;
      });
    }
  }

  Future<void> _saveHistory(RiskResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyCheckHistory);
    final list = raw != null
        ? List<Map<String, dynamic>>.from(jsonDecode(raw))
        : <Map<String, dynamic>>[];

    list.add({
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'time': DateFormat('HH:mm').format(DateTime.now()),
      'trimester': _trimester,
      'risk_level': result.riskLevel,
      'emoji': result.emoji,
      'recommendation': result.recommendation,
      'triggered_risks': result.triggeredRisks,
      'predicted_class': result.predictedClass,
    });

    // Oxirgi 90 ta saqlash
    if (list.length > 90) list.removeRange(0, list.length - 90);

    await prefs.setString(AppConstants.keyCheckHistory, jsonEncode(list));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _profileLoaded
            ? (_submitted ? _buildResult() : _buildForm())
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  // ─── Forma ───────────────────────────────────────────────

  Widget _buildForm() {
    final questions = _questionsFor(_trimester);
    final trimLabel = _trimester == 'T1'
        ? '1-trimest (1–12 hafta)'
        : _trimester == 'T3'
            ? '3-trimest (27–40 hafta)'
            : '2-trimest (13–26 hafta)';

    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kunlik tekshiruv', style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
              )),
              Text(trimLabel, style: GoogleFonts.nunito(
                fontSize: 12, color: Colors.white70,
              )),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${questions.length} savol', style: GoogleFonts.nunito(
              fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
            )),
          ),
        ]),
      ),

      // Savollar ro'yxati
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(children: [
          // Tushuntirish
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Bugungi holatingizni to\'g\'ri tanlang. AI tahlil qilib, shifokorga borish kerakmi yoki yo\'qligini aytadi.',
                style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.primary,
                  fontWeight: FontWeight.w600, height: 1.4,
                ),
              )),
            ]),
          ),

          // Savollar
          ...questions.asMap().entries.map((entry) => _QuestionCard(
            question: entry.value,
            index: entry.key + 1,
            value: _answers[entry.value.key] ?? 0,
            onChanged: (v) => setState(() => _answers[entry.value.key] = v),
          )).toList(),

          const SizedBox(height: 16),

          // Xato xabar
          if (_errorMsg != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.wifi_off, color: AppColors.red, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_errorMsg!, style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.red,
                ))),
              ]),
            ),

          // Yuborish tugmasi
          _SubmitButton(loading: _loading, onTap: _submit),
          const SizedBox(height: 24),
        ]),
      )),
    ]);
  }

  // ─── Natija ──────────────────────────────────────────────

  Widget _buildResult() {
    final r = _result!;
    final isSafe = r.isLow || r.isMedium;
    return _ResultView(
      result: r,
      isSafe: isSafe,
      onClose: () => Navigator.of(context).pop(),
      onRepeat: () => setState(() {
        _submitted = false;
        _result = null;
        for (final q in _questionsFor(_trimester)) {
          _answers[q.key] = 0;
        }
      }),
    );
  }
}

// ─── Savol kartasi ───────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final _Question question;
  final int index;
  final int value;
  final void Function(int) onChanged;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecoration.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Savol
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('$index', style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(question.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(question.title, style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textGrey,
                  )),
                ]),
                const SizedBox(height: 4),
                Text(question.text, style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: AppColors.textDark, height: 1.3,
                )),
              ],
            )),
          ]),
        ),

        // Variantlar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            children: question.options.asMap().entries.map((e) {
              final idx = e.key;
              final label = e.value;
              final selected = value == idx;
              final isDanger = question.dangerAt != null && idx >= question.dangerAt!;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(idx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDanger
                            ? AppColors.red.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.1))
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? (isDanger ? AppColors.red : AppColors.primary)
                          : AppColors.divider,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? (isDanger ? AppColors.red : AppColors.primary)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : AppColors.divider,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(label, style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: selected
                          ? (isDanger ? AppColors.red : AppColors.primary)
                          : AppColors.textMedium,
                    ))),
                    if (isDanger && selected)
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.red, size: 16),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 250.ms, delay: (index * 60).ms).slideY(begin: 0.05);
  }
}

// ─── Yuborish tugmasi ────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _SubmitButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: loading ? null : AppColors.headerGradient,
          color: loading ? AppColors.divider : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16, offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5,
                  ),
                )
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🔍', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text('AI tahlil qilsin', style: GoogleFonts.nunito(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
                ]),
        ),
      ),
    );
  }
}

// ─── Natija ko'rinishi ────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final RiskResult result;
  final bool isSafe;
  final VoidCallback onClose;
  final VoidCallback onRepeat;

  const _ResultView({
    required this.result,
    required this.isSafe,
    required this.onClose,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSafe
        ? const Color(0xFFE8F5E9)
        : result.isEmergency
            ? const Color(0xFFFCE4EC)
            : const Color(0xFFFFF3E0);

    final mainColor = isSafe
        ? AppColors.green
        : result.isEmergency
            ? AppColors.emergency
            : AppColors.red;

    final bigIcon = isSafe ? '✅' : result.isEmergency ? '🚨' : '⚠️';

    final bigTitle = isSafe
        ? 'HAMMASI\nYAXSHI!'
        : result.isEmergency
            ? 'TEZKOR!\nSHIFOKORGA!'
            : 'DOKTORGA\nBORING';

    final subText = isSafe
        ? 'Hozircha xavfli belgi yo\'q.\nNavbatdagi rejali ko\'rikka boring.'
        : result.isEmergency
            ? 'Hoziroq tez yordam chaqiring\nyoki kasalxonaga boring!'
            : result.recommendation;

    return Container(
      color: bgColor,
      child: Column(children: [
        // Yuqori panel
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          color: mainColor.withValues(alpha: 0.15),
          child: Row(children: [
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: mainColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: mainColor, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Text('Tahlil natijasi', style: GoogleFonts.nunito(
              fontSize: 16, fontWeight: FontWeight.w700, color: mainColor,
            )),
          ]),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 32),

            // Katta icon
            Text(bigIcon, style: const TextStyle(fontSize: 80))
                .animate()
                .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 20),

            // Katta sarlavha
            Text(
              bigTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: mainColor,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Tavsiya
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withValues(alpha: 0.12),
                    blurRadius: 16, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                subText,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  height: 1.5,
                ),
              ),
            ).animate().fadeIn(delay: 350.ms, duration: 300.ms),

            // Aniqlangan xavflar
            if (result.triggeredRisks.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: mainColor.withValues(alpha: 0.2), width: 1.5,
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.info_outline, color: mainColor, size: 18),
                    const SizedBox(width: 8),
                    Text('Aniqlangan belgilar:', style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: mainColor,
                    )),
                  ]),
                  const SizedBox(height: 12),
                  ...result.triggeredRisks.map((risk) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: mainColor, shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(risk, style: GoogleFonts.nunito(
                        fontSize: 14, color: AppColors.textDark,
                        fontWeight: FontWeight.w600, height: 1.3,
                      ))),
                    ]),
                  )),
                ]),
              ).animate().fadeIn(delay: 450.ms, duration: 300.ms),
            ],

            // Muhimlik eslatmasi (favqulodda holatda)
            if (result.isEmergency) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.emergency.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.emergency.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(children: [
                  const Text('📞', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Tez yordam: 103\nOnalik markazi: 1058',
                    style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.emergency, height: 1.5,
                    ),
                  )),
                ]),
              ).animate().fadeIn(delay: 500.ms),
            ],

            const SizedBox(height: 32),

            // Tugmalar
            Column(children: [
              // Yopish tugmasi
              GestureDetector(
                onTap: onClose,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: isSafe
                        ? LinearGradient(colors: [
                            AppColors.green,
                            AppColors.green.withValues(alpha: 0.8),
                          ])
                        : result.isEmergency
                            ? LinearGradient(colors: [
                                AppColors.emergency,
                                AppColors.emergency.withValues(alpha: 0.8),
                              ])
                            : AppColors.headerGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: mainColor.withValues(alpha: 0.3),
                        blurRadius: 14, offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(child: Text(
                    isSafe ? '✅  Yopish' : '🏥  Tushundim',
                    style: GoogleFonts.nunito(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  )),
                ),
              ),

              const SizedBox(height: 10),

              // Qayta tekshiruv tugmasi
              GestureDetector(
                onTap: onRepeat,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Center(child: Text(
                    '🔄  Qayta tekshirish',
                    style: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  )),
                ),
              ),
            ]).animate().fadeIn(delay: 500.ms, duration: 300.ms),

            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }
}

// ─── Savol modeli ────────────────────────────────────────────

class _Question {
  final String key;
  final String emoji;
  final String title;
  final String text;
  final List<String> options;
  final int? dangerAt; // Bu indeksdan boshlab xavfli rang

  const _Question({
    required this.key,
    required this.emoji,
    required this.title,
    required this.text,
    required this.options,
    this.dangerAt,
  });
}
