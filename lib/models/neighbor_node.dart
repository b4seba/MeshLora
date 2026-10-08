import 'dart:math' as math;
import 'package:flutter/material.dart';

class NeighborNode {
  final int nodeNum;
  final String id; // e.g. !e829a410
  final String name; // real long name or short name
  final String shortName;
  final String distance;
  final Color color;
  final double? latitude;
  final double? longitude;
  final double xPercent; // 0..100 para renderizado en mapa
  final double yPercent; // 0..100 para renderizado en mapa
  final bool isUrgent;
  final bool isMe;
  final int _rawBatteryPercent;
  final double? voltage;
  final double? snr;
  final DateTime lastSeen;
  final int hopsAway;
  final bool isHighPrecision;
  final int precisionBits;

  NeighborNode({
    required this.nodeNum,
    required this.id,
    required this.name,
    this.shortName = '',
    required this.distance,
    required this.color,
    this.latitude,
    this.longitude,
    required this.xPercent,
    required this.yPercent,
    this.isUrgent = false,
    this.isMe = false,
    int batteryPercent = 0,
    this.voltage,
    this.snr,
    required this.lastSeen,
    this.hopsAway = 0,
    this.isHighPrecision = false,
    this.precisionBits = 32,
  }) : _rawBatteryPercent = batteryPercent;

  /// Porcentaje real de batería LiPo calculado a partir del voltaje
  int get batteryPercent {
    if (voltage != null && voltage! > 0) {
      if (voltage! >= 4.20) return 100;
      if (voltage! <= 3.20) return 0;
      return ((voltage! - 3.20) / (4.20 - 3.20) * 100).clamp(0, 100).round();
    }
    return (_rawBatteryPercent > 0 && _rawBatteryPercent < 100) ? _rawBatteryPercent : 0;
  }

  /// Un nodo está ACTIVO si es mi radio local o si se ha escuchado algún paquete de él en los últimos 15 minutos
  bool get isActive {
    if (isMe) return true;
    final diff = DateTime.now().difference(lastSeen);
    return diff.inMinutes < 15;
  }

  /// Texto legible del tiempo transcurrido desde el último paquete LoRa
  String get lastSeenFormatted {
    if (isMe) return 'Mi Radio';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 45) return 'Visto hace unos seg';
    if (diff.inMinutes < 60) return 'Visto hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Visto hace ${diff.inHours} h';
    return 'Visto hace ${diff.inDays} d';
  }

  NeighborNode copyWith({
    int? nodeNum,
    String? id,
    String? name,
    String? shortName,
    String? distance,
    Color? color,
    double? latitude,
    double? longitude,
    double? xPercent,
    double? yPercent,
    bool? isUrgent,
    bool? isMe,
    int? batteryPercent,
    double? voltage,
    double? snr,
    DateTime? lastSeen,
    int? hopsAway,
    bool? isHighPrecision,
    int? precisionBits,
  }) {
    return NeighborNode(
      nodeNum: nodeNum ?? this.nodeNum,
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      distance: distance ?? this.distance,
      color: color ?? this.color,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      xPercent: xPercent ?? this.xPercent,
      yPercent: yPercent ?? this.yPercent,
      isUrgent: isUrgent ?? this.isUrgent,
      isMe: isMe ?? this.isMe,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      voltage: voltage ?? this.voltage,
      snr: snr ?? this.snr,
      lastSeen: lastSeen ?? this.lastSeen,
      hopsAway: hopsAway ?? this.hopsAway,
      isHighPrecision: isHighPrecision ?? this.isHighPrecision,
      precisionBits: precisionBits ?? this.precisionBits,
    );
  }

  String get shortDisplayName {
    if (shortName.isNotEmpty) return shortName;
    final parts = name.split(' ');
    if (parts.isNotEmpty) return parts[0];
    return id;
  }

  String get initials {
    final clean = name.trim();
    if (clean.isEmpty) return 'N';
    final parts = clean.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.length >= 2 ? clean.substring(0, 2).toUpperCase() : clean.toUpperCase();
  }

  static Color pickColorFromNum(int num, String name) {
    const colors = [
      Color(0xFF7B61FF),
      Color(0xFFFF6B00),
      Color(0xFF2ECC71),
      Color(0xFF3498DB),
      Color(0xFFE74C3C),
      Color(0xFFF39C12),
      Color(0xFF9B59B6),
      Color(0xFF1ABC9C),
    ];
    final seed = num != 0 ? num : name.codeUnits.fold<int>(0, (p, e) => p + e);
    return colors[seed.abs() % colors.length];
  }

  /// Calcula coordenadas relativas (xPercent, yPercent de 10 a 90) para el mapa local
  static Map<String, double> computeRelativeXY(
    double? nodeLat,
    double? nodeLon,
    double? myLat,
    double? myLon,
    int index,
    int totalNodes,
  ) {
    if (nodeLat != null && nodeLon != null && myLat != null && myLon != null) {
      // Proyección cartesiana simple centrada en mi ubicación
      final dLat = (nodeLat - myLat) * 111320.0; // metros
      final dLon = (nodeLon - myLon) * 111320.0 * math.cos(myLat * math.pi / 180.0);

      // Escala máx. 1.5 km a 35% del radio de la pantalla
      final x = (50.0 + (dLon / 1500.0) * 35.0).clamp(12.0, 88.0);
      final y = (50.0 - (dLat / 1500.0) * 35.0).clamp(12.0, 88.0);
      return {'x': x, 'y': y};
    }

    // Si no hay GPS en el nodo, distribuirlo en constelación circular ordenada alrededor de 'Yo'
    final angle = (index * (2 * math.pi / math.max(1, totalNodes))) - (math.pi / 2);
    final radius = 22.0 + (index % 3) * 8.0;
    final x = (50.0 + radius * math.cos(angle)).clamp(15.0, 85.0);
    final y = (50.0 + radius * math.sin(angle)).clamp(15.0, 85.0);
    return {'x': x, 'y': y};
  }
}
