import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../models/neighbor_node.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/map_view_widget.dart';
import '../widgets/mesh_logo.dart';

class NeighborsScreen extends StatelessWidget {
  const NeighborsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MeshProvider>();
    final neighbors = provider.neighbors;
    final activeCount = neighbors.where((n) => n.isActive).length;
    final isMap = provider.isMapView;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: isDark ? AppTheme.obsidian : Colors.white,
        title: Row(
          children: [
            const MeshLogo(
              height: 38,
              fit: BoxFit.contain,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nodos',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                    ),
                  ),
                  const Gap(2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: activeCount > 0 ? AppTheme.onlineGreen : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
                          shape: BoxShape.circle,
                          boxShadow: activeCount > 0
                              ? [
                                  BoxShadow(
                                    color: AppTheme.onlineGreen.withAlpha(100),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const Gap(6),
                      Flexible(
                        child: Text(
                          activeCount > 0
                              ? '$activeCount nodos activos en la malla'
                              : 'Buscando nodos en rango...',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: activeCount > 0 ? AppTheme.onlineGreen : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
                          ),
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
          Tooltip(
            message: 'Sincronizar Nodos',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sincronizando nodos vecinos de la malla LoRa...'),
                      duration: Duration(milliseconds: 900),
                      backgroundColor: AppTheme.obsidian,
                    ),
                  );
                  await provider.refreshAllData();
                },
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.obsidianElevated : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                  ),
                ),
              ),
            ),
          ),
          const Gap(14),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.obsidian : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppTheme.borderDark : const Color(0xFFE2E8F0), width: 1)),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.obsidianElevated : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildSegmentButton(
                    isDark: isDark,
                    label: 'Lista',
                    icon: Icons.format_list_bulleted_rounded,
                    isActive: !isMap,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      provider.setMapView(false);
                    },
                  ),
                  _buildSegmentButton(
                    isDark: isDark,
                    label: 'Mapa',
                    icon: Icons.map_outlined,
                    isActive: isMap,
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
        color: AppTheme.electricBlue,
        backgroundColor: isDark ? AppTheme.obsidianCard : Colors.white,
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
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.obsidianCard : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
                                ),
                                child: Icon(
                                  Icons.radar_rounded,
                                  size: 40,
                                  color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
                                ),
                              ),
                              const Gap(18),
                              Text(
                                'Buscando Nodos en la Malla',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
                                ),
                              ),
                              const Gap(8),
                              Text(
                                'Enciende tu segunda antena WisBlock RAK4630 con Meshtastic para que se descubra automáticamente por radiofrecuencia a 915 MHz.\n\nDesliza hacia abajo para refrescar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: neighbors.length,
                    separatorBuilder: (context, index) => const Gap(8),
                    itemBuilder: (context, index) {
                      final node = neighbors[index];
                      return _buildNeighborCard(context, node, isDark).animate().fadeIn(duration: 150.ms).slideY(begin: 0.05, end: 0);
                    },
                  ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required bool isDark,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? (isDark ? AppTheme.obsidianCard : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 8),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive
                    ? (isDark ? AppTheme.textPrimaryDark : AppTheme.textDark)
                    : (isDark ? AppTheme.textMutedDark : AppTheme.textMuted),
              ),
              const Gap(6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? (isDark ? AppTheme.textPrimaryDark : AppTheme.textDark)
                      : (isDark ? AppTheme.textMutedDark : AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeighborCard(BuildContext context, NeighborNode node, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.obsidianCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: node.isActive ? node.color : (isDark ? AppTheme.obsidianElevated : const Color(0xFFE2E8F0)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                node.initials,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        node.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textDark,
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
                          color: isDark ? AppTheme.electricBlue : AppTheme.obsidian,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Mi Radio',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(2),
                Text(
                  '${node.id} · Batería: ${node.batteryPercent}%${node.voltage != null ? ' (${node.voltage!.toStringAsFixed(2)}V)' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                  ),
                ),
                Text(
                  '${node.distance}${node.snr != null ? ' · SNR: ${node.snr!.toStringAsFixed(1)} dB' : ''} · ${node.lastSeenFormatted}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: node.isActive
                  ? (isDark ? AppTheme.onlineGreen.withAlpha(40) : AppTheme.onlineGreenLight)
                  : (isDark ? AppTheme.obsidianElevated : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: node.isActive ? AppTheme.onlineGreen : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(5),
                Text(
                  node.isActive ? 'Activo' : 'Sin señal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: node.isActive ? AppTheme.onlineGreen : (isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

