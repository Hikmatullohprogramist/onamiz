import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/risk_result.dart';

class RiskCard extends StatelessWidget {
  final RiskResult result;
  const RiskCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final bgColor     = AppColors.riskLightColor(result.riskLevel);
    final borderColor = AppColors.riskColor(result.riskLevel);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Emoji + daraja
          Row(
            children: [
              Text(result.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.riskLabelUz,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: borderColor,
                    ),
                  ),
                  Text(
                    'Aniqlik: ${(result.modelAccuracy * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tavsiya
          Text(
            result.recommendation,
            style: TextStyle(
              fontSize: 15,
              fontWeight: result.isEmergency || result.isHigh
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: AppColors.textDark,
            ),
          ),

          // Trigger bo'lgan xavflar
          if (result.triggeredRisks.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Aniqlangan belgilar:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 6),
            ...result.triggeredRisks.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: borderColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(r,
                          style: const TextStyle(fontSize: 13,
                              color: AppColors.textDark)),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Ehtimollar
          const SizedBox(height: 14),
          _ProbabilityBar(probabilities: result.probabilities),
        ],
      ),
    );
  }
}

class _ProbabilityBar extends StatelessWidget {
  final Map<String, double> probabilities;
  const _ProbabilityBar({required this.probabilities});

  static const _labels = {
    'low':       ('🟢', 'Xavfsiz'),
    'medium':    ('🟡', 'Diqqat'),
    'high':      ('🔴', 'Yuqori'),
    'emergency': ('🚨', 'Favqulodda'),
  };

  @override
  Widget build(BuildContext context) {
    final sorted = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ehtimollar:',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        ...sorted.map((e) {
          final info = _labels[e.key];
          final pct  = (e.value * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(info?.$1 ?? '', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 64,
                  child: Text(
                    info?.$2 ?? e.key,
                    style: const TextStyle(fontSize: 11,
                        color: AppColors.textGrey),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                          AppColors.riskColor(
                            e.key == 'low' ? 'yashil'
                            : e.key == 'medium' ? 'sariq'
                            : e.key == 'high' ? 'qizil'
                            : 'favqulodda',
                          )),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('$pct%',
                    style: const TextStyle(fontSize: 11,
                        color: AppColors.textGrey)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
