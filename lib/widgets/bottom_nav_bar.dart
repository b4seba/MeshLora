import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEDF2F7), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                label: 'Mensajes',
                icon: Icons.chat_bubble_rounded,
              ),
              _buildNavItem(
                index: 1,
                label: 'Vecinos',
                icon: Icons.people_alt_rounded,
              ),
              _buildNavItem(
                index: 2,
                label: 'Estado',
                icon: Icons.sensors_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isActive = activeIndex == index;
    final color = isActive ? AppTheme.orange : const Color(0xFFA0AEC0);

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        splashColor: AppTheme.orange.withAlpha(20),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            if (isActive)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.orange,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
