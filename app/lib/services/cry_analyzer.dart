import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../core/constants.dart';

/// Model qaytaradigan klasslar.
/// V3 (3-klass): needs, discomfort, pain
/// V2 (5-klass): hungry, tired, discomfort, burping, bellyPain (eski model)
enum CryClass {
  // V3 — yangi 3-klass
  needs, discomfortBroad, pain,
  // V2 — eski 5-klass (backward compat)
  hungry, tired, discomfort, burping, bellyPain,
}

extension CryClassExt on CryClass {
  String get key => switch (this) {
    CryClass.needs           => 'needs',
    CryClass.discomfortBroad => 'discomfort',  // v3 'discomfort' kategoriyasi
    CryClass.pain            => 'pain',
    CryClass.hungry          => 'hungry',
    CryClass.tired           => 'tired',
    CryClass.discomfort      => 'discomfort_v2',
    CryClass.burping         => 'burping',
    CryClass.bellyPain       => 'belly_pain',
  };

  /// Backend'dan kelgan key bo'yicha enum topish.
  /// Backend v3 'discomfort' yuborsa → discomfortBroad ga map qilamiz.
  static CryClass? fromKey(String key, {String? version}) {
    switch (key) {
      case 'needs':       return CryClass.needs;
      case 'pain':        return CryClass.pain;
      case 'discomfort':
        // v3 contextida — broad discomfort
        return version == 'v3'
            ? CryClass.discomfortBroad
            : CryClass.discomfort;
      case 'hungry':      return CryClass.hungry;
      case 'tired':       return CryClass.tired;
      case 'burping':     return CryClass.burping;
      case 'belly_pain':  return CryClass.bellyPain;
    }
    return null;
  }
}

/// Bola yig'isi sababi — UI uchun barcha matn ma'lumotlari.
class CryReason {
  final CryClass cls;
  final String emoji;
  final String label;
  final String description;
  final String advice;

  const CryReason({
    required this.cls,
    required this.emoji,
    required this.label,
    required this.description,
    required this.advice,
  });
}

/// V3 — 3 ta keng kategoriya (model output tartibida).
const List<CryReason> kCryReasonsV3 = [
  CryReason(
    cls: CryClass.needs,
    emoji: '👶',
    label: 'Asosiy ehtiyojlar',
    description: "Och, charchagan yoki uyqu istamoqda — eng keng "
        "tarqalgan sabab.",
    advice: "Avval emizishni sinab ko'ring. Agar ovqatdan keyin bo'lsa "
        "— xona yorug'ini kamaytirib, chayqating yoki erkalang.",
  ),
  CryReason(
    cls: CryClass.discomfortBroad,
    emoji: '😣',
    label: 'Jismoniy noqulay',
    description: "Taglik nam, harorat noqulay, kiyim tor yoki ovqatdan "
        "keyin kekirish kerak bo'lishi mumkin.",
    advice: "Tagligini va kiyimini tekshiring. Xona harorati 22-24°C "
        "bo'lsin. Ovqatdan keyin tik ko'tarib, orqasini uqalang.",
  ),
  CryReason(
    cls: CryClass.pain,
    emoji: '🤒',
    label: "Og'riq yoki kasallik",
    description: "Kuchli, o'tkir yig'i. Oyoqlarini qornidagi tomon "
        "tortadi, yuzi qizaradi.",
    advice: "Qornini soat yo'nalishida asta massaj qiling. Haroratini "
        "o'lchang. Agar 30 daqiqadan ko'p davom etsa — shifokorga.",
  ),
];

/// V2 — 5 ta aniq sabab (eski model uchun, backward compat).
const List<CryReason> kCryReasons = [
  CryReason(
    cls: CryClass.hungry,
    emoji: '🍼',
    label: 'Och qolgan',
    description: "Muntazam, ritmik yig'i. Ovoz kuchayib boradi.",
    advice: "Emizib ko'ring — och qolganda yig'i tezda to'xtaydi. "
        "Oxirgi emizishdan 2-3 soat o'tgan bo'lsa, ehtimol och.",
  ),
  CryReason(
    cls: CryClass.tired,
    emoji: '😴',
    label: 'Uxlagisi kelmoqda',
    description: "Past, monoton yig'i. Ko'zlari yumiladi.",
    advice: "Xona yorug'ini kamaytiring. Chayqating yoki erkalang. "
        "Dam olish vaqti — hadeb uyg'otmang.",
  ),
  CryReason(
    cls: CryClass.discomfort,
    emoji: '💧',
    label: 'Noqulay (taglik, harorat)',
    description: "Birdan boshlanadi. Oyoqlarini qimirlatadi.",
    advice: "Tagligini, kiyimini va xona haroratini tekshiring. "
        "Quruq va toza saqlang. Tor kiyim bo'lmasin.",
  ),
  CryReason(
    cls: CryClass.burping,
    emoji: '🤱',
    label: 'Kekirish kerak',
    description: "Ovqatdan keyin bezovta, qornidagi gaz.",
    advice: "Tik ko'tarib, yelkangizga qo'yib, orqasini asta-sekin uqalang. "
        "Kekirish chiqsa, tinchlanadi.",
  ),
  CryReason(
    cls: CryClass.bellyPain,
    emoji: '🤒',
    label: "Qorin og'rig'i (gaz, kolik)",
    description: "Kuchli, o'tkir yig'i. Oyoqlarini qornidagi tomon "
        "tortadi, yuzi qizaradi.",
    advice: "Qornini soat yo'nalishida asta massaj qiling. Oyoqlarini "
        "velosiped kabi aylantiring. Davom etsa shifokorga.",
  ),
];

