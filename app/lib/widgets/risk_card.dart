import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/risk_result.dart';

class RiskCard extends StatelessWidget {
  final RiskResult result;
  const RiskCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.riskColor(result.riskLevel);
    final lightColor = AppColors.riskLightColor(result.riskLevel);

    return Container(
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header strip
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: Text(result.emoji,
                  style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahlil natijasi', style: GoogleFonts.nunito(
                  fontSize: 12, color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 3),
                Text(result.riskLabelUz, style: GoogleFonts.nunito(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color,
                )),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${(result.modelAccuracy * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color,
                ),
              ),
            ),
          ]),
        ),

        // Recommendation
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Text(result.recommendation, style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: result.isEmergency || result.isHigh
                ? FontWeight.w700
                : FontWeight.w500,
            color: AppColors.textDark, height: 1.5,
          )),
        ),

        // Triggered risks
        if (result.triggeredRisks.isNotEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: color.withValues(alpha: 0.15)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aniqlangan belgilar:', style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                )),
                const SizedBox(height: 8),
                ...result.triggeredRisks.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r, style: GoogleFonts.nunito(
                      fontSize: 13, color: AppColors.textMedium,
                      fontWeight: FontWeight.w500,
                    ))),
                  ]),
                )),
              ],
            ),
          ),
        ],

        // Probability bars
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: _ProbBars(probabilities: result.probabilities),
        ),
      ]),
    );
  }
}

class _ProbBars extends StatelessWidget {
  final Map<String, double> probabilities;
  const _ProbBars({required this.probabilities});

  static const _info = {
    'low':       ('🟢', 'Xavfsiz',      AppColors.green),
    'medium':    ('🟡', 'Diqqat',       AppColors.yellow),
    'high':      ('🔴', "Yuqori xavf",  AppColors.red),
    'emergency': ('🚨', 'Favqulodda',   AppColors.emergency),
  };

  @override
  Widget build(BuildContext context) {
    final sorted = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Ehtimollar:', style: GoogleFonts.nunito(
        fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w700,
      )),
      const SizedBox(height: 10),
      ...sorted.map((e) {
        final info = _info[e.key];
        final pct = (e.value * 100).toStringAsFixed(1);
        final barColor = info?.$3 ?? AppColors.primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Text(info?.$1 ?? '', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Text(info?.$2 ?? e.key, style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              )),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: e.value,
                  minHeight: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              child: Text('$pct%', style: GoogleFonts.nunito(
                fontSize: 11, color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ), textAlign: TextAlign.right),
            ),
          ]),
        );
      }),
    ]);
  }
}
