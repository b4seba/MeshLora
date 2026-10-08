import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'meshtastic_protocol.dart';
import 'radio_logger.dart';

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class DiscoveredRadioDevice {
  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice? device;
  final bool isMeshtastic;

  DiscoveredRadioDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.device,
    this.isMeshtastic = false,
  });

  bool get isLikelyRadio => isMeshtastic;
}

class BleService {
  final RadioLogger _logger = RadioLogger();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _toRadioCharacteristic;
  BluetoothCharacteristic? _fromRadioCharacteristic;
  BluetoothCharacteristic? _fromNumCharacteristic;

  StreamSubscription<List<int>>? _fromRadioSub;
  StreamSubscription<List<int>>? _fromNumSub;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _pollTimer;
  Timer? _handshakeRetryTimer;
  bool _isDraining = false;

  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _myNodeInfoController = StreamController<MeshtasticMyNodeInfo>.broadcast();
  final _nodeInfoController = StreamController<MeshtasticNode>.broadcast();
  final _telemetryController = StreamController<MeshtasticTelemetry>.broadcast();
  final _metadataController = StreamController<MeshtasticDeviceMetadata>.broadcast();
  final _inboundMessageController = StreamController<MeshtasticInboundMessage>.broadcast();
  final _discoveredDevicesController = StreamController<List<DiscoveredRadioDevice>>.broadcast();

  BleConnectionState _currentState = BleConnectionState.disconnected;
  final List<DiscoveredRadioDevice> _cachedDevices = [];
  int _myNodeNum = 0;

  Stream<BleConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<MeshtasticMyNodeInfo> get myNodeInfoStream => _myNodeInfoController.stream;
  Stream<MeshtasticNode> get nodeInfoStream => _nodeInfoController.stream;
  Stream<MeshtasticTelemetry> get telemetryStream => _telemetryController.stream;
  Stream<MeshtasticDeviceMetadata> get metadataStream => _metadataController.stream;
  Stream<MeshtasticInboundMessage> get inboundMessageStream => _inboundMessageController.stream;
  Stream<List<DiscoveredRadioDevice>> get discoveredDevicesStream => _discoveredDevicesController.stream;

  BleConnectionState get currentState => _currentState;
  bool get isConnected => _currentState == BleConnectionState.connected;
  int get myNodeNum => _myNodeNum;
  String get connectedDeviceName => _connectedDevice?.platformName.isNotEmpty == true
      ? _connectedDevice!.platformName
      : 'Desconectado';
  String get connectedDeviceId => _connectedDevice?.remoteId.str ?? '';

  BleService() {
    _initBleStateListener();
  }

