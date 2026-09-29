import 'package:flutter/material.dart';
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
      'title': '🚨 TERREMOTO',
      'steps': [
        'Protégete bajo una mesa resistente y cubre tu cabeza.',
        'Aléjate de ventanas, repisas y objetos que puedan caer.',
        'Al terminar el sismo, corta gas y luz y sal con calma al punto de encuentro.',
      ],
    },
    {
      'title': '🔥 INCENDIO',
      'steps': [
        'Avisa a bomberos y da la alarma a los vecinos inmediatamente.',
        'Desplázate agachado o gateando si hay humo denso. No uses ascensores.',
        'Reúnete en la zona segura exterior y verifica que todos estén a salvo.',
      ],
    },
    {
      'title': '🌊 TSUNAMI',
      'steps': [
        '¡EVACÚA A TERRENO ALTO INMEDIATAMENTE tras un sismo fuerte!',
        'Aléjate de la costa y sube a mínimo 30 metros de altura sobre el nivel del mar.',
        'Permanece en la zona segura hasta la cancelación oficial de la alerta.',
      ],
    },
    {
      'title': '🩹 PRIMEROS AUXILIOS',
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle y encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'GUÍA DE EMERGENCIA',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFC53030),
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Toca cada sección para ver los pasos de acción',
                      style: TextStyle(
                        fontFamily: 'Roboto',
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
                    child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Guías
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _guides.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == _guides.length) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFED7D7)),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          '📞 Teléfonos de Emergencia Oficiales (Chile)',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC53030),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '131: SAMU (Ambulancia)  •  132: Bomberos  •  133: Carabineros\n130: CONAF (Incendios Forestales)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF742A2A),
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

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isExpanded ? const Color(0xFFFFF9F9) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpanded ? AppTheme.redAlert : const Color(0xFFE2E8F0),
                      width: isExpanded ? 2 : 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        title: Text(
                          guide['title'] as String,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                        trailing: Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.redAlert,
                          size: 28,
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
                                      width: 24,
                                      height: 24,
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
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        stepText,
                                        style: const TextStyle(
                                          fontFamily: 'Roboto',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2D3748),
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
