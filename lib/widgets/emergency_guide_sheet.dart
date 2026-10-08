import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../theme/app_theme.dart';

class EmergencyGuideSheet extends StatefulWidget {
  const EmergencyGuideSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EmergencyGuideSheet(),
    );
  }

  @override
  State<EmergencyGuideSheet> createState() => _EmergencyGuideSheetState();
}

class _EmergencyGuideSheetState extends State<EmergencyGuideSheet> {
  int? _expandedIndex;

  static const List<Map<String, dynamic>> _guides = [
    {
      'title': 'Terremoto / Sismo Fuerte',
      'icon': Icons.vibration_rounded,
      'steps': [
        'Protégete bajo una mesa resistente y cubre tu cabeza.',
        'Aléjate de ventanas, repisas y objetos que puedan caer.',
        'Al terminar el sismo, corta gas y luz y sal con calma a la zona segura.',
      ],
    },
    {
      'title': 'Incendio Forestal / Estructural',
      'icon': Icons.local_fire_department_rounded,
      'steps': [
        'Avisa a bomberos y da la alarma a los vecinos inmediatamente.',
        'Desplázate agachado o gateando si hay humo denso. No uses ascensores.',
        'Reúnete en la zona segura exterior y verifica que todos estén a salvo.',
      ],
    },
    {
      'title': 'Tsunami / Evacuación Costera',
      'icon': Icons.tsunami_rounded,
      'steps': [
        '¡Evacúa a terreno alto inmediatamente tras un sismo que dificulte mantenerse en pie!',
        'Aléjate de la costa y sube a mínimo 30 metros de altura sobre el nivel del mar.',
        'Permanece en la zona segura hasta la cancelación oficial de la alerta.',
      ],
    },
    {
      'title': 'Primeros Auxilios Básicos',
      'icon': Icons.medical_services_rounded,
      'steps': [
        'Hemorragia: presiona la herida con tela o compresa limpia sin soltar.',
        'Inconsciente que respira: colócalo de costado (posición lateral de seguridad).',
        'Paro cardiorrespiratorio: inicia RCP (30 compresiones torácicas x 2 ventilaciones).',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle y encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Guía de Emergencia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.redAlert,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Gap(2),
                        Text(
                          'Protocolos de acción ante desastres y primeros auxilios',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de Guías
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _guides.length + 1,
              separatorBuilder: (context, index) => const Gap(10),
              itemBuilder: (context, index) {
                if (index == _guides.length) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.redAlertLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '📞 Teléfonos de Emergencia Oficiales (Chile)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.redAlertDark,
                          ),
                        ),
                        Gap(8),
                        Text(
                          '131: SAMU (Ambulancia)  •  132: Bomberos  •  133: Carabineros\n130: CONAF (Incendios Forestales)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF991B1B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final guide = _guides[index];
                final isExpanded = _expandedIndex == index;
                final steps = guide['steps'] as List<String>;
                final icon = guide['icon'] as IconData;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isExpanded ? const Color(0xFFFEF2F2) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpanded ? AppTheme.redAlert : AppTheme.borderSubtle,
                      width: isExpanded ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isExpanded ? Colors.white : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: AppTheme.redAlert, size: 20),
                        ),
                        title: Text(
                          guide['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        trailing: Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: isExpanded ? AppTheme.redAlert : AppTheme.textSubtle,
                          size: 20,
                        ),
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: steps.asMap().entries.map((entry) {
                              final stepIndex = entry.key + 1;
                              final stepText = entry.value;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.redAlert,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$stepIndex',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Gap(10),
                                    Expanded(
                                      child: Text(
                                        stepText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textDark,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

