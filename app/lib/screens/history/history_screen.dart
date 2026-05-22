import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyCheckHistory);
    setState(() {
      if (raw != null) {
        final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
        _history = list.reversed.toList();
      }
      _loading = false;
    });
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final todayStr  = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterStr = DateFormat('yyyy-MM-dd').format(
        DateTime.now().subtract(const Duration(days: 1)));
    if (dateStr == todayStr)  return 'Bugun';
    if (dateStr == yesterStr) return 'Kecha';
    return DateFormat('d-MMMM', 'uz').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        // App bar
        SliverAppBar(
          pinned: true,
          expandedHeight: 110,
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: Text('Tarix', style: GoogleFonts.nunito(
              fontSize: 22, fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            )),
            expandedTitleScale: 1.2,
          ),
          actions: [
            if (_history.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_history.length} ta', style: GoogleFonts.nunito(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )),
                )),
              ),
          ],
        ),

        if (_loading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_history.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final entry = _history[i];
                  final showDateHeader = i == 0 ||
                      _history[i - 1]['date'] != entry['date'];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDateHeader) ...[
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 20, bottom: 8),
                          child: Text(
                            _formatDate(entry['date'] as String),
                            style: GoogleFonts.nunito(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                      ],
                      _HistoryItem(entry: entry)
                          .animate()
                          .fadeIn(delay: (i * 40).ms, duration: 300.ms)
                          .slideX(begin: 0.04, end: 0),
                      const SizedBox(height: 10),
                    ],
                  );
                },
                childCount: _history.length,
              ),
            ),
          ),
      ]),
    );
  }
}

// ─── History item ─────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _HistoryItem({required this.entry});

  static const _labels = {
    'yashil':     'Xavfsiz',
    'sariq':      'Diqqat',
    'qizil':      'Yuqori xavf',
    'favqulodda': 'Favqulodda',
  };

  static const _sublabels = {
    'yashil':     'Hamma narsa yaxshi',
    'sariq':      'Shifokorga murojaat qiling',
    'qizil':      'Tezda yordam oling',
    'favqulodda': 'Darhol tez yordam chaqiring',
  };

  @override
  Widget build(BuildContext context) {
    final risk       = entry['risk'] as String;
    final emoji      = entry['emoji'] as String;
    final color      = AppColors.riskColor(risk);
    final lightColor = AppColors.riskLightColor(risk);
    final label      = _labels[risk] ?? risk;
    final sublabel   = _sublabels[risk] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
        // Color stripe
        Container(
          width: 4, height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 14),
        // Emoji badge
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: lightColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: Text(emoji,
              style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        // Text
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.nunito(
              fontSize: 16, fontWeight: FontWeight.w800, color: color,
            )),
            const SizedBox(height: 2),
            Text(sublabel, style: GoogleFonts.nunito(
              fontSize: 12, color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
            )),
          ],
        )),
        // Risk level dot
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4),
                  blurRadius: 6, spreadRadius: 1),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110, height: 110,
            decoration: const BoxDecoration(
              gradient: AppColors.softPinkGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('📋', style: TextStyle(fontSize: 50))),
          ).animate().scale(
              begin: const Offset(0.6, 0.6),
              duration: 450.ms,
              curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text("Hali tekshiruv yo'q", style: GoogleFonts.nunito(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          )),
          const SizedBox(height: 10),
          Text(
            "Kunlik tekshiruvdan o'tganingizda\nnatijalar bu yerda ko'rinadi",
            style: GoogleFonts.nunito(
              fontSize: 14, color: AppColors.textMedium, height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
