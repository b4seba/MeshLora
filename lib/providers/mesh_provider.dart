import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/chat_message.dart';
import '../models/neighbor_node.dart';
import '../models/device_status.dart';
import '../services/ble_service.dart';
import '../services/radio_logger.dart';
import '../services/storage_service.dart';

enum AppFlowScreen {
  splash,
  pairing,
  pairedSuccess,
  nameInput,
  mainNav,
}

class MeshProvider with ChangeNotifier {
  final BleService _bleService = BleService();
  final StorageService _storageService = StorageService();

  AppFlowScreen _currentScreen = AppFlowScreen.splash;
  int _currentTab = 0; // 0: Chat, 1: Vecinos, 2: Estado
  String _userName = 'Usuario LoRa';
  bool _isPaired = false;
  bool _isMapView = false;
  double _mapZoom = 1.0;

  DeviceStatus _deviceStatus = const DeviceStatus();

  // LISTAS DINÁMICAS 100% REALES (Sin datos simulados ni hardcodeados)
  final List<ChatMessage> _messages = [];
  final Map<int, NeighborNode> _nodesMap = {};
  List<DiscoveredRadioDevice> _discoveredDevices = [];

  // GPS REAL DEL TELÉFONO Y DIFUSIÓN LORA
  Position? _currentGpsPosition;
  bool _isGpsActive = false;
  bool _isBroadcastingGps = false;
  String _gpsStatusMessage = 'GPS inactivo';
  StreamSubscription<Position>? _gpsStreamSub;
  Timer? _gpsPeriodicBroadcastTimer;

  StreamSubscription? _bleStateSub;
  StreamSubscription? _myNodeInfoSub;
  StreamSubscription? _nodeInfoSub;
  StreamSubscription? _telemetrySub;
  StreamSubscription? _metadataSub;
  StreamSubscription? _inboundMessageSub;
  StreamSubscription? _discoveredDevicesSub;
  Timer? _presenceTickerTimer;

  AppFlowScreen get currentScreen => _currentScreen;
  int get currentTab => _currentTab;
  String get userName => _userName;
  bool get isPaired => _isPaired;
  bool get isMapView => _isMapView;
  double get mapZoom => _mapZoom;
  DeviceStatus get deviceStatus => _deviceStatus;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<NeighborNode> get neighbors => List.unmodifiable(_nodesMap.values.toList());
  List<DiscoveredRadioDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  BleService get bleService => _bleService;

  Position? get currentGpsPosition => _currentGpsPosition;
  bool get isGpsActive => _isGpsActive;
  bool get isBroadcastingGps => _isBroadcastingGps;
  String get gpsStatusMessage => _gpsStatusMessage;
  double? get myLatitude => _currentGpsPosition?.latitude;
  double? get myLongitude => _currentGpsPosition?.longitude;

  MeshProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    _initBleStreams();
    _startPresenceTicker();
    await _loadStoredPreferences();
    startGpsTrackingAndBroadcast();
  }

  void _startPresenceTicker() {
    _presenceTickerTimer?.cancel();
    _presenceTickerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final activeCount = _nodesMap.values.where((n) => n.isActive).length;
      if (_deviceStatus.activeNodesCount != activeCount) {
        _deviceStatus = _deviceStatus.copyWith(activeNodesCount: activeCount);
      }
      notifyListeners();
    });
  }

  Future<void> _loadStoredPreferences() async {
    final savedName = await _storageService.getUserName();
    if (savedName != null && savedName.isNotEmpty) {
      _userName = savedName;
    }
    final savedMessages = await _storageService.getMessages();
    if (savedMessages != null && savedMessages.isNotEmpty) {
      _messages.addAll(savedMessages);
    }
    notifyListeners();
  }

  void _initBleStreams() {
    // 1. Estado de conexión BLE
    _bleStateSub = _bleService.connectionStateStream.listen((state) {
      if (state == BleConnectionState.connected) {
        _isPaired = true;
        _deviceStatus = _deviceStatus.copyWith(
          isBleConnected: true,
          isLoRaActive: true,
          connectedDeviceName: _bleService.connectedDeviceName,
          connectedDeviceId: _bleService.connectedDeviceId,
        );
        // Si ya tenemos coordenadas GPS del teléfono, compartirlas con la antena WisBlock por BLE/LoRa
        if (_currentGpsPosition != null) {
          Future.delayed(const Duration(seconds: 2), () => broadcastMyLocation());
        }
      } else if (state == BleConnectionState.disconnected) {
        _deviceStatus = _deviceStatus.copyWith(
          isBleConnected: false,
          isLoRaActive: false,
        );
      }
      notifyListeners();
    });

    // 2. Info de la placa local (MyNodeInfo de Meshtastic)
    _myNodeInfoSub = _bleService.myNodeInfoStream.listen((myInfo) {
      _deviceStatus = _deviceStatus.copyWith(
        myNodeNum: myInfo.myNodeNum,
        nodeId: myInfo.nodeHex,
        firmwareVersion: myInfo.firmwareVersion.isNotEmpty ? myInfo.firmwareVersion : _deviceStatus.firmwareVersion,
        channelUtilization: myInfo.channelUtilization > 0 ? myInfo.channelUtilization : _deviceStatus.channelUtilization,
        airUtilTx: myInfo.airUtilTx > 0 ? myInfo.airUtilTx : _deviceStatus.airUtilTx,
        batteryPercent: myInfo.batteryLevel,
        voltage: myInfo.voltage,
        isLoRaActive: true,
      );
      notifyListeners();
    });

    // 3. Metadata del dispositivo (Firmware, modelo)
    _metadataSub = _bleService.metadataStream.listen((meta) {
      if (meta.firmwareVersion.isNotEmpty) {
        _deviceStatus = _deviceStatus.copyWith(
          firmwareVersion: meta.firmwareVersion,
        );
        notifyListeners();
      }
    });

    // 4. Telemetría de la placa local y de nodos de la malla (Batería, Voltaje, Canal)
    _telemetrySub = _bleService.telemetryStream.listen((telemetry) {
      final isLocal = telemetry.nodeNum == _bleService.myNodeNum || _bleService.myNodeNum == 0;

      if (isLocal) {
        _deviceStatus = _deviceStatus.copyWith(
          batteryPercent: telemetry.batteryLevel,
          voltage: telemetry.voltage ?? _deviceStatus.voltage,
          channelUtilization: telemetry.channelUtilization ?? _deviceStatus.channelUtilization,
          airUtilTx: telemetry.airUtilTx ?? _deviceStatus.airUtilTx,
        );
      }

      // Actualizar o registrar en la lista de nodos vecinos si es un nodo remoto
      if (!isLocal && telemetry.nodeNum != 0) {
        if (_nodesMap.containsKey(telemetry.nodeNum)) {
          final current = _nodesMap[telemetry.nodeNum]!;
          _nodesMap[telemetry.nodeNum] = current.copyWith(
            batteryPercent: telemetry.batteryLevel,
            voltage: telemetry.voltage ?? current.voltage,
            lastSeen: DateTime.now(), // Marcado en tiempo real al recibir paquete LoRa
          );
        } else {
          final nodeHex = '!${telemetry.nodeNum.toRadixString(16).padLeft(8, '0')}';
          final nodeName = 'Nodo ${nodeHex.substring(nodeHex.length - 4)}';
          final nodeColor = NeighborNode.pickColorFromNum(telemetry.nodeNum, nodeName);
          final xy = NeighborNode.computeRelativeXY(
            null, null, null, null,
            _nodesMap.length,
            _nodesMap.length + 1,
          );
          _nodesMap[telemetry.nodeNum] = NeighborNode(
            nodeNum: telemetry.nodeNum,
            id: nodeHex,
            name: nodeName,
            shortName: nodeName.length > 4 ? nodeName.substring(0, 4) : nodeName,
            distance: 'Enlace LoRa Directo',
            color: nodeColor,
            xPercent: xy['x'] ?? 50.0,
            yPercent: xy['y'] ?? 50.0,
            isMe: false,
            batteryPercent: telemetry.batteryLevel,
            voltage: telemetry.voltage,
            lastSeen: DateTime.now(),
          );
        }
      }

      notifyListeners();
    });

    // 5. Nodos reales descubiertos en la malla LoRa (NodeInfo de Meshtastic)
    _nodeInfoSub = _bleService.nodeInfoStream.listen((node) {
      final isMe = node.num == _bleService.myNodeNum;
      final nodeName = node.displayName;
      final nodeColor = NeighborNode.pickColorFromNum(node.num, nodeName);

      // Si es mi propio nodo y reporta métricas, actualizar DeviceStatus
      if (isMe) {
        _deviceStatus = _deviceStatus.copyWith(
          batteryPercent: node.batteryLevel,
          voltage: node.voltage ?? _deviceStatus.voltage,
          nodeId: node.id,
        );
      }

      final current = _nodesMap[node.num];
      final lastSeenTime = current?.lastSeen ?? node.lastHeard;
      final resolvedName = (node.longName.isNotEmpty ? node.longName : (current?.name ?? node.displayName));
      final resolvedShortName = (node.shortName.isNotEmpty ? node.shortName : (current?.shortName ?? ''));
      
      // Lógica anti-fuzzing:
      // Si ya teníamos una coordenada de alta precisión (exacta) y el nuevo paquete llega con
      // menor resolución (fuzzed a 13 bits por el canal Meshtastic), conservamos la exacta.
      double? resolvedLat;
      double? resolvedLon;
      bool isHighPrec = current?.isHighPrecision ?? false;
      int precBits = current?.precisionBits ?? 32;

      if (isMe && _currentGpsPosition != null) {
        resolvedLat = _currentGpsPosition!.latitude;
        resolvedLon = _currentGpsPosition!.longitude;
        isHighPrec = true;
        precBits = 32;
      } else {
        if (node.isHighPrecision || node.precisionBits >= 32) {
          resolvedLat = node.latitude ?? current?.latitude;
          resolvedLon = node.longitude ?? current?.longitude;
          isHighPrec = true;
          precBits = 32;
        } else if (node.latitude != null && node.longitude != null) {
          // Viene coordenada con recorte/fuzzing
          if (!isHighPrec || (current?.latitude == null)) {
            resolvedLat = node.latitude;
            resolvedLon = node.longitude;
            isHighPrec = false;
            precBits = node.precisionBits;
          } else {
            // Mantenemos la coordenada de alta precisión ya registrada
            resolvedLat = current!.latitude;
            resolvedLon = current.longitude;
          }
        } else {
          resolvedLat = current?.latitude;
          resolvedLon = current?.longitude;
        }
      }

      String distanceStr = 'Sin GPS';
      if (isMe) {
        distanceStr = 'Mi Nodo';
      } else if (_currentGpsPosition != null && resolvedLat != null && resolvedLon != null) {
        final d = Geolocator.distanceBetween(
          _currentGpsPosition!.latitude,
          _currentGpsPosition!.longitude,
          resolvedLat,
          resolvedLon,
        );
        distanceStr = d < 1000 ? 'a ${d.round()} m' : 'a ${(d / 1000).toStringAsFixed(1)} km';
      } else if (resolvedLat != null && resolvedLon != null) {
        distanceStr = 'GPS fijado';
      } else {
        distanceStr = node.hopsAway > 0 ? '~${node.hopsAway} saltos' : 'Enlace LoRa Directo';
      }

      // Calcular posición relativa cartesiana (fallback o referencia)
      final xy = NeighborNode.computeRelativeXY(
        resolvedLat,
        resolvedLon,
        _currentGpsPosition?.latitude,
        _currentGpsPosition?.longitude,
        _nodesMap.length,
        _nodesMap.length + 1,
      );

      final neighbor = NeighborNode(
        nodeNum: node.num,
        id: node.id,
        name: resolvedName,
        shortName: resolvedShortName,
        distance: distanceStr,
        color: nodeColor,
        latitude: resolvedLat,
        longitude: resolvedLon,
        xPercent: xy['x'] ?? 50.0,
        yPercent: xy['y'] ?? 50.0,
        isMe: isMe,
        batteryPercent: node.batteryLevel,
        voltage: node.voltage ?? current?.voltage,
        snr: node.snr ?? current?.snr,
        lastSeen: lastSeenTime,
        hopsAway: node.hopsAway,
        isHighPrecision: isHighPrec,
        precisionBits: precBits,
      );

      _nodesMap[node.num] = neighbor;

      if (!isMe && resolvedLat != null && resolvedLon != null) {
        RadioLogger().gps(
          'GPS RECIBIDO MALLA',
          '🗺️ Coordenadas de nodo ${neighbor.name} (${neighbor.id}):\n'
          '   • Vecino: Lat=${resolvedLat.toStringAsFixed(6)}, Lon=${resolvedLon.toStringAsFixed(6)}\n'
          '   • Mi Celular: Lat=${_currentGpsPosition?.latitude.toStringAsFixed(6) ?? "N/A"}, Lon=${_currentGpsPosition?.longitude.toStringAsFixed(6) ?? "N/A"}\n'
          '   • Distancia calculada: $distanceStr',
        );
      }

      // Si es la info de mi propio nodo, actualizar mi nombre si no se ha fijado
      if (isMe && node.longName.isNotEmpty && _userName == 'Usuario LoRa') {
        _userName = node.longName;
      }

      notifyListeners();
    });

    // 6. Mensajes de texto reales recibidos por la malla LoRa
    _inboundMessageSub = _bleService.inboundMessageStream.listen((inbound) {
      final isFromOtherNode = inbound.from != 0 && inbound.from != _bleService.myNodeNum;

      // Si el nodo emisor no estaba registrado aún, registrarlo dinámicamente como vecino en la malla
      if (isFromOtherNode && !_nodesMap.containsKey(inbound.from)) {
        final nodeHex = '!${inbound.from.toRadixString(16).padLeft(8, '0')}';
        final nodeName = inbound.senderName.isNotEmpty ? inbound.senderName : 'Nodo ${nodeHex.substring(nodeHex.length - 4)}';
        final nodeColor = NeighborNode.pickColorFromNum(inbound.from, nodeName);
        final xy = NeighborNode.computeRelativeXY(
          null, null, null, null,
          _nodesMap.length,
          _nodesMap.length + 1,
        );

        final newNeighbor = NeighborNode(
          nodeNum: inbound.from,
          id: nodeHex,
          name: nodeName,
          shortName: nodeName.length > 4 ? nodeName.substring(0, 4) : nodeName,
          distance: '~${inbound.hopStart - inbound.hopLimit} saltos LoRa',
          color: nodeColor,
          xPercent: xy['x'] ?? 50.0,
          yPercent: xy['y'] ?? 50.0,
          isMe: false,
          snr: inbound.snr,
          lastSeen: DateTime.now(), // Hora exacta real de recepción de este paquete
          hopsAway: inbound.hopStart - inbound.hopLimit,
        );
        _nodesMap[inbound.from] = newNeighbor;
      } else if (isFromOtherNode && _nodesMap.containsKey(inbound.from)) {
        // Actualizar último contacto y SNR del nodo existente en tiempo real
        final current = _nodesMap[inbound.from]!;
        _nodesMap[inbound.from] = current.copyWith(
          snr: inbound.snr ?? current.snr,
          lastSeen: DateTime.now(), // Hora exacta real de recepción de este paquete
          hopsAway: inbound.hopStart - inbound.hopLimit,
        );
      }

      // Buscar el nombre del remitente en los nodos conocidos
      final senderNode = _nodesMap[inbound.from];
      final senderName = senderNode?.name ?? inbound.senderName;
      final initials = senderNode?.initials ??
          (senderName.length >= 2 ? senderName.substring(0, 2).toUpperCase() : 'ND');
      final avatarColor = senderNode?.color ?? NeighborNode.pickColorFromNum(inbound.from, senderName);

      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderNodeNum: inbound.from,
        name: senderName,
        initials: initials,
        text: inbound.text,
        timestamp: inbound.timestamp,
        fromMe: inbound.from == _bleService.myNodeNum && _bleService.myNodeNum != 0,
        avatarColor: avatarColor,
        isUrgent: inbound.isUrgent,
        rssiDbm: inbound.rssi,
        snr: inbound.snr,
        hops: inbound.hopStart - inbound.hopLimit,
      );

      _messages.add(msg);
      _deviceStatus = _deviceStatus.copyWith(
        totalMessagesTransmitted: _deviceStatus.totalMessagesTransmitted + 1,
        signalDbm: inbound.rssi ?? _deviceStatus.signalDbm,
        snr: inbound.snr ?? _deviceStatus.snr,
      );

      _storageService.saveMessages(_messages);
      notifyListeners();
    });

    // 7. Radios Bluetooth detectadas
    _discoveredDevicesSub = _bleService.discoveredDevicesStream.listen((devices) {
      _discoveredDevices = devices;
      notifyListeners();
    });
  }

  // Navegación de Flujo
  void goToScreen(AppFlowScreen screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  void setTab(int tabIndex) {
    _currentTab = tabIndex;
    notifyListeners();
  }

  void setMapView(bool isMap) {
    _isMapView = isMap;
    notifyListeners();
  }

  void setMapZoom(double zoom) {
    _mapZoom = zoom.clamp(0.8, 2.5);
    notifyListeners();
  }

  void zoomIn() => setMapZoom(_mapZoom + 0.2);
  void zoomOut() => setMapZoom(_mapZoom - 0.2);

  Future<void> refreshAllData() async {
    if (_bleService.currentState == BleConnectionState.connected) {
      await _bleService.requestMeshConfigSync();
      await _bleService.drainFromRadio();
    } else {
      await _bleService.startScan();
    }
    notifyListeners();
  }

  Future<void> startPairingScan() async {
    _currentScreen = AppFlowScreen.pairing;
    notifyListeners();
    await _bleService.startScan();
  }

  Future<void> connectToRadio(dynamic deviceOrId) async {
    final success = await _bleService.connectToDevice(deviceOrId);
    if (success) {
      _isPaired = true;
      await _storageService.saveIsPaired(true);
      _currentScreen = AppFlowScreen.pairedSuccess;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 1400));
      _currentScreen = AppFlowScreen.mainNav;
      notifyListeners();
    }
  }

  Future<void> saveUserNameAndContinue(String name) async {
    _userName = name.trim().isEmpty ? 'Usuario LoRa' : name.trim();
    await _storageService.saveUserName(_userName);
    _currentScreen = AppFlowScreen.mainNav;
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    _userName = clean;
    await _storageService.saveUserName(_userName);
    notifyListeners();
  }

  Future<void> disconnectRadio() async {
    await _bleService.disconnect();
    _isPaired = false;
    _deviceStatus = _deviceStatus.copyWith(
      isBleConnected: false,
      isLoRaActive: false,
      connectedDeviceName: '',
      connectedDeviceId: '',
    );
    notifyListeners();
  }

  Future<void> sendMessage(String text, {bool isUrgent = false}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final userInitials = _userName.length >= 2 ? _userName.substring(0, 2).toUpperCase() : _userName.toUpperCase();

    // 1. Transmitir por la malla LoRa real a través de Meshtastic BLE
    await _bleService.sendTextMessage(cleanText);

    // 2. Registrar en la interfaz local
    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderNodeNum: _bleService.myNodeNum,
      name: 'Yo ($_userName)',
      initials: userInitials,
      text: cleanText,
      timestamp: DateTime.now(),
      fromMe: true,
      avatarColor: const Color(0xFF0A1F44),
      isUrgent: isUrgent || cleanText.toUpperCase().contains('AYUDA') || cleanText.toUpperCase().contains('SOS'),
    );

    _messages.add(newMsg);
    _deviceStatus = _deviceStatus.copyWith(
      totalMessagesTransmitted: _deviceStatus.totalMessagesTransmitted + 1,
    );

    await _storageService.saveMessages(_messages);
    notifyListeners();
  }

  Future<void> sendQuickMessage(String text) async {
    final isUrgent = text.toUpperCase().contains('AYUDA') || text.toUpperCase().contains('SOS');
    await sendMessage(text, isUrgent: isUrgent);
  }

  void clearChatHistory() {
    _messages.clear();
    _storageService.saveMessages([]);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // GESTIÓN DE GPS Y DIFUSIÓN LORA REAL
  // ---------------------------------------------------------------------------

  /// Inicia la lectura del GPS del teléfono y programa la difusión periódica por LoRa
  Future<bool> startGpsTrackingAndBroadcast() async {
    try {
      final hasPermission = await _checkAndRequestGpsPermissions();
      if (!hasPermission) {
        _gpsStatusMessage = 'Permiso GPS denegado';
        notifyListeners();
        return false;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _gpsStatusMessage = 'Ubicación desactivada';
        notifyListeners();
        return false;
      }

      _isGpsActive = true;
      _gpsStatusMessage = 'Buscando señal GPS...';
      notifyListeners();

      // 1. Obtener primera posición inmediata
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        pos = null;
      }

      if (pos != null) {
        _updateMyGpsPosition(pos);
        if (_isPaired) {
          await broadcastMyLocation();
        }
      }

      // 2. Suscribirse a actualizaciones de movimiento del teléfono
      _gpsStreamSub?.cancel();
      _gpsStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // cada 10 metros
        ),
      ).listen((newPos) {
        _updateMyGpsPosition(newPos);
      });

      // 3. Temporizador de re-emisión periódica (cada 60 segundos por LoRa a la malla)
      _gpsPeriodicBroadcastTimer?.cancel();
      _gpsPeriodicBroadcastTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (_isGpsActive && _currentGpsPosition != null && _isPaired) {
          broadcastMyLocation();
        }
      });

      return true;
    } catch (e) {
      _gpsStatusMessage = 'Error GPS: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _checkAndRequestGpsPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  void _updateMyGpsPosition(Position pos) {
    _currentGpsPosition = pos;
    _isGpsActive = true;
    _gpsStatusMessage = 'GPS fijado (±${pos.accuracy.round()}m)';

    RadioLogger().gps(
      'GPS CELULAR',
      '📱 GPS capturado en este teléfono:\n'
      '   • Latitud: ${pos.latitude.toStringAsFixed(6)}\n'
      '   • Longitud: ${pos.longitude.toStringAsFixed(6)}\n'
      '   • Altitud: ${pos.altitude.round()}m\n'
      '   • Precisión: ±${pos.accuracy.toStringAsFixed(1)}m',
    );

    final myNum = _bleService.myNodeNum;
    if (_nodesMap.containsKey(myNum)) {
      final me = _nodesMap[myNum]!;
      _nodesMap[myNum] = me.copyWith(
        latitude: pos.latitude,
        longitude: pos.longitude,
        distance: 'Mi Nodo',
        isHighPrecision: true,
        precisionBits: 32,
      );
    }

    _recalculateAllDistances();
    notifyListeners();
  }

  void _recalculateAllDistances() {
    if (_currentGpsPosition == null) return;
    final myLat = _currentGpsPosition!.latitude;
    final myLon = _currentGpsPosition!.longitude;

    for (final entry in _nodesMap.entries) {
      final node = entry.value;
      if (node.isMe) {
        _nodesMap[entry.key] = node.copyWith(
          latitude: myLat,
          longitude: myLon,
          distance: 'Mi Nodo',
        );
      } else if (node.latitude != null && node.longitude != null) {
        final d = Geolocator.distanceBetween(myLat, myLon, node.latitude!, node.longitude!);
        final distStr = d < 1000 ? 'a ${d.round()} m' : 'a ${(d / 1000).toStringAsFixed(1)} km';
        _nodesMap[entry.key] = node.copyWith(distance: distStr);
      }
    }
  }

  /// Transmite la posición GPS actual del teléfono a la antena WisBlock por BLE
  /// y por ondas LoRa a la malla completa
  Future<bool> broadcastMyLocation() async {
    if (_isBroadcastingGps) return false;
    _isBroadcastingGps = true;
    notifyListeners();

    try {
      if (_currentGpsPosition == null) {
        final hasPermission = await _checkAndRequestGpsPermissions();
        if (!hasPermission) {
          _isBroadcastingGps = false;
          _gpsStatusMessage = 'Permiso denegado';
          notifyListeners();
          return false;
        }
        try {
          _currentGpsPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
        } catch (_) {
          _currentGpsPosition = null;
        }
      }

      if (_currentGpsPosition == null) {
        _isBroadcastingGps = false;
        _gpsStatusMessage = 'Sin señal GPS';
        notifyListeners();
        return false;
      }

      _updateMyGpsPosition(_currentGpsPosition!);

      RadioLogger().gps(
        'GPS BROADCAST',
        '🚀 Transmitiendo posición a la malla LoRa:\n'
        '   • Lat: ${_currentGpsPosition!.latitude.toStringAsFixed(6)}\n'
        '   • Lon: ${_currentGpsPosition!.longitude.toStringAsFixed(6)}\n'
        '   • Alt: ${_currentGpsPosition!.altitude.round()}m',
      );

      // Enviar por BLE a la antena física WisBlock
      final ok = await _bleService.sendPosition(
        latitude: _currentGpsPosition!.latitude,
        longitude: _currentGpsPosition!.longitude,
        altitude: _currentGpsPosition!.altitude.toInt(),
      );

      _gpsStatusMessage = ok ? 'Ubicación emitida por LoRa' : 'Error al emitir';
      return ok;
    } catch (e) {
      _gpsStatusMessage = 'Error transmitiendo GPS: $e';
      return false;
    } finally {
      _isBroadcastingGps = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _gpsStreamSub?.cancel();
    _gpsPeriodicBroadcastTimer?.cancel();
    _presenceTickerTimer?.cancel();
    _bleStateSub?.cancel();
    _myNodeInfoSub?.cancel();
    _nodeInfoSub?.cancel();
    _telemetrySub?.cancel();
    _metadataSub?.cancel();
    _inboundMessageSub?.cancel();
    _discoveredDevicesSub?.cancel();
    _bleService.dispose();
    super.dispose();
  }
}
