import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/neighbor_node.dart';
import '../providers/mesh_provider.dart';
import '../widgets/demo_sheet.dart';
import '../widgets/map_view_widget.dart';
import '../widgets/mesh_logo.dart';

/// ============================================================================
/// PANTALLA: VECINOS (LISTA DE NODOS LORA)
/// ============================================================================
/// Estándar: Ultra-minimalista, limpio y empresarial (estilo iOS Settings / Dashboard).
/// - Cero avatares multicolores: Contenedores 40x40, borderRadius 10px, fondo #183B59, texto blanco.
/// - Cero tarjetas flotantes: ListView.separated sobre fondo blanco continuo con divisor ultrafino.
/// - Indicador de estado: Punto verde brillante de 8x8px con texto 'Activo' en #757575 (fontSize: 12).
/// - Selector Lista/Mapa: Contenedor gris #F2F2F2 con borde interno de 4px, activo en #FFFFFF y #1F74BF.
/// ============================================================================

class NeighborsScreen extends StatelessWidget {
  const NeighborsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandPrimary = Color(0xFF1F74BF);
    const Color brandDark = Color(0xFF183B59);
    const Color textMuted = Color(0xFF757575);
    const Color onlineGreen = Color(0xFF10B981);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MeshProvider>();
    final neighbors = provider.neighbors;
    final activeCount = neighbors.where((n) => n.isActive).length;
    final isMap = provider.isMapView;

    final Color bgColor = isDark ? brandDark : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 20,
        elevation: 0,
        backgroundColor: bgColor,
        title: Row(
          children: [
            const MeshLogo(
              height: 32,
              fit: BoxFit.contain,
              borderRadius: 6,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nodos en Malla',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : brandDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Gap(2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: activeCount > 0 ? onlineGreen : textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        activeCount > 0
                            ? '$activeCount activos en rango'
                            : 'Buscando nodos...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Selector visual discreto y accesible de tamaño de texto (A- y A+)
          Container(
            height: 34,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0x22183B59)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.decreaseTextScale();
                  },
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(17)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    child: Text(
                      'A-',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: brandDark,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 16, color: const Color(0x22183B59)),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.increaseTextScale();
                  },
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(17)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    child: Text(
                      'A+',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: brandDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(4),

          // Botón Demo & Vistas
          IconButton(
            tooltip: 'Modo Demo',
            onPressed: () {
              HapticFeedback.lightImpact();
              showDemoNavigationModal(context);
            },
            icon: const Icon(Icons.bolt_rounded, size: 20, color: onlineGreen),
          ),
          // Botón Sincronizar
          IconButton(
            tooltip: 'Sincronizar Malla',
            onPressed: () async {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronizando nodos vecinos de la malla LoRa...'),
                  duration: Duration(milliseconds: 900),
                  backgroundColor: brandDark,
                ),
              );
              await provider.refreshAllData();
            },
            icon: Icon(
              Icons.sync_rounded,
              size: 20,
              color: isDark ? Colors.white : brandDark,
            ),
          ),
          const Gap(12),
        ],
        // ====================================================================
        // SELECTOR SUPERIOR (LISTA / MAPA) - ESTILO EMPRESARIAL CONTENEDOR #F2F2F2
        // ====================================================================
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0x3348B0D9) : const Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(4), // Borde interno de 4px
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF122C43) : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildSegmentButton(
                    isDark: isDark,
                    label: 'Lista de Nodos',
                    icon: Icons.format_list_bulleted_rounded,
                    isActive: !isMap,
                    brandPrimary: brandPrimary,
                    textMuted: textMuted,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      provider.setMapView(false);
                    },
                  ),
                  _buildSegmentButton(
                    isDark: isDark,
                    label: 'Vista de Mapa',
                    icon: Icons.map_outlined,
                    isActive: isMap,
                    brandPrimary: brandPrimary,
                    textMuted: textMuted,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      provider.setMapView(true);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshAllData(),
        color: brandPrimary,
        backgroundColor: isDark ? const Color(0xFF122C43) : Colors.white,
        child: isMap
            ? MapViewWidget(
                neighbors: neighbors,
                userName: provider.userName,
                zoom: provider.mapZoom,
                onZoomIn: provider.zoomIn,
                onZoomOut: provider.zoomOut,
              )
            : neighbors.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF122C43) : const Color(0xFFF7F7F7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.radar_rounded,
                                  size: 28,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                              const Gap(16),
                              Text(
                                'Buscando Nodos en la Malla',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : brandDark,
                                ),
                              ),
                              const Gap(8),
                              Text(
                                'Enciende tu segunda antena WisBlock para que se descubra automáticamente por radiofrecuencia a 915 MHz.\n\nDesliza hacia abajo para refrescar.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                // ============================================================
                // LISTA CONTINUA LIMPIA (SIN CARDS FLOTANTES NI SOMBRAS)
                // ============================================================
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: neighbors.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      indent: 76, // Alineado con el inicio del texto tras el avatar
                      endIndent: 20,
                      color: const Color(0x339E9E9E), // Divisor ultra fino
                    ),
                    itemBuilder: (context, index) {
                      final node = neighbors[index];
                      return _buildNeighborRow(
                        context: context,
                        node: node,
                        isDark: isDark,
                        brandDark: brandDark,
                        textMuted: textMuted,
                        onlineGreen: onlineGreen,
                      );
                    },
                  ),
      ),
    );
  }

  /// Segmented button ultra-limpio sin sombras genéricas
  Widget _buildSegmentButton({
    required bool isDark,
    required String label,
    required IconData icon,
    required bool isActive,
    required Color brandPrimary,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF183B59) : Colors.white) // Fondo blanco puro cuando activo
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? brandPrimary : textMuted,
              ),
              const Gap(6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? brandPrimary : textMuted,
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

  /// Fila de nodo limpia (Tipo iOS Settings, CERO Cards, CERO colores aleatorios)
  Widget _buildNeighborRow({
    required BuildContext context,
    required NeighborNode node,
    required bool isDark,
    required Color brandDark,
    required Color textMuted,
    required Color onlineGreen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Avatar: 40x40 con borderRadius 10, estrictamente #183B59 y texto blanco puro
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF183B59), // Estrictamente #183B59
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    node.initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Gap(14),

              // Información del Nodo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            node.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : brandDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (node.isMe) ...[
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F74BF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Mi Radio',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(2),
                    Text(
                      '${node.id} · ${node.distance}${node.snr != null ? ' · SNR: ${node.snr!.toStringAsFixed(1)} dB' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicador de Estado Minimalista: Punto de 8x8px + texto 'Activo' en #757575
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: node.isActive ? onlineGreen : const Color(0xFF9E9E9E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    node.isActive ? 'Activo' : 'Sin señal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF757575), // Estrictamente #757575
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
