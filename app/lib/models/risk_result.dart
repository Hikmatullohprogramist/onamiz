class RiskResult {
  final String riskLevel;
  final String color;
  final String emoji;
  final String recommendation;
  final Map<String, double> probabilities;
  final String predictedClass;
  final double modelAccuracy;
  final List<String> triggeredRisks;
  final String version;

  const RiskResult({
    required this.riskLevel,
    required this.color,
    required this.emoji,
    required this.recommendation,
    required this.probabilities,
    required this.predictedClass,
    required this.modelAccuracy,
    required this.triggeredRisks,
    required this.version,
  });

  factory RiskResult.fromJson(Map<String, dynamic> json) => RiskResult(
    riskLevel:      json['risk_level'] ?? 'yashil',
    color:          json['color'] ?? '#4CAF50',
    emoji:          json['emoji'] ?? '🟢',
    recommendation: json['recommendation'] ?? '',
    probabilities:  Map<String, double>.from(
      (json['probabilities'] ?? {}).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
    ),
    predictedClass: json['predicted_class'] ?? 'low',
    modelAccuracy:  (json['model_accuracy'] as num?)?.toDouble() ?? 0.0,
    triggeredRisks: List<String>.from(json['triggered_risks'] ?? []),
    version:        json['version'] ?? 'v4',
  );

  bool get isEmergency => riskLevel == 'favqulodda';
  bool get isHigh      => riskLevel == 'qizil';
  bool get isMedium    => riskLevel == 'sariq';
  bool get isLow       => riskLevel == 'yashil';

  String get riskLabelUz {
    switch (riskLevel) {
      case 'favqulodda': return 'FAVQULODDA';
      case 'qizil':      return 'YUQORI XAVF';
      case 'sariq':      return 'DIQQAT';
      case 'yashil':     return 'XAVFSIZ';
      default:           return 'NOMA\'LUM';
    }
  }
}
