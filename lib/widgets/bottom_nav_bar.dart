import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
    const Color activeColor = Color(0xFF1F74BF);
    const Color inactiveColor = Color(0xFF9E9E9E);
    const Color bgColor = Color(0xFFFFFFFF);
    const Color borderColor = Color(0xFFEEEEEE);

    return Container(
      decoration: const BoxDecoration(
        color: bgColor, // Fondo blanco puro
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                label: 'Mensajes',
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                label: 'Vecinos',
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                label: 'Estado',
                icon: Icons.sensors_rounded,
                activeIcon: Icons.sensors_rounded,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isActive = activeIndex == index;
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTabSelected(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Icono y texto completamente libres, SIN contenedor ni rectángulo de fondo
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: color,
              ),
              const SizedBox(height: 3),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
