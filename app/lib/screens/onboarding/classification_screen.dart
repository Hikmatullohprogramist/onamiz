import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class ClassificationScreen extends StatefulWidget {
  const ClassificationScreen({super.key});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  UserType? _selected;

  final _options = [
    _Option(
      type:    UserType.pregnant,
      emoji:   '🤰',
      title:   'Homiladorman',
      subtitle: 'Trimestimga mos xavflarni kuzatish',
      enabled: true,
    ),
    _Option(
      type:    UserType.postpartum,
      emoji:   '👶',
      title:   "Chaqalog'im bor",
      subtitle: "Tug'ruqdan keyingi holat va depressiya skriningi",
      enabled: true,
    ),
    _Option(
      type:    UserType.planning,
      emoji:   '📋',
      title:   'Rejalashtiraman',
      subtitle: 'Keyingi versiyada — tez orada',
      enabled: false,  // ← disabled
    ),
  ];

  Future<void> _onContinue() async {
    if (_selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserType, _selected!.name);
    await prefs.setBool(AppConstants.keyOnboardingDone, false);

    if (!mounted) return;
    switch (_selected!) {
      case UserType.pregnant:
        context.go('/onboarding/pregnancy-setup');
      case UserType.postpartum:
        context.go('/onboarding/postpartum-setup');
      case UserType.planning:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Logo + sarlavha
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🌸', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Onamiz',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sizning holatingizni tanlang',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Variantlar
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _OptionCard(
                    option:   _options[i],
                    selected: _selected == _options[i].type,
                    onTap:    _options[i].enabled
                        ? () => setState(() => _selected = _options[i].type)
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Davom etish tugmasi
              ElevatedButton(
                onPressed: _selected != null ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selected != null
                      ? AppColors.primary
                      : AppColors.textGrey,
                ),
                child: const Text('Davom etish'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Option model ─────────────────────────────────────────────
class _Option {
  final UserType type;
  final String emoji;
  final String title;
  final String subtitle;
  final bool enabled;
  const _Option({
    required this.type,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });
}

// ─── Option card widget ───────────────────────────────────────
class _OptionCard extends StatelessWidget {
  final _Option option;
  final bool selected;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = option.enabled;
    final borderColor = selected
        ? AppColors.primary
        : enabled
            ? Colors.grey.shade200
            : Colors.grey.shade200;
    final bgColor = selected
        ? AppColors.primaryLight
        : enabled
            ? Colors.white
            : Colors.grey.shade50;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              option.emoji,
              style: TextStyle(
                fontSize: 36,
                color: enabled ? null : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? AppColors.textDark
                              : AppColors.textGrey,
                        ),
                      ),
                      if (!enabled) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tez orada',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: enabled
                          ? AppColors.textGrey
                          : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary),
            if (!selected && enabled)
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            if (!enabled)
              Icon(Icons.lock_outline, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}
