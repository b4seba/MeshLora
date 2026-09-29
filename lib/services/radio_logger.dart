import 'dart:async';
import 'package:flutter/foundation.dart';

enum LogType {
  info,
  loraRx,
  loraTx,
  telemetry,
  node,
  ble,
  warning,
  error,
  gps,
}

class RadioLogEntry {
  final DateTime timestamp;
  final LogType type;
  final String tag;
  final String message;
  final String? rawHex;

  RadioLogEntry({
    required this.timestamp,
    required this.type,
    required this.tag,
    required this.message,
    this.rawHex,
  });

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = (timestamp.millisecond ~/ 10).toString().padLeft(2, '0');
    return '$h:$m:$s.$ms';
  }

  String get typeEmoji {
    switch (type) {
      case LogType.gps:
        return '📍 [GPS]';
      case LogType.loraRx:
        return '📥 [LORA RX]';
      case LogType.loraTx:
        return '🚀 [LORA TX]';
      case LogType.telemetry:
        return '⚡ [TELEMETRÍA]';
      case LogType.node:
        return '📡 [NODO MESH]';
      case LogType.ble:
        return '🔵 [BLE]';
      case LogType.warning:
        return '⚠️ [AVISO]';
      case LogType.error:
        return '❌ [ERROR]';
      case LogType.info:
        return 'ℹ️ [INFO]';
    }
  }
}

class RadioLogger {
  static final RadioLogger _instance = RadioLogger._internal();
  factory RadioLogger() => _instance;
  RadioLogger._internal();

  final List<RadioLogEntry> _logs = [];
  final _logStreamController = StreamController<RadioLogEntry>.broadcast();

  List<RadioLogEntry> get logs => List.unmodifiable(_logs);
  Stream<RadioLogEntry> get logStream => _logStreamController.stream;

  static const int maxLogs = 200;

  void log({
    required LogType type,
    required String tag,
    required String message,
    String? rawHex,
  }) {
    final entry = RadioLogEntry(
      timestamp: DateTime.now(),
      type: type,
      tag: tag,
      message: message,
      rawHex: rawHex,
    );

    _logs.add(entry);
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }

    _logStreamController.add(entry);

    // Salida directa a la terminal (visible en `flutter run`)
    final hexStr = rawHex != null && rawHex.isNotEmpty ? ' | HEX: [$rawHex]' : '';
    debugPrint('${entry.timeFormatted} ${entry.typeEmoji} $tag: $message$hexStr');
  }

  void info(String tag, String message, [String? hex]) => log(type: LogType.info, tag: tag, message: message, rawHex: hex);
  void ble(String tag, String message, [String? hex]) => log(type: LogType.ble, tag: tag, message: message, rawHex: hex);
  void loraRx(String tag, String message, [String? hex]) => log(type: LogType.loraRx, tag: tag, message: message, rawHex: hex);
  void loraTx(String tag, String message, [String? hex]) => log(type: LogType.loraTx, tag: tag, message: message, rawHex: hex);
  void telemetry(String tag, String message, [String? hex]) => log(type: LogType.telemetry, tag: tag, message: message, rawHex: hex);
  void node(String tag, String message, [String? hex]) => log(type: LogType.node, tag: tag, message: message, rawHex: hex);
  void warn(String tag, String message, [String? hex]) => log(type: LogType.warning, tag: tag, message: message, rawHex: hex);
  void error(String tag, String message, [String? hex]) => log(type: LogType.error, tag: tag, message: message, rawHex: hex);
  void gps(String tag, String message, [String? hex]) => log(type: LogType.gps, tag: tag, message: message, rawHex: hex);

  void clear() {
    _logs.clear();
  }
}
