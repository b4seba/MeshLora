import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickMessageBar extends StatelessWidget {
  final Function(String) onQuickMessageTapped;

  const QuickMessageBar({
    super.key,
    required this.onQuickMessageTapped,
  });

  static const List<Map<String, dynamic>> _quickItems = [
    {
      'text': '¡ESTOY BIEN!',
      'color': AppTheme.lime,
      'isUrgent': false,
    },
    {
      'text': 'NECESITO AYUDA',
      'color': AppTheme.redAlert,
      'isUrgent': true,
    },
    {
      'text': '¿DÓNDE ESTÁN?',
      'color': AppTheme.navy,
      'isUrgent': false,
    },
    {
      'text': 'PUNTO DE ENCUENTRO',
      'color': Color(0xFFF39C12),
      'isUrgent': false,
    },
    {
      'text': 'HAY AGUA DISPONIBLE',
      'color': Color(0xFF3498DB),
      'isUrgent': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _quickItems[index];
          final text = item['text'] as String;
          final color = item['color'] as Color;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onQuickMessageTapped(text),
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
