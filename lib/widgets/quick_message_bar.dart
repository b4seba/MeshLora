import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../theme/app_theme.dart';

class QuickMessageBar extends StatelessWidget {
  final Function(String) onQuickMessageTapped;

  const QuickMessageBar({
    super.key,
    required this.onQuickMessageTapped,
  });

  static const List<Map<String, dynamic>> _quickItems = [
    {
      'text': '¡Estoy bien!',
      'color': AppTheme.onlineGreen,
      'bg': AppTheme.onlineGreenLight,
      'icon': Icons.check_circle_outline_rounded,
      'isUrgent': false,
    },
    {
      'text': 'Necesito ayuda',
      'color': AppTheme.redAlert,
      'bg': AppTheme.redAlertLight,
      'icon': Icons.warning_amber_rounded,
      'isUrgent': true,
    },
    {
      'text': '¿Dónde están?',
      'color': AppTheme.obsidian,
      'bg': Color(0xFFF1F5F9),
      'icon': Icons.help_outline_rounded,
      'isUrgent': false,
    },
    {
      'text': 'Punto de encuentro',
      'color': Color(0xFFD97706),
      'bg': Color(0xFFFFFBEB),
      'icon': Icons.place_rounded,
      'isUrgent': false,
    },
    {
      'text': 'Hay agua disponible',
      'color': AppTheme.electricBlue,
      'bg': AppTheme.electricBlueLight,
      'icon': Icons.water_drop_outlined,
      'isUrgent': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickItems.length,
        separatorBuilder: (context, index) => const Gap(8),
        itemBuilder: (context, index) {
          final item = _quickItems[index];
          final text = item['text'] as String;
          Color color = item['color'] as Color;
          Color bg = item['bg'] as Color;
          final icon = item['icon'] as IconData;

          if (isDark) {
            if (color == AppTheme.obsidian) {
              color = AppTheme.textPrimaryDark;
              bg = AppTheme.obsidianCard;
            } else if (color == AppTheme.onlineGreen) {
              bg = AppTheme.onlineGreen.withAlpha(35);
            } else if (color == AppTheme.redAlert) {
              bg = AppTheme.redAlert.withAlpha(35);
            } else if (color == AppTheme.electricBlue) {
              bg = AppTheme.electricBlue.withAlpha(35);
            } else {
              bg = const Color(0xFFD97706).withAlpha(35);
            }
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onQuickMessageTapped(text);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? color.withAlpha(90) : color.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const Gap(6),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

