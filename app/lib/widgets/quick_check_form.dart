import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class QuickCheckForm extends StatefulWidget {
  final String trimester;
  final bool loading;
  final void Function(Map<String, int> symptoms) onSubmit;

  const QuickCheckForm({
    super.key,
    required this.trimester,
    required this.loading,
    required this.onSubmit,
  });

  @override
  State<QuickCheckForm> createState() => _QuickCheckFormState();
}

class _QuickCheckFormState extends State<QuickCheckForm> {
  final Map<String, int> _answers = {
    'vaginal_bleeding':    0,
    'headache_severity':   0,
    'visual_disturbance':  0,
    'fetal_movement':      0,
    'itching_palms_soles': 0,
    'anemia_level':        0,
  };

  List<_Question> get _questions => [
    _Question(
      key: 'vaginal_bleeding',
      emoji: '🩸',
      text: "Qin qon ketishi yoki dog' boryaptimi?",
      options: ["Yo'q", 'Ozgina', "Ko'p"],
    ),
    _Question(
      key: 'headache_severity',
      emoji: '🤕',
      text: "Bosh og'rig'i boryaptimi?",
      options: ["Yo'q", 'Ozgina', "Kuchli (tabletkadan o'tmaydi)"],
    ),
    _Question(
      key: 'visual_disturbance',
      emoji: '👁️',
      text: "Ko'z oldida uchish yoki xiralashish?",
      options: ["Yo'q", 'Ha'],
    ),
    if (widget.trimester != 'T1') _Question(
      key: 'fetal_movement',
      emoji: '👶',
      text: 'Homila harakati qanday?',
      options: ['Yaxshi', "Kamroq bo'ldi", "Deyarli yo'q"],
    ),
    if (widget.trimester == 'T3') _Question(
      key: 'itching_palms_soles',
      emoji: '🖐️',
      text: 'Kaft / oyoq tagingiz qichishadimi?',
      options: ["Yo'q", 'Ozgina', 'Kuchli', "Uxlay olmayapman"],
    ),
    _Question(
      key: 'anemia_level',
      emoji: '😴',
      text: 'Zaiflik / bosh aylanishi boryaptimi?',
      options: ["Yo'q", 'Ozgina', "Ko'p", 'Juda kuchli'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card,
      child: Column(children: [
        ..._questions.asMap().entries.map((entry) => _QuestionTile(
          question: entry.value,
          value: _answers[entry.value.key] ?? 0,
          isLast: entry.key == _questions.length - 1,
          onChanged: (v) => setState(() => _answers[entry.value.key] = v),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: GestureDetector(
            onTap: widget.loading
                ? null
                : () => widget.onSubmit(Map.from(_answers)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                gradient: widget.loading ? null : AppColors.headerGradient,
                color: widget.loading ? AppColors.divider : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: widget.loading ? [] : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: widget.loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.analytics_outlined,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Tahlil qilish', style: GoogleFonts.nunito(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
                      ],
                    ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Question {
  final String key, emoji, text;
  final List<String> options;
  const _Question({
    required this.key, required this.emoji,
    required this.text, required this.options,
  });
}

class _QuestionTile extends StatelessWidget {
  final _Question question;
  final int value;
  final bool isLast;
  final ValueChanged<int> onChanged;

  const _QuestionTile({
    required this.question, required this.value,
    required this.isLast, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(question.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(question.text, style: GoogleFonts.nunito(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ))),
          ]),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(question.options.length, (i) {
                final selected = value == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.headerGradient : null,
                        color: selected ? null : AppColors.background,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        question.options[i],
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: selected ? Colors.white : AppColors.textMedium,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
