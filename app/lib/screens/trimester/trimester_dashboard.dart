import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../models/risk_result.dart';
import '../../widgets/risk_card.dart';
import '../../widgets/quick_check_form.dart';

class TrimesterDashboard extends StatefulWidget {
  const TrimesterDashboard({super.key});

  @override
  State<TrimesterDashboard> createState() => _TrimesterDashboardState();
}

class _TrimesterDashboardState extends State<TrimesterDashboard> {
  final _api = ApiService();

  int    _week      = 18;
  int    _age       = 28;
  String _trimester = 'T2';
  bool   _rural     = false;
  bool   _loading   = false;
  RiskResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _week      = prefs.getInt(AppConstants.keyGestWeek) ?? 18;
      _age       = prefs.getInt(AppConstants.keyUserAge) ?? 28;
      _trimester = prefs.getString(AppConstants.keyTrimester) ?? 'T2';
      _rural     = prefs.getBool(AppConstants.keyRural) ?? false;
    });
  }

  Future<void> _quickCheck(Map<String, int> symptoms) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _api.predictQuick(
        trimester:         _trimester,
        age:               _age,
        gestationalWeek:   _week,
        vaginalBleeding:   symptoms['vaginal_bleeding']    ?? 0,
        headacheSeverity:  symptoms['headache_severity']   ?? 0,
        visualDisturbance: symptoms['visual_disturbance']  ?? 0,
        fetalMovement:     symptoms['fetal_movement']      ?? 0,
        itchingPalmsSoles: symptoms['itching_palms_soles'] ?? 0,
        anemiaLevel:       symptoms['anemia_level']        ?? 0,
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = 'Server bilan aloqa yo\'q. Internetni tekshiring.');
    } finally {
      setState(() => _loading = false);
    }
  }

  String get _trimesterLabel {
    switch (_trimester) {
      case 'T1': return '1-trimest';
      case 'T2': return '2-trimest';
      case 'T3': return '3-trimest';
      default:   return _trimester;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onamiz 🌸'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Hafta + trimest info
            _WeekCard(week: _week, trimester: _trimesterLabel),
            const SizedBox(height: 20),

            // Natija kartasi (agar bor bo'lsa)
            if (_result != null) ...[
              RiskCard(result: _result!),
              const SizedBox(height: 20),
            ],

            // Xato
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: AppColors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: AppColors.red))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Tez tekshiruv formasi
            Text('Bugungi holatingiz',
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            QuickCheckForm(
              trimester: _trimester,
              loading:   _loading,
              onSubmit:  _quickCheck,
            ),

            const SizedBox(height: 24),

            // To'liq tekshiruv
            OutlinedButton.icon(
              onPressed: () => context.push('/full-check'),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('To\'liq tekshiruv (39 savol)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Hafta kartasi ────────────────────────────────────────────
class _WeekCard extends StatelessWidget {
  final int week;
  final String trimester;
  const _WeekCard({required this.week, required this.trimester});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$week-hafta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  trimester,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Text('🤰', style: TextStyle(fontSize: 56)),
        ],
      ),
    );
  }
}
