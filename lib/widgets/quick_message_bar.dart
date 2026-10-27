import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

/// Barra de acciones rápidas resiliente al escalado de texto (Accesibilidad).
/// Cumple con:
/// - Eliminación de altura fija (cero SizedBox(height: 48)).
/// - Ajuste dinámico de altura y expansión en múltiples líneas (Flexible + softWrap).
/// - Fondo blanco puro (#FFFFFF) y textos/iconos en #1F74BF.
class QuickMessageBar extends StatelessWidget {
  final Function(String) onQuickMessageTapped;

  const QuickMessageBar({
    super.key,
    required this.onQuickMessageTapped,
  });

  static const List<Map<String, dynamic>> _quickItems = [
    {
      'text': '¡Estoy bien!',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'text': 'Necesito ayuda',
      'icon': Icons.emergency_outlined,
    },
    {
      'text': '¿Dónde están?',
      'icon': Icons.help_outline_rounded,
    },
    {
      'text': 'Punto de encuentro',
      'icon': Icons.place_outlined,
    },
    {
      'text': 'Hay agua disponible',
      'icon': Icons.water_drop_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color brandPrimary = Color(0xFF1F74BF);
    // Modo Claro garantizado (#FFFFFF en contenedores sobre fondo #F2F2F2)
    const Color buttonBg = Color(0xFFFFFFFF);

    // Sin altura fija rígida: el contenedor se adapta dinámicamente al texto escalado
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < _quickItems.length; i++) ...[
            if (i > 0) const Gap(8),
            _buildQuickChip(
              text: _quickItems[i]['text'] as String,
              icon: _quickItems[i]['icon'] as IconData,
              brandPrimary: brandPrimary,
              buttonBg: buttonBg,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String text,
    required IconData icon,
    required Color brandPrimary,
    required Color buttonBg,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onQuickMessageTapped(text);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          // Altura mínima accesible de 48dp, pero expandible dinámicamente sin límite superior rígido
          constraints: const BoxConstraints(
            minHeight: 48,
            maxWidth: 220, // Permite que textos largos como 'Punto de encuentro' o 'Hay agua disponible' salten de línea
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: buttonBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0x331F74BF), // #1F74BF al 20%
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000), // Opacidad sutil 0.04
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: brandPrimary),
              const Gap(8),
              // Flexible con softWrap: true permite que los botones se expandan en múltiples líneas sin overflow
              Flexible(
                child: Text(
                  text,
                  softWrap: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: brandPrimary,
                    letterSpacing: -0.1,
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