/// Yig'i tahlili natijasi.
class CryDetectionResult {
  final bool isCry;
  final double confidence;
  final String level; // 'high' | 'medium' | 'low'
  final double durationSec;
  final String topClass;
  /// CryClass → probability (0..1). TAXMINIY.
  final Map<CryClass, double>? predictions;
  final String? predictionsNote;
  /// Model versiyasi — qaysi sabablar listini ishlatishni hal qiladi
  final String? predictionsVersion; // 'v2' | 'v3'

  const CryDetectionResult({
    required this.isCry,
    required this.confidence,
    required this.level,
    required this.durationSec,
    required this.topClass,
    this.predictions,
    this.predictionsNote,
    this.predictionsVersion,
  });

  factory CryDetectionResult.fromJson(Map<String, dynamic> j) {
    final version = j['predictions_version'] as String?;
    Map<CryClass, double>? preds;
    final rawPreds = j['predictions'];
    if (rawPreds is Map) {
      preds = <CryClass, double>{};
      rawPreds.forEach((k, v) {
        final c = CryClassExt.fromKey(k.toString(), version: version);
        if (c != null) preds![c] = (v as num).toDouble();
      });
    }
    return CryDetectionResult(
      isCry: j['is_cry'] as bool,
      confidence: (j['confidence'] as num).toDouble(),
      level: j['level'] as String,
      durationSec: (j['duration_sec'] as num).toDouble(),
      topClass: j['top_class'] as String? ?? '',
      predictions: preds,
      predictionsNote: j['predictions_note'] as String?,
      predictionsVersion: version,
    );
  }

  int get confidencePct => (confidence * 100).round();
  bool get isHighConfidence => level == 'high';

  /// Versiyaga qarab to'g'ri reasons listni qaytaradi.
  List<CryReason> get reasonsList =>
      predictionsVersion == 'v3' ? kCryReasonsV3 : kCryReasons;

  /// Sabablarni model probability'lari bo'yicha kamayuvchi tartibda.
  List<({CryReason reason, double prob})> get sortedReasons {
    final list = reasonsList.map((r) => (
      reason: r,
      prob: predictions?[r.cls] ?? 0.0,
    )).toList();
    list.sort((a, b) => b.prob.compareTo(a.prob));
    return list;
  }
}

class CryAnalysisUnavailable implements Exception {
  final String message;
  const CryAnalysisUnavailable(this.message);
  @override
  String toString() => message;
}

class MicrophonePermissionDenied implements Exception {
  const MicrophonePermissionDenied();
  @override
  String toString() => 'Mikrofonga ruxsat berilmadi';
}

class CryAnalyzer {
  static final CryAnalyzer _instance = CryAnalyzer._internal();
  factory CryAnalyzer() => _instance;
  CryAnalyzer._internal();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.cryApiBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<bool> requestPermission() async {
    // 1) Avval record paketining native check'i (iOS uchun ishonchli)
    if (await _recorder.hasPermission()) return true;
    // 2) Agar yo'q bo'lsa permission_handler bilan so'raymiz
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    final granted = await requestPermission();
    if (!granted) throw const MicrophonePermissionDenied();

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/cry_${DateTime.now().millisecondsSinceEpoch}.wav';

    // WAV (PCM 16-bit) — backend librosa/soundfile to'g'ridan-to'g'ri o'qiydi,
    // ffmpeg kerak emas
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _currentPath = path;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    _currentPath = path;
    return path;
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
    if (_currentPath != null) {
      final f = File(_currentPath!);
      if (await f.exists()) await f.delete();
    }
    _currentPath = null;
  }

  Future<bool> get isRecording => _recorder.isRecording();

  /// Audio faylni backend YAMNet'ga yuborib, yig'i aniqlanganligini qaytaradi.
  /// Sababini bashorat qilmaydi — bu etik tanlov.
  Future<CryDetectionResult> analyze(String audioPath) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      throw const CryAnalysisUnavailable("Audio fayl topilmadi");
    }

    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioPath,
          filename: 'recording.wav',
        ),
      });

      final res = await _dio.post('/cry/detect', data: formData);
      return CryDetectionResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const CryAnalysisUnavailable(
          "Server bilan aloqa yo'q.\nInternet ulanishini tekshiring.",
        );
      }
      throw CryAnalysisUnavailable(
        "Tahlil bajarilmadi: ${e.response?.statusCode ?? e.message}",
      );
    } catch (e) {
      throw CryAnalysisUnavailable("Kutilmagan xatolik: $e");
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
