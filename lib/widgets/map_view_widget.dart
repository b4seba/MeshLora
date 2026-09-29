import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
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
    // Si no está en el provider, buscar en el nodo marcado como isMe
    for (final n in widget.neighbors) {
      if (n.isMe && n.latitude != null && n.longitude != null) {
        return LatLng(n.latitude!, n.longitude!);
      }
    }
    return null;
  }

  void _centerOnMe(LatLng? myPos) {
    if (myPos != null) {
      _mapController.move(myPos, 16.0);
    }
  }

  void _fitAllNodes(LatLng? myPos, List<NeighborNode> nodesWithGps) {
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

    // Centrar automáticamente en la primera fijación de GPS
    if (!_hasInitialCentered && myPos != null) {
      _hasInitialCentered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(myPos, 15.5);
      });
    }

    // Coordenada inicial por defecto (Santiago, Chile o posición del usuario)
    final initialCenter = myPos ??
        (nodesWithGps.isNotEmpty
            ? LatLng(nodesWithGps.first.latitude!, nodesWithGps.first.longitude!)
            : const LatLng(-33.4489, -70.6693));

    return Stack(
      children: [
        // 1. Mapa Real OpenStreetMap
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
            // Capa de teselas OpenStreetMap
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'cl.uautonoma.radiomesh.radio_mesh',
              maxZoom: 19,
            ),

            // Enlaces LoRa (Líneas discontinuas entre mi nodo y vecinos con GPS)
            if (myPos != null)
              PolylineLayer(
                polylines: nodesWithGps.map((n) {
                  return Polyline(
                    points: [myPos, LatLng(n.latitude!, n.longitude!)],
                    strokeWidth: 2.5,
                    pattern: StrokePattern.dashed(segments: [8, 6]),
                    color: n.color.withAlpha(200),
                  );
                }).toList(),
              ),

            // Halo animado de radar alrededor de mi ubicación
            if (myPos != null)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final radiusMeters = 20.0 + (_pulseController.value * 40.0);
                  final alpha = ((1.0 - _pulseController.value) * 120).toInt();
                  return CircleLayer(
                    circles: [
                      CircleMarker(
                        point: myPos,
                        radius: radiusMeters,
                        useRadiusInMeter: true,
                        color: AppTheme.lime.withAlpha(alpha),
                        borderColor: AppTheme.lime.withAlpha(alpha + 40),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  );
                },
              ),

            // Marcadores de Nodos en Coordenadas Reales
            MarkerLayer(
              markers: [
                // Marcador "Mi Nodo" (Yo)
                if (myPos != null)
                  Marker(
                    point: myPos,
                    width: 74,
                    height: 74,
                    alignment: Alignment.center,
                    child: _buildMyNodeMarker(provider.userName),
                  ),

                // Marcadores de Nodos Vecinos de la Malla
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

        // 3. Aviso Informativo si no hay señal satelital aún
        if (myPos == null && nodesWithGps.isEmpty)
          Positioned(
            top: 76,
            left: 16,
            right: 16,
            child: _buildNoGpsNoticeCard(provider),
          ),

        // 4. Botones Flotantes de Acción y Navegación
        Positioned(
          bottom: _selectedNode != null ? 220 : 24,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Emitir Posición LoRa
              _buildFloatingActionButton(
                icon: Icons.satellite_alt_rounded,
                tooltip: 'Emitir mi GPS por LoRa',
                color: AppTheme.lime,
                iconColor: AppTheme.navy,
                isLoading: provider.isBroadcastingGps,
                onPressed: () async {
                  final ok = await provider.broadcastMyLocation();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? '📍 Ubicación GPS transmitida a la malla LoRa.'
                              : '⚠️ No se pudo emitir la ubicación (${provider.gpsStatusMessage})',
                        ),
                        backgroundColor: ok ? AppTheme.navy : AppTheme.redAlert,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),

              // Botón Centrar en Mí
              if (myPos != null) ...[
                _buildFloatingActionButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Centrar en mi ubicación',
                  color: Colors.white,
                  iconColor: AppTheme.navy,
                  onPressed: () => _centerOnMe(myPos),
                ),
                const SizedBox(height: 10),
              ],

              // Botón Encuadre Total (Fit All)
              if (nodesWithGps.isNotEmpty) ...[
                _buildFloatingActionButton(
                  icon: Icons.filter_center_focus_rounded,
                  tooltip: 'Encuadrar todos los nodos',
                  color: Colors.white,
                  iconColor: AppTheme.navy,
                  onPressed: () => _fitAllNodes(myPos, nodesWithGps),
                ),
                const SizedBox(height: 10),
              ],

              // Zoom In
              _buildFloatingActionButton(
                icon: Icons.add,
                tooltip: 'Acercar',
                color: Colors.white,
                iconColor: AppTheme.navy,
                onPressed: () {
                  final z = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, math.min(z + 1.0, 19.0));
                },
              ),
              const SizedBox(height: 8),

              // Zoom Out
              _buildFloatingActionButton(
                icon: Icons.remove,
                tooltip: 'Alejar',
                color: Colors.white,
                iconColor: AppTheme.navy,
                onPressed: () {
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
            bottom: 16,
            left: 14,
            right: 14,
            child: _buildNodeDetailCard(_selectedNode!),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets de Marcadores Cartográficos
  // ---------------------------------------------------------------------------

  Widget _buildMyNodeMarker(String userName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.navy,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Yo ($userName)',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.lime,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(70),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            size: 20,
            color: AppTheme.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildNeighborMarker(NeighborNode neighbor) {
    final isSelected = _selectedNode?.nodeNum == neighbor.nodeNum;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedNode = neighbor);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.navy : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.lime : const Color(0xFFCBD5E1),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: neighbor.isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  neighbor.shortDisplayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: neighbor.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.lime : Colors.white,
                width: isSelected ? 3.5 : 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                neighbor.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Componentes de Interfaz Superior e Inferior
  // ---------------------------------------------------------------------------

  Widget _buildTopStatusPill(MeshProvider provider, int withGps, int withoutGps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: provider.isGpsActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.gpsStatusMessage,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$withGps en mapa • $withoutGps sin coordenadas',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.navy),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Toca "Emitir mi GPS" para inyectar la ubicación de este teléfono a la antena y que el otro nodo te vea en el mapa.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.amber.shade900,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila Superior: Nombre, ID y botón cerrar
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: node.color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    node.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${node.id} • ${node.lastSeenFormatted}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedNode = null),
              ),
            ],
          ),
          const Divider(height: 20),

          // Fila de Métricas Reales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                icon: Icons.straighten_rounded,
                label: 'DISTANCIA',
                value: node.distance,
                color: AppTheme.navy,
              ),
              _buildMetricItem(
                icon: Icons.battery_charging_full_rounded,
                label: 'BATERÍA',
                value: '${node.batteryPercent}%',
                color: const Color(0xFF10B981),
              ),
              _buildMetricItem(
                icon: Icons.network_check_rounded,
                label: 'SNR LORA',
                value: node.snr != null ? '${node.snr!.toStringAsFixed(1)} dB' : 'N/A',
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Badge de precisión GPS
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (node.isMe || node.isHighPrecision)
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (node.isMe || node.isHighPrecision)
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCD34D),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (node.isMe || node.isHighPrecision)
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      size: 13,
                      color: (node.isMe || node.isHighPrecision)
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (node.isMe || node.isHighPrecision)
                          ? 'GPS Exacto (100% Real)'
                          : 'GPS Canal Meshtastic (${node.precisionBits}b: ~1.9 km)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: (node.isMe || node.isHighPrecision)
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Coordenadas GPS exactas y botón centrar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.navy),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lat: ${node.latitude!.toStringAsFixed(5)}  Lon: ${node.longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                      color: AppTheme.navy,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: '${node.latitude}, ${node.longitude}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coordenadas copiadas al portapapeles.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    _mapController.move(LatLng(node.latitude!, node.longitude!), 17.0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ENFOCAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.navy,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      shadowColor: Colors.black.withAlpha(50),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 46,
            height: 46,
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 22,
                    color: iconColor,
                  ),
          ),
        ),
      ),
    );
  }
}
