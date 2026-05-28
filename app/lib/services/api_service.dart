import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/risk_result.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl:        AppConstants.apiBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers:        {'Content-Type': 'application/json'},
    ),
  );

  // ─── Health check ────────────────────────────────────────
  Future<bool> isOnline() async {
    try {
      final res = await _dio.get('/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Tez bashorat (kunlik tekshiruv) ─────────────────────
  Future<RiskResult> predictQuick({
    required String trimester,
    required int age,
    required int gestationalWeek,
    double systolicBp       = 120,
    double diastolicBp      = 80,
    double heartRate        = 80,
    // Umumiy
    int vaginalBleeding     = 0,
    int headacheSeverity    = 0,
    int visualDisturbance   = 0,
    int fetalMovement       = 0,
    int itchingPalmsSoles   = 0,
    int anemiaLevel         = 0,
    // T1 xususiy
    int oneSidedPain        = 0,
    int nauseaSeverity      = 0,
    int dizziness           = 0,
    int fever               = 0,
    int urinaryBurning      = 0,
    // T2 xususiy
    int edemaLevel          = 0,
    int painlessBleeding    = 0,
    int suddenWeightGain    = 0,
    // T3 xususiy
    int fetalMovementT3     = 0,
    int contractions        = 0,
    int bleedingWithPain    = 0,
    int shortnessOfBreath   = 0,
    // Profil
    int parity              = 0,
    int rural               = 0,
    String lang             = 'uz',
  }) async {
    final res = await _dio.post('/predict/quick', data: {
      'trimester':           trimester,
      'age':                 age,
      'gestational_week':    gestationalWeek,
      'systolic_bp':         systolicBp,
      'diastolic_bp':        diastolicBp,
      'heart_rate':          heartRate,
      'vaginal_bleeding':    vaginalBleeding,
      'headache_severity':   headacheSeverity,
      'visual_disturbance':  visualDisturbance,
      'fetal_movement':      fetalMovement,
      'itching_palms_soles': itchingPalmsSoles,
      'anemia_level':        anemiaLevel,
      'one_sided_pain':      oneSidedPain,
      'nausea_severity':     nauseaSeverity,
      'dizziness':           dizziness,
      'fever':               fever,
      'urinary_burning':     urinaryBurning,
      'edema_level':         edemaLevel,
      'painless_bleeding':   painlessBleeding,
      'sudden_weight_gain':  suddenWeightGain,
      'fetal_movement_t3':   fetalMovementT3,
      'contractions':        contractions,
      'bleeding_with_pain':  bleedingWithPain,
      'shortness_of_breath': shortnessOfBreath,
      'parity':              parity,
      'rural':               rural,
      'lang':                lang,
    });
    return RiskResult.fromJson(res.data);
  }

  // ─── To'liq bashorat (forma to'ldirilgandan keyin) ───────
  Future<RiskResult> predictFull(
    Map<String, dynamic> features, {
    String lang = 'uz',
  }) async {
    final res = await _dio.post('/predict', data: {
      ...features,
      'lang': lang,
    });
    return RiskResult.fromJson(res.data);
  }

  // ─── Trimest savollari ────────────────────────────────────
  Future<Map<String, dynamic>> getQuestions(String trimester) async {
    final res = await _dio.get('/questions/$trimester');
    return res.data as Map<String, dynamic>;
  }

  // ─── Barcha xavflar ──────────────────────────────────────
  Future<Map<String, dynamic>> getAllRisks() async {
    final res = await _dio.get('/risks');
    return res.data as Map<String, dynamic>;
  }
}
