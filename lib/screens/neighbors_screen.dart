import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/neighbor_node.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/map_view_widget.dart';

class NeighborsScreen extends StatelessWidget {
  const NeighborsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeshProvider>();
    final neighbors = provider.neighbors;
    final activeCount = neighbors.where((n) => n.isActive).length;
    final isMap = provider.isMapView;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(116),
        child: Container(
          color: AppTheme.navy,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VECINOS CERCANOS',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: activeCount > 0 ? AppTheme.lime : const Color(0xFFA0AEC0),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  activeCount > 0
                                      ? '$activeCount nodos activos en la malla LoRa'
                                      : 'Sin otros nodos en rango',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: activeCount > 0 ? AppTheme.lime : const Color(0xFFA0AEC0),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Recargar Malla / Nodos',
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sincronizando nodos vecinos de la malla LoRa...'),
                              duration: Duration(milliseconds: 900),
                              backgroundColor: AppTheme.navy,
                            ),
                          );
                          await provider.refreshAllData();
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle Tab: LISTA / MAPA
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withAlpha(25)),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(
                        label: '☰  LISTA',
                        isActive: !isMap,
                        onTap: () => provider.setMapView(false),
                      ),
                      _buildTabButton(
                        label: '⊙  MAPA',
                        isActive: isMap,
                        onTap: () => provider.setMapView(true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshAllData(),
        color: AppTheme.navy,
        backgroundColor: AppTheme.lime,
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
                                  color: const Color(0xFFF8FAFC),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(
                                  Icons.radar_rounded,
                                  size: 48,
                                  color: Color(0xFFA0AEC0),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Buscando Nodos en la Malla',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Enciende tu segunda antena WisBlock RAK4630 con Meshtastic para que se descubra automáticamente por radiofrecuencia a 915 MHz.\n\nDesliza hacia abajo o pulsa recargar para sincronizar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: neighbors.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Color(0xFFEDF2F7),
                      indent: 76,
                    ),
                    itemBuilder: (context, index) {
                      final node = neighbors[index];
                      return _buildNeighborTile(context, node);
                    },
                  ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppTheme.lime : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isActive ? AppTheme.lime : Colors.white.withAlpha(140),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeighborTile(BuildContext context, NeighborNode node) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: node.isActive ? node.color : const Color(0xFFCBD5E0),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            node.initials,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              node.name,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
          ),
          if (node.isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.navy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'MI RADIO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            '${node.id} · Batería: ${node.batteryPercent}%${node.voltage != null ? ' (${node.voltage!.toStringAsFixed(2)}V)' : ''}',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            '${node.distance}${node.snr != null ? ' · SNR: ${node.snr!.toStringAsFixed(1)} dB' : ''} · ${node.lastSeenFormatted}',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: node.isActive ? AppTheme.lime : const Color(0xFFCBD5E0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            node.isActive ? 'ACTIVO' : 'SIN SEÑAL',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: node.isActive ? const Color(0xFF276749) : const Color(0xFFA0AEC0),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
