import 'package:flutter/material.dart';
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
      icon: '🩸',
      text: 'Qin qon ketishi yoki dog\' boryaptimi?',
      options: ['Yo\'q', 'Ozgina', 'Ko\'p'],
    ),
    _Question(
      key: 'headache_severity',
      icon: '🤕',
      text: 'Bosh og\'rig\'i boryaptimi?',
      options: ['Yo\'q', 'Ozgina', 'Kuchli (tabletkadan o\'tmaydi)'],
    ),
    _Question(
      key: 'visual_disturbance',
      icon: '👁️',
      text: 'Ko\'z oldida uchish yoki xiralashish?',
      options: ['Yo\'q', 'Ha'],
    ),
    if (widget.trimester != 'T1') _Question(
      key: 'fetal_movement',
      icon: '👶',
      text: 'Homila harakati qanday?',
      options: ['Yaxshi', 'Kamroq bo\'ldi', 'Deyarli yo\'q'],
    ),
    if (widget.trimester == 'T3') _Question(
      key: 'itching_palms_soles',
      icon: '🖐️',
      text: 'Kaft / oyoq tagingiz qichishadimi?',
      options: ['Yo\'q', 'Ozgina', 'Kuchli', 'Uxlay olmayapman'],
    ),
    _Question(
      key: 'anemia_level',
      icon: '😴',
      text: 'Zaiflik / bosh aylanishi boryaptimi?',
      options: ['Yo\'q', 'Ozgina', 'Ko\'p', 'Juda kuchli'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ..._questions.map((q) => _QuestionTile(
            question: q,
            value: _answers[q.key] ?? 0,
            onChanged: (v) => setState(() => _answers[q.key] = v),
          )),

          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: widget.loading
                  ? null
                  : () => widget.onSubmit(Map.from(_answers)),
              icon: widget.loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.analytics_outlined),
              label: Text(widget.loading ? 'Tahlil qilinmoqda...' : 'Tahlil qilish'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Question {
  final String key;
  final String icon;
  final String text;
  final List<String> options;
  const _Question({
    required this.key,
    required this.icon,
    required this.text,
    required this.options,
  });
}

class _QuestionTile extends StatelessWidget {
  final _Question question;
  final int value;
  final ValueChanged<int> onChanged;

  const _QuestionTile({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(question.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        question.options[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? Colors.white : AppColors.textGrey,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade100),
        ],
      ),
    );
  }
}
