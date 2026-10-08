import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/neighbor_node.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';

class MapViewWidget extends StatefulWidget {
  final List<NeighborNode> neighbors;
  final String userName;
  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapViewWidget({
    super.key,
    required this.neighbors,
    required this.userName,
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  NeighborNode? _selectedNode;
  bool _hasInitialCentered = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng? _getMyPosition(MeshProvider provider) {
    if (provider.currentGpsPosition != null) {
      return LatLng(
        provider.currentGpsPosition!.latitude,
        provider.currentGpsPosition!.longitude,
      );
    }
    for (final n in widget.neighbors) {
      if (n.isMe && n.latitude != null && n.longitude != null) {
        return LatLng(n.latitude!, n.longitude!);
      }
    }
    return null;
  }

  void _centerOnMe(LatLng? myPos) {
    if (myPos != null) {
      HapticFeedback.lightImpact();
      _mapController.move(myPos, 16.0);
    }
  }

  void _fitAllNodes(LatLng? myPos, List<NeighborNode> nodesWithGps) {
    HapticFeedback.lightImpact();
    final points = <LatLng>[];
    if (myPos != null) points.add(myPos);
    for (final n in nodesWithGps) {
      if (n.latitude != null && n.longitude != null) {
        points.add(LatLng(n.latitude!, n.longitude!));
      }
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 16.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeshProvider>();
    final myPos = _getMyPosition(provider);
    final nodesWithGps = widget.neighbors.where((n) => !n.isMe && n.latitude != null && n.longitude != null).toList();
    final nodesWithoutGps = widget.neighbors.where((n) => !n.isMe && (n.latitude == null || n.longitude == null)).toList();

    if (!_hasInitialCentered && myPos != null) {
      _hasInitialCentered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(myPos, 15.5);
      });
    }

    final initialCenter = myPos ??
        (nodesWithGps.isNotEmpty
            ? LatLng(nodesWithGps.first.latitude!, nodesWithGps.first.longitude!)
            : const LatLng(-33.4489, -70.6693));

    return Stack(
      children: [
        // 1. OpenStreetMap
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 15.0,
            minZoom: 3.0,
            maxZoom: 19.0,
            onTap: (_, _) {
              if (_selectedNode != null) {
                setState(() => _selectedNode = null);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'cl.uautonoma.radiomesh.radio_mesh',
              maxZoom: 19,
            ),

            if (myPos != null)
              PolylineLayer(
                polylines: nodesWithGps.map((n) {
                  return Polyline(
                    points: [myPos, LatLng(n.latitude!, n.longitude!)],
                    strokeWidth: 2.0,
                    pattern: StrokePattern.dashed(segments: [6, 4]),
                    color: AppTheme.electricBlue.withAlpha(180),
                  );
                }).toList(),
              ),

            if (myPos != null)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final radiusMeters = 20.0 + (_pulseController.value * 40.0);
                  final alpha = ((1.0 - _pulseController.value) * 100).toInt();
                  return CircleLayer(
                    circles: [
                      CircleMarker(
                        point: myPos,
                        radius: radiusMeters,
                        useRadiusInMeter: true,
                        color: AppTheme.onlineGreen.withAlpha(alpha),
                        borderColor: AppTheme.onlineGreen.withAlpha(alpha + 30),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  );
                },
              ),

            MarkerLayer(
              markers: [
                if (myPos != null)
                  Marker(
                    point: myPos,
                    width: 74,
                    height: 74,
                    alignment: Alignment.center,
                    child: _buildMyNodeMarker(provider.userName),
                  ),

                ...nodesWithGps.map((neighbor) {
                  return Marker(
                    point: LatLng(neighbor.latitude!, neighbor.longitude!),
                    width: 68,
                    height: 78,
                    alignment: Alignment.topCenter,
                    child: _buildNeighborMarker(neighbor),
                  );
                }),
              ],
            ),
          ],
        ),

        // 2. Barra Superior de Estado GPS
        Positioned(
          top: 14,
          left: 14,
          right: 14,
          child: _buildTopStatusPill(provider, nodesWithGps.length, nodesWithoutGps.length),
        ),

        // 3. Aviso Informativo si no hay señal GPS aún
        if (myPos == null && nodesWithGps.isEmpty)
          Positioned(
            top: 76,
            left: 14,
            right: 14,
            child: _buildNoGpsNoticeCard(provider),
          ),

        // 4. Botones Flotantes de Acción
        Positioned(
          bottom: _selectedNode != null ? 240 : 20,
          right: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFloatingButton(
                icon: Icons.satellite_alt_rounded,
                tooltip: 'Emitir mi GPS por LoRa',
                color: AppTheme.electricBlue,
                iconColor: Colors.white,
                isLoading: provider.isBroadcastingGps,
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final ok = await provider.broadcastMyLocation();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? '📍 Ubicación GPS transmitida a la malla LoRa.'
                              : '⚠️ No se pudo emitir la ubicación (${provider.gpsStatusMessage})',
                        ),
                        backgroundColor: ok ? AppTheme.obsidian : AppTheme.redAlert,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
              const Gap(8),

              if (myPos != null) ...[
                _buildFloatingButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Centrar en mi ubicación',
                  color: Colors.white,
                  iconColor: AppTheme.textDark,
                  onPressed: () => _centerOnMe(myPos),
                ),
                const Gap(8),
              ],

              if (nodesWithGps.isNotEmpty) ...[
                _buildFloatingButton(
                  icon: Icons.fit_screen_rounded,
                  tooltip: 'Encuadrar todos los nodos',
                  color: Colors.white,
                  iconColor: AppTheme.textDark,
                  onPressed: () => _fitAllNodes(myPos, nodesWithGps),
                ),
                const Gap(8),
              ],

              _buildFloatingButton(
                icon: Icons.add_rounded,
                tooltip: 'Acercar',
                color: Colors.white,
                iconColor: AppTheme.textDark,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final z = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, math.min(z + 1.0, 19.0));
                },
              ),
              const Gap(6),

              _buildFloatingButton(
                icon: Icons.remove_rounded,
                tooltip: 'Alejar',
                color: Colors.white,
                iconColor: AppTheme.textDark,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final z = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, math.max(z - 1.0, 3.0));
                },
              ),
            ],
          ),
        ),

        // 5. Tarjeta de Detalle del Nodo Seleccionado
        if (_selectedNode != null)
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: _buildNodeDetailCard(_selectedNode!),
          ),
      ],
    );
  }

  Widget _buildMyNodeMarker(String userName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.obsidian,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Yo ($userName)',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Gap(2),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.onlineGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNeighborMarker(NeighborNode neighbor) {
    final isSelected = _selectedNode?.nodeNum == neighbor.nodeNum;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedNode = neighbor);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.obsidian : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.electricBlue : AppTheme.borderSubtle,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: neighbor.isActive ? AppTheme.onlineGreen : AppTheme.textSubtle,
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(4),
                Text(
                  neighbor.shortDisplayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Gap(2),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: neighbor.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.electricBlue : Colors.white,
                width: isSelected ? 3.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                neighbor.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatusPill(MeshProvider provider, int withGps, int withoutGps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: provider.isGpsActive ? AppTheme.onlineGreen : AppTheme.warningAmber,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.gpsStatusMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$withGps en mapa • $withoutGps sin coordenadas',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (provider.isBroadcastingGps)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.electricBlue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoGpsNoticeCard(MeshProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 18,
          ),
          Gap(10),
          Expanded(
            child: Text(
              'Toca "Emitir mi GPS" para inyectar tu posición y que otros nodos te vean en el mapa.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeDetailCard(NeighborNode node) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: node.color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    node.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${node.id} • ${node.lastSeenFormatted}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                onPressed: () => setState(() => _selectedNode = null),
              ),
            ],
          ),
          const Divider(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                icon: Icons.navigation_rounded,
                label: 'DISTANCIA',
                value: node.distance,
                color: AppTheme.electricBlue,
              ),
              _buildMetricItem(
                icon: Icons.battery_5_bar_rounded,
                label: 'BATERÍA',
                value: '${node.batteryPercent}%',
                color: AppTheme.onlineGreen,
              ),
              _buildMetricItem(
                icon: Icons.signal_cellular_alt_rounded,
                label: 'SNR LORA',
                value: node.snr != null ? '${node.snr!.toStringAsFixed(1)} dB' : 'N/A',
                color: AppTheme.textDark,
              ),
            ],
          ),
          const Gap(10),

          // Coordenadas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, size: 14, color: AppTheme.electricBlue),
                const Gap(6),
                Expanded(
                  child: Text(
                    'Lat: ${node.latitude!.toStringAsFixed(5)}  Lon: ${node.longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: '${node.latitude}, ${node.longitude}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coordenadas copiadas al portapapeles.'),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppTheme.obsidian,
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.copy_rounded, size: 14, color: AppTheme.textMuted),
                  ),
                ),
                const Gap(6),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _mapController.move(LatLng(node.latitude!, node.longitude!), 17.0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.obsidian,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Enfocar',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSubtle,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 18,
                    color: iconColor,
                  ),
          ),
        ),
      ),
    );
  }
}