  void _initBleStateListener() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on && _currentState == BleConnectionState.connected) {
          _logger.warn('BLE', 'Adaptador Bluetooth apagado o desconectado.');
          _setConnectionState(BleConnectionState.disconnected);
        }
      });
    } catch (e) {
      _logger.error('BLE', 'Error inicializando listener BLE: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;

    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ].request();

        return statuses.values.every((s) => s.isGranted || s.isLimited);
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.request();
        return status.isGranted;
      }
    } catch (e) {
      _logger.error('PERMISOS', 'Error solicitando permisos BLE: $e');
    }
    return true;
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    _setConnectionState(BleConnectionState.scanning);
    _cachedDevices.clear();
    _logger.info('BLE SCAN', 'Iniciando escaneo de antenas LoRa / WisBlock...');

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _setConnectionState(BleConnectionState.disconnected);
      return;
    }

    try {
      await requestPermissions();

      final isScanning = FlutterBluePlus.isScanningNow;
      if (isScanning) {
        await FlutterBluePlus.stopScan();
      }

      final devicesMap = <String, DiscoveredRadioDevice>{};

      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var r in results) {
          final platformName = r.device.platformName;
          final advName = r.advertisementData.advName;
          final name = platformName.isNotEmpty ? platformName : advName;

          // Detección de dispositivos Meshtastic / WisBlock
          final isMeshtastic = name.toUpperCase().contains('MESHTASTIC') ||
              name.toUpperCase().contains('RAK') ||
              name.toUpperCase().contains('WISBLOCK') ||
              name.toUpperCase().contains('MESH') ||
              r.advertisementData.serviceUuids.any(
                (u) => u.str.toLowerCase().contains('6ba1'),
              );

          if (name.isNotEmpty || isMeshtastic) {
            final displayName = name.isNotEmpty
                ? name
                : 'Meshtastic Node (${r.device.remoteId.str.length > 5 ? r.device.remoteId.str.substring(0, 5) : r.device.remoteId.str})';

            if (!devicesMap.containsKey(r.device.remoteId.str)) {
              _logger.ble('DISPOSITIVO', 'Detectado: "$displayName" [RSSI: ${r.rssi} dBm | ID: ${r.device.remoteId.str}]');
            }

            devicesMap[r.device.remoteId.str] = DiscoveredRadioDevice(
              id: r.device.remoteId.str,
              name: displayName,
              rssi: r.rssi,
              device: r.device,
              isMeshtastic: isMeshtastic,
            );
          }
        }

        final sortedList = devicesMap.values.toList()
          ..sort((a, b) {
            if (a.isMeshtastic && !b.isMeshtastic) return -1;
            if (!a.isMeshtastic && b.isMeshtastic) return 1;
            return b.rssi.compareTo(a.rssi);
          });

        _cachedDevices.clear();
        _cachedDevices.addAll(sortedList);
        _discoveredDevicesController.add(List.from(_cachedDevices));
      });

      await FlutterBluePlus.startScan(timeout: timeout);

      Future.delayed(timeout, () {
        if (_currentState == BleConnectionState.scanning) {
          _setConnectionState(BleConnectionState.disconnected);
          _logger.info('BLE SCAN', 'Escaneo finalizado. ${_cachedDevices.length} dispositivos encontrados.');
        }
      });
    } catch (e) {
      _logger.error('BLE SCAN', 'Fallo escaneo BLE: $e');
      _setConnectionState(BleConnectionState.disconnected);
    }
  }

  Future<bool> connectToDevice(dynamic deviceOrId) async {
    _setConnectionState(BleConnectionState.connecting);

    BluetoothDevice? targetDevice;
    if (deviceOrId is BluetoothDevice) {
      targetDevice = deviceOrId;
    } else if (deviceOrId is DiscoveredRadioDevice && deviceOrId.device != null) {
      targetDevice = deviceOrId.device;
    } else if (deviceOrId is String && deviceOrId.isNotEmpty) {
      final found = _cachedDevices.where((d) => d.id == deviceOrId).firstOrNull;
      if (found?.device != null) {
        targetDevice = found!.device;
      }
    }

    if (targetDevice == null) {
      _setConnectionState(BleConnectionState.disconnected);
      return false;
    }

    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }

      _logger.info('CONEXIÓN', 'Estableciendo enlace BLE con ${targetDevice.platformName} (${targetDevice.remoteId})...');
      await targetDevice.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 14),
        autoConnect: false,
      );
      _connectedDevice = targetDevice;

      // Solicitar MTU extendido (512 bytes)
      try {
        if (Platform.isAndroid) {
          await targetDevice.requestMtu(512);
          _logger.ble('GATT', 'MTU solicitado a 512 bytes.');
        }
      } catch (e) {
        _logger.warn('GATT', 'Nota MTU: $e');
      }

      // Descubrir servicios GATT
      final services = await targetDevice.discoverServices();
      _logger.ble('GATT', '${services.length} servicios GATT descubiertos.');

      _toRadioCharacteristic = null;
      _fromRadioCharacteristic = null;
      _fromNumCharacteristic = null;

      // 1. Mostrar todos los servicios y características descubiertas
      for (var s in services) {
        final sUuidStr = s.uuid.toString().toLowerCase();
        _logger.ble('DISCOVERY', 'Servicio: $sUuidStr');

        for (var c in s.characteristics) {
          final cUuidStr = c.uuid.toString().toLowerCase();
          final props = <String>[];
          if (c.properties.read) props.add('READ');
          if (c.properties.write) props.add('WRITE');
          if (c.properties.writeWithoutResponse) props.add('WRITE_NO_RESP');
          if (c.properties.notify) props.add('NOTIFY');
          _logger.ble('DISCOVERY', '  -> Char: $cUuidStr [${props.join(", ")}]');
        }
      }

      // 2. Localizar el Servicio Meshtastic específico (UUID que inicia con 6ba1...)
      BluetoothService? meshtasticService;

      for (var s in services) {
        final sUuid = s.uuid.toString().toLowerCase().replaceAll('-', '');
        if (sUuid.startsWith('6ba1') || sUuid.contains('6ba1') || sUuid.contains('cb0b9a0b')) {
          meshtasticService = s;
          break;
        }
      }

      // Fallback a servicio 128-bit que no sea estándar de Bluetooth ni DFU
      if (meshtasticService == null) {
        for (var s in services) {
          final sUuid = s.uuid.toString().toLowerCase();
          final isStandard = sUuid.contains('00001800') ||
              sUuid.contains('00001801') ||
              sUuid.contains('0000180a') ||
              sUuid.contains('0000180f') ||
              sUuid.contains('00001530') || // Nordic DFU
              sUuid.startsWith('1800') ||
              sUuid.startsWith('1801') ||
              sUuid.startsWith('180a');
          if (!isStandard && s.characteristics.length >= 2) {
            meshtasticService = s;
            break;
          }
        }
      }

      if (meshtasticService != null) {
        _logger.ble('MESHTASTIC SERVICE', 'Servicio Meshtastic vinculado: ${meshtasticService.uuid}');

        // A) Buscar TORADIO de forma explícita por UUID (f75c76d2 o f75de936)
        for (var c in meshtasticService.characteristics) {
          final u = c.uuid.toString().toLowerCase().replaceAll('-', '');
          if (u.contains('f75c76d2') || u.contains('f75de936')) {
            _toRadioCharacteristic = c;
            break;
          }
        }
        if (_toRadioCharacteristic == null) {
          for (var c in meshtasticService.characteristics) {
            if (c.properties.write || c.properties.writeWithoutResponse) {
              _toRadioCharacteristic = c;
              break;
            }
          }
        }
        if (_toRadioCharacteristic != null) {
          _logger.ble('TORADIO', 'Canal TORADIO asignado: ${_toRadioCharacteristic!.uuid} [Write: ${_toRadioCharacteristic!.properties.write}, WriteNoResp: ${_toRadioCharacteristic!.properties.writeWithoutResponse}]');
        }

        // B) Buscar FROMRADIO de forma explícita por UUID (2c55e69e o 8ba2b240)
        for (var c in meshtasticService.characteristics) {
          final u = c.uuid.toString().toLowerCase().replaceAll('-', '');
          if (u.contains('2c55e69e') || u.contains('8ba2b240')) {
            _fromRadioCharacteristic = c;
            break;
          }
        }
        if (_fromRadioCharacteristic == null) {
          for (var c in meshtasticService.characteristics) {
            if (c != _toRadioCharacteristic && c.properties.read) {
              _fromRadioCharacteristic = c;
              break;
            }
          }
        }
        if (_fromRadioCharacteristic != null) {
          _logger.ble('FROMRADIO', 'Canal FROMRADIO asignado: ${_fromRadioCharacteristic!.uuid} [Read: ${_fromRadioCharacteristic!.properties.read}, Notify: ${_fromRadioCharacteristic!.properties.notify}]');
        }

        // C) Buscar FROMNUM de forma explícita por UUID (ed9da18c)
        for (var c in meshtasticService.characteristics) {
          final u = c.uuid.toString().toLowerCase().replaceAll('-', '');
          if (u.contains('ed9da18c')) {
            _fromNumCharacteristic = c;
            break;
          }
        }
        if (_fromNumCharacteristic == null) {
          for (var c in meshtasticService.characteristics) {
            if (c != _toRadioCharacteristic && c != _fromRadioCharacteristic && c.properties.notify) {
              _fromNumCharacteristic = c;
              break;
            }
          }
        }
        if (_fromNumCharacteristic != null) {
          _logger.ble('FROMNUM', 'Canal FROMNUM asignado: ${_fromNumCharacteristic!.uuid} [Notify: ${_fromNumCharacteristic!.properties.notify}]');
        }
      } else {
        _logger.error('MESHTASTIC SERVICE', 'No se encontró el servicio Meshtastic en el dispositivo.');
      }

      // Suscribirse a notificaciones en FROMRADIO si soporta notify
      if (_fromRadioCharacteristic != null && _fromRadioCharacteristic!.properties.notify) {
        try {
          _fromRadioSub?.cancel();
          _fromRadioSub = _fromRadioCharacteristic!.onValueReceived.listen((value) {
            _handleFromRadioPacket(Uint8List.fromList(value));
          });
          await _fromRadioCharacteristic!.setNotifyValue(true);
          _logger.ble('FROMRADIO', 'Suscripción a notificaciones FROMRADIO activa.');
        } catch (e) {
          _logger.warn('FROMRADIO', 'Aviso suscripción notify: $e');
        }
      }

      // Suscribirse a notificaciones en FROMNUM (trigger fundamental para drenar la cola de Meshtastic)
      if (_fromNumCharacteristic != null && _fromNumCharacteristic!.properties.notify) {
        try {
          _fromNumSub?.cancel();
          _fromNumSub = _fromNumCharacteristic!.onValueReceived.listen((value) {
            _logger.ble('FROMNUM', 'Evento notificado por WisBlock. Drenando cola FROMRADIO...');
            drainFromRadio();
          });
          await _fromNumCharacteristic!.setNotifyValue(true);
          _logger.ble('FROMNUM', 'Suscripción a eventos FROMNUM activa.');
        } catch (e) {
          _logger.warn('FROMNUM', 'Aviso suscripción FROMNUM: $e');
        }
      }

      _setConnectionState(BleConnectionState.connected);
      _logger.info('CONEXIÓN', '¡Enlace BLE establecido con éxito con ${targetDevice.platformName}!');

      // Sincronizar malla enviando want_config_id con reintentos activos
      _startConfigSyncLifecycle();

      // Iniciar temporizador de sondeo periódico (cada 2 segundos)
      _startDrainPolling();

      return true;
    } catch (e) {
      _logger.error('CONEXIÓN', 'Error conectando a dispositivo: $e');
      _setConnectionState(BleConnectionState.disconnected);
      return false;
    }
  }

  /// Ciclo de sincronización: envía want_config_id y reintenta si el nodo aún no ha respondido
  void _startConfigSyncLifecycle() {
    requestMeshConfigSync();

    _handshakeRetryTimer?.cancel();
    int attempts = 0;
    _handshakeRetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentState != BleConnectionState.connected || _myNodeNum != 0 || attempts >= 4) {
        timer.cancel();
        return;
      }
      attempts++;
      _logger.info('HANDSHAKE', 'Reintentando solicitud want_config_id (intento $attempts)...');
      requestMeshConfigSync();
    });
  }

  /// Solicita a la placa WisBlock que envíe la lista de nodos y estado (`want_config_id`)
  Future<void> requestMeshConfigSync() async {
    if (_toRadioCharacteristic == null) {
      _logger.error('HANDSHAKE', 'No se puede sincronizar: TORADIO no fue encontrado.');
      return;
    }

    try {
      final configPacket = MeshtasticProtocol.buildWantConfigPacket(123456);
      final hex = configPacket.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

      _logger.ble('HANDSHAKE', 'Enviando solicitud want_config_id a TORADIO (${configPacket.length} bytes | ${_toRadioCharacteristic!.uuid})', hex);

      final canWriteNoResp = _toRadioCharacteristic!.properties.writeWithoutResponse;
      final canWriteWithResp = _toRadioCharacteristic!.properties.write;

      try {
        await _toRadioCharacteristic!.write(
          configPacket,
          withoutResponse: canWriteNoResp || !canWriteWithResp,
          timeout: 4,
        );
        _logger.info('HANDSHAKE', 'want_config_id enviado con éxito a TORADIO.');
      } catch (e) {
        _logger.warn('HANDSHAKE', 'Primer intento falló ($e), reintentando modo alternativo...');
        await _toRadioCharacteristic!.write(
          configPacket,
          withoutResponse: !canWriteNoResp,
          timeout: 4,
        );
        _logger.info('HANDSHAKE', 'want_config_id enviado con éxito a TORADIO (modo alternativo).');
      }

      // Programar drenajes secuenciales para recoger respuesta
      Future.delayed(const Duration(milliseconds: 400), () => drainFromRadio());
      Future.delayed(const Duration(milliseconds: 1000), () => drainFromRadio());
      Future.delayed(const Duration(milliseconds: 2000), () => drainFromRadio());
      Future.delayed(const Duration(milliseconds: 3200), () => drainFromRadio());
    } catch (e) {
      _logger.error('HANDSHAKE', 'Error solicitando sincronización: $e');
    }
  }

  void _startDrainPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentState == BleConnectionState.connected) {
        drainFromRadio();
      } else {
        timer.cancel();
      }
    });
  }

  /// Lee continuamente FROMRADIO hasta vaciar la cola del WisBlock
  Future<void> drainFromRadio() async {
    if (_fromRadioCharacteristic == null || _currentState != BleConnectionState.connected || _isDraining) return;
    _isDraining = true;

    try {
      for (int i = 0; i < 25; i++) {
        if (_currentState != BleConnectionState.connected) break;

        final bytes = await _fromRadioCharacteristic!.read().timeout(const Duration(milliseconds: 1500));
        if (bytes.isEmpty) break;

        final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        _logger.ble('FROMRADIO RX', 'Leídos ${bytes.length} bytes de FROMRADIO', hex);

        _handleFromRadioPacket(Uint8List.fromList(bytes));
        await Future.delayed(const Duration(milliseconds: 35));
      }
    } catch (e) {
      // Fin del drenaje o timeout cuando no hay más datos pendientes
    } finally {
      _isDraining = false;
    }
  }

  void _handleFromRadioPacket(Uint8List rawBytes) {
    if (rawBytes.isEmpty) return;

    final hex = rawBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

    try {
      final decoded = MeshtasticProtocol.decodeFromRadio(rawBytes);
      if (decoded == null) {
        _logger.ble('PAQUETE CRUDO', 'Paquete recibido sin decodificar (${rawBytes.length} bytes)', hex);
        return;
      }

      if (decoded is MeshtasticMyNodeInfo) {
        _myNodeNum = decoded.myNodeNum;
        _logger.info('NODO LOCAL', '🟢 MyNodeInfo recibido: ID=${decoded.nodeHex} (Num=${decoded.myNodeNum}) FW="${decoded.firmwareVersion}" GPS=${decoded.hasGps ? "Sí" : "No"}');
        _myNodeInfoController.add(decoded);
      } else if (decoded is MeshtasticNode) {
        if (decoded.latitude != null && decoded.longitude != null) {
          _logger.gps(
            'GPS RX RECIBIDO',
            '📍 Coordenadas RECIBIDAS por LoRa de ${decoded.displayName} (${decoded.id}):\n'
            '   • Latitud: ${decoded.latitude!.toStringAsFixed(6)}\n'
            '   • Longitud: ${decoded.longitude!.toStringAsFixed(6)}\n'
            '   • Altitud: ${decoded.altitude ?? 0}m\n'
            '   • lat_i=${(decoded.latitude! * 1e7).round()} | lon_i=${(decoded.longitude! * 1e7).round()}',
            hex,
          );
        }
        _logger.node('NODO MESH', '🟢 Nodo descubierto/actualizado: "${decoded.displayName}" (${decoded.id}) | Bat: ${decoded.batteryLevel}% | SNR: ${decoded.snr?.toStringAsFixed(1) ?? "N/A"} dB | Saltos: ${decoded.hopsAway}');
        _nodeInfoController.add(decoded);
      } else if (decoded is MeshtasticTelemetry) {
        final hexId = '!${decoded.nodeNum.toRadixString(16).padLeft(8, '0')}';
        _logger.telemetry('TELEMETRÍA', '⚡ Telemetría de $hexId: Batería ${decoded.batteryLevel}% | Voltaje: ${decoded.voltage?.toStringAsFixed(2) ?? "N/A"}V | Canal: ${decoded.channelUtilization?.toStringAsFixed(1) ?? "0"}% | TX: ${decoded.airUtilTx?.toStringAsFixed(1) ?? "0"}%');
        _telemetryController.add(decoded);
      } else if (decoded is MeshtasticDeviceMetadata) {
        _logger.info('METADATA', 'Datos de hardware: Firmware="${decoded.firmwareVersion}" HWModel=${decoded.hwModel}');
        _metadataController.add(decoded);
      } else if (decoded is MeshtasticInboundMessage) {
        _logger.loraRx('MENSAJE LORA', '💬 Mensaje recibido de ${decoded.senderName}: "${decoded.text}" [RSSI: ${decoded.rssi ?? "N/A"} dBm | SNR: ${decoded.snr?.toStringAsFixed(1) ?? "N/A"} dB | Saltos: ${decoded.hopStart - decoded.hopLimit}]', hex);
        _inboundMessageController.add(decoded);
      } else if (decoded is Map && decoded['type'] == 'config_complete') {
        _logger.info('CONFIG MESH', '✅ Sincronización de configuración completada (Config ID: ${decoded['config_id']})');
      }
    } catch (e) {
      _logger.error('DECODIFICADOR', 'Error procesando paquete FromRadio ($e)', hex);
    }
  }

  /// Transmite un mensaje de texto por la malla LoRa a través de Meshtastic
  Future<bool> sendTextMessage(String text, {int toNodeNum = kBroadcastNodeNum}) async {
    if (_currentState != BleConnectionState.connected || _toRadioCharacteristic == null) {
      _logger.warn('LORA TX', 'No se puede transmitir: WisBlock desconectado.');
      return false;
    }

    try {
      final packet = MeshtasticProtocol.buildTextMessagePacket(
        text: text,
        myNodeNum: _myNodeNum,
        toNodeNum: toNodeNum,
        channel: 0,
        hopLimit: 3,
      );

      final hex = packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      _logger.loraTx('LORA TX', 'Transmitiendo mensaje por LoRa (915 MHz): "$text" (Destino: ${toNodeNum == kBroadcastNodeNum ? "BROADCAST" : "!${toNodeNum.toRadixString(16)}"})', hex);

      final canWriteNoResp = _toRadioCharacteristic!.properties.writeWithoutResponse;
      final canWriteWithResp = _toRadioCharacteristic!.properties.write;

      try {
        await _toRadioCharacteristic!.write(
          packet,
          withoutResponse: canWriteNoResp || !canWriteWithResp,
          timeout: 4,
        );
      } catch (_) {
        await _toRadioCharacteristic!.write(
          packet,
          withoutResponse: !canWriteNoResp,
          timeout: 4,
        );
      }

      return true;
    } catch (e) {
      _logger.error('LORA TX', 'Error enviando paquete al WisBlock: $e');
      return false;
    }
  }

  /// Transmite la posición GPS por la malla LoRa a través de Meshtastic
  Future<bool> sendPosition({
    required double latitude,
    required double longitude,
    int? altitude,
  }) async {
    if (_currentState != BleConnectionState.connected || _toRadioCharacteristic == null) {
      _logger.warn('GPS TX', 'No se puede transmitir ubicación: WisBlock desconectado.');
      return false;
    }

    try {
      // 1. Paquete estándar POSITION_APP (portnum = 3) con precision_bits = 32
      final standardPacket = MeshtasticProtocol.buildPositionPacket(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        myNodeNum: _myNodeNum,
        toNodeNum: kBroadcastNodeNum,
        channel: 0,
        hopLimit: 3,
        portnum: kPortNumPosition,
      );

      // 2. Paquete de alta precisión PRIVATE_APP (portnum = 256)
      // Meshtastic pasa este puerto de forma transparente sin que el firmware aplique
      // el difuminado/fuzzing de privacidad de 13 bits (~1.9 km) del canal
      final exactPacket = MeshtasticProtocol.buildPositionPacket(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        myNodeNum: _myNodeNum,
        toNodeNum: kBroadcastNodeNum,
        channel: 0,
        hopLimit: 3,
        portnum: kPortNumPrivateApp,
      );

      final hexStandard = standardPacket.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      _logger.gps(
        'GPS TX ENVIADO',
        '🚀 Transmitiendo posición GPS dual (Estándar + Alta Precisión Directa):\n'
        '   • Latitud: ${latitude.toStringAsFixed(6)}\n'
        '   • Longitud: ${longitude.toStringAsFixed(6)}\n'
        '   • Altitud: ${altitude ?? 0}m\n'
        '   • lat_i=${(latitude * 1e7).round()} | lon_i=${(longitude * 1e7).round()}\n'
        '   • Canales: POSITION_APP (3) + PRIVATE_APP (256 - anti-fuzzing)',
        hexStandard,
      );

      final canWriteNoResp = _toRadioCharacteristic!.properties.writeWithoutResponse;
      final canWriteWithResp = _toRadioCharacteristic!.properties.write;

      // Enviar paquete estándar
      await _toRadioCharacteristic!.write(
        standardPacket,
        withoutResponse: canWriteNoResp || !canWriteWithResp,
        timeout: 4,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // Enviar paquete de alta precisión directa
      await _toRadioCharacteristic!.write(
        exactPacket,
        withoutResponse: canWriteNoResp || !canWriteWithResp,
        timeout: 4,
      );

      _logger.gps('GPS TX OK', '✅ Posición GPS exacta transmitida por LoRa (inmune al recorte de 1.9km).', hexStandard);
      return true;
    } catch (e) {
      _logger.error('GPS TX', 'Error transmitiendo ubicación GPS: $e');
      return false;
    }
  }

  /// Configura el nombre del nodo en la memoria flash/NVS del WisBlock y lo difunde a la malla LoRa
  Future<bool> setNodeOwner({
    required String longName,
    String? shortName,
  }) async {
    if (_currentState != BleConnectionState.connected || _toRadioCharacteristic == null) {
      _logger.warn('NOMBRE NODO', 'No se puede cambiar el nombre: WisBlock desconectado.');
      return false;
    }

    try {
      final cleanLong = longName.trim();
      String effectiveShort = (shortName ?? '').trim();

      if (effectiveShort.isEmpty) {
        final words = cleanLong.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (words.length >= 2) {
          effectiveShort = words.take(4).map((w) => w[0].toUpperCase()).join();
        } else if (cleanLong.length >= 4) {
          effectiveShort = cleanLong.substring(0, 4).toUpperCase();
        } else {
          effectiveShort = cleanLong.toUpperCase();
        }
      }

      if (effectiveShort.length > 4) {
        effectiveShort = effectiveShort.substring(0, 4);
      }

      // 1. Paquete AdminMessage.set_owner para guardar en NVS del hardware
      final adminPacket = MeshtasticProtocol.buildSetOwnerPacket(
        longName: cleanLong,
        shortName: effectiveShort,
        myNodeNum: _myNodeNum,
      );

      // 2. Paquete NODEINFO_APP para difundir inmediatamente por la malla LoRa
      final nodeInfoPacket = MeshtasticProtocol.buildNodeInfoPacket(
        longName: cleanLong,
        shortName: effectiveShort,
        myNodeNum: _myNodeNum,
      );

      final canWriteNoResp = _toRadioCharacteristic!.properties.writeWithoutResponse;
      final canWriteWithResp = _toRadioCharacteristic!.properties.write;

      // Enviar comando admin al hardware local
      await _toRadioCharacteristic!.write(
        adminPacket,
        withoutResponse: canWriteNoResp || !canWriteWithResp,
        timeout: 4,
      );

      await Future.delayed(const Duration(milliseconds: 150));

      // Difundir NodeInfo por la malla
      await _toRadioCharacteristic!.write(
        nodeInfoPacket,
        withoutResponse: canWriteNoResp || !canWriteWithResp,
        timeout: 4,
      );

      final hex = adminPacket.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      _logger.info('NOMBRE NODO', '🏷️ Nombre de nodo grabado en WisBlock y transmitido a la malla: "$cleanLong" [$effectiveShort]', hex);
      return true;
    } catch (e) {
      _logger.error('NOMBRE NODO', 'Error configurando nombre en WisBlock: $e');
      return false;
    }
  }

  /// Graba una posición fija (Fixed Position) en la memoria Flash/NVS del nodo WisBlock.
  /// Esto hace que el nodo continúe transmitiendo las coordenadas reales del celular
  /// de manera autónoma por la malla LoRa incluso después de desconectar el Bluetooth.
  Future<bool> setFixedPosition({
    required double latitude,
    required double longitude,
    int? altitude,
  }) async {
    if (_currentState != BleConnectionState.connected || _toRadioCharacteristic == null) {
      _logger.warn('POSICIÓN FIJA', 'No se puede fijar ubicación: WisBlock desconectado.');
      return false;
    }

    try {
      final packet = MeshtasticProtocol.buildSetFixedPositionPacket(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        myNodeNum: _myNodeNum,
      );

      final canWriteNoResp = _toRadioCharacteristic!.properties.writeWithoutResponse;
      final canWriteWithResp = _toRadioCharacteristic!.properties.write;

      await _toRadioCharacteristic!.write(
        packet,
        withoutResponse: canWriteNoResp || !canWriteWithResp,
        timeout: 4,
      );

      final hex = packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      _logger.gps(
        'POSICIÓN FIJA FLASH',
        '📍 Ubicación grabada en memoria FLASH de la antena WisBlock:\n'
        '   • Lat: ${latitude.toStringAsFixed(6)}\n'
        '   • Lon: ${longitude.toStringAsFixed(6)}\n'
        '   • Alt: ${altitude ?? 0}m\n'
        '   • La antena mantendrá esta posición de forma autónoma al desconectar el celular.',
        hex,
      );
      return true;
    } catch (e) {
      _logger.error('POSICIÓN FIJA', 'Error grabando posición fija en Flash del nodo: $e');
      return false;
    }
  }

  /// Elimina la posición fija guardada en la memoria Flash/NVS de la radio WisBlock.
  Future<bool> removeFixedPosition() async {
    if (_currentState != BleConnectionState.connected || _toRadioCharacteristic == null) {
      _logger.warn('POSICIÓN FIJA', 'No se puede borrar posición fija: WisBlock desconectado.');
      return false;
    }

    try {
      final packet = MeshtasticProtocol.buildRemoveFixedPositionPacket(
        myNodeNum: _myNodeNum,
      );

      final canWriteNoResp = _toRadioCharacteristic!.properties.writeWithoutResponse;
      final canWriteWithResp = _toRadioCharacteristic!.properties.write;

      await _toRadioCharacteristic!.write(
        packet,
        withoutResponse: canWriteNoResp || !canWriteWithResp,
        timeout: 4,
      );

      final hex = packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      _logger.info('POSICIÓN FIJA', '🧹 Posición fija eliminada de la memoria Flash del WisBlock.', hex);
      return true;
    } catch (e) {
      _logger.error('POSICIÓN FIJA', 'Error eliminando posición fija de Flash: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _handshakeRetryTimer?.cancel();
    _fromRadioSub?.cancel();
    _fromNumSub?.cancel();
    _scanSubscription?.cancel();
    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _toRadioCharacteristic = null;
    _fromRadioCharacteristic = null;
    _fromNumCharacteristic = null;
    _myNodeNum = 0;
    _isDraining = false;
    _setConnectionState(BleConnectionState.disconnected);
    _logger.info('BLE', 'Desconectado del dispositivo WisBlock.');
  }

  void _setConnectionState(BleConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  void dispose() {
    _pollTimer?.cancel();
    _handshakeRetryTimer?.cancel();
    _fromRadioSub?.cancel();
    _fromNumSub?.cancel();
    _scanSubscription?.cancel();
    _connectionStateController.close();
    _myNodeInfoController.close();
    _nodeInfoController.close();
    _telemetryController.close();
    _metadataController.close();
    _inboundMessageController.close();
    _discoveredDevicesController.close();
  }
}
