import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'radio_logger.dart';

/// Constantes de UUIDs BLE de Meshtastic
const String kMeshtasticServiceUuid = '6ba1b088-ab4d-493a-a325-7208e085189e';
const String kMeshtasticToRadioUuid = 'f75de936-ba35-433c-a08d-dd8855d40ee0'; // Write
const String kMeshtasticToRadioUuidAlt = 'f75c76d2-129e-4dad-a1dd-7866124401e7';
const String kMeshtasticFromRadioUuid = '2c55e69e-4993-11ed-b878-0242ac120002'; // Read / Notify
const String kMeshtasticFromRadioUuidAlt = '8ba2b240-e70e-4368-80b6-12c823fbbf36';
const String kMeshtasticFromNumUuid = 'ed9da18c-a800-4f66-a670-aa7547e34453'; // Notify/Read

/// PortNums estándar en Meshtastic
const int kPortNumTextMessage = 1;   // TEXT_MESSAGE_APP
const int kPortNumPosition = 3;      // POSITION_APP
const int kPortNumNodeInfo = 4;      // NODEINFO_APP
const int kPortNumRouting = 5;       // ROUTING_APP
const int kPortNumAdmin = 6;         // ADMIN_APP
const int kPortNumCompressedText = 7;// TEXT_MESSAGE_COMPRESSED_APP
const int kPortNumTelemetry = 67;    // TELEMETRY_APP
const int kPortNumPrivateApp = 256;  // PRIVATE_APP (canal transparente para GPS exacto sin difuminado de canal)

/// Dirección broadcast en Meshtastic (todos los nodos)
const int kBroadcastNodeNum = 0xFFFFFFFF;

// -----------------------------------------------------------------------------
// Modelos de Datos de Meshtastic
// -----------------------------------------------------------------------------

class MeshtasticMyNodeInfo {
  final int myNodeNum;
  final bool hasGps;
  final String firmwareVersion;
  final int rebootCount;
  final double channelUtilization;
  final double airUtilTx;
  final int batteryLevel;
  final double voltage;

  MeshtasticMyNodeInfo({
    this.myNodeNum = 0,
    this.hasGps = false,
    this.firmwareVersion = '',
    this.rebootCount = 0,
    this.channelUtilization = 0.0,
    this.airUtilTx = 0.0,
    this.batteryLevel = 100,
    this.voltage = 4.2,
  });

  String get nodeHex => '!${myNodeNum.toRadixString(16).padLeft(8, '0')}';
}

class MeshtasticDeviceMetadata {
  final String firmwareVersion;
  final int hwModel;
  final int role;

  MeshtasticDeviceMetadata({
    this.firmwareVersion = '',
    this.hwModel = 0,
    this.role = 0,
  });
}

class MeshtasticTelemetry {
  final int nodeNum;
  final int batteryLevel;
  final double? voltage;
  final double? channelUtilization;
  final double? airUtilTx;
  final int? uptimeSeconds;
  final DateTime timestamp;

  MeshtasticTelemetry({
    required this.nodeNum,
    required this.batteryLevel,
    this.voltage,
    this.channelUtilization,
    this.airUtilTx,
    this.uptimeSeconds,
    required this.timestamp,
  });
}

class MeshtasticNode {
  final int num;
  final String id;
  final String longName;
  final String shortName;
  final String macAddr;
  final double? latitude;
  final double? longitude;
  final int? altitude;
  final int batteryLevel;
  final double? voltage;
  final double? snr;
  final DateTime lastHeard;
  final int hopsAway;
  final bool isMe;
  final bool isHighPrecision;
  final int precisionBits;

  MeshtasticNode({
    required this.num,
    required this.id,
    required this.longName,
    required this.shortName,
    this.macAddr = '',
    this.latitude,
    this.longitude,
    this.altitude,
    this.batteryLevel = 100,
    this.voltage,
    this.snr,
    required this.lastHeard,
    this.hopsAway = 0,
    this.isMe = false,
    this.isHighPrecision = false,
    this.precisionBits = 32,
  });

  String get displayName => longName.isNotEmpty ? longName : (shortName.isNotEmpty ? shortName : id);
}

class MeshtasticInboundMessage {
  final int from;
  final int to;
  final String senderName;
  final String text;
  final int portNum;
  final DateTime timestamp;
  final int? rssi;
  final double? snr;
  final int hopLimit;
  final int hopStart;
  final bool isUrgent;

  MeshtasticInboundMessage({
    required this.from,
    required this.to,
    required this.senderName,
    required this.text,
    required this.portNum,
    required this.timestamp,
    this.rssi,
    this.snr,
    this.hopLimit = 3,
    this.hopStart = 3,
    this.isUrgent = false,
  });
}

// -----------------------------------------------------------------------------
// Decodificador y Codificador Binario Protobuf de Meshtastic
// -----------------------------------------------------------------------------

class MeshtasticProtocol {
  /// Decodifica un paquete `FromRadio` recibido por BLE
  static dynamic decodeFromRadio(Uint8List bytes) {
    if (bytes.isEmpty) return null;

    final reader = _ProtobufReader(bytes);
    while (reader.hasMore) {
      final tag = reader.readTag();
      final fieldNum = tag.fieldNumber;
      final wireType = tag.wireType;

      // Tag 2: MeshPacket (paquete recibido por LoRa o local)
      if (fieldNum == 2 && wireType == _WireType.lengthDelimited) {
        final packetBytes = reader.readBytes();
        return _decodeMeshPacket(packetBytes);
      }
      // Tag 3: MyNodeInfo (info de nuestra placa local conectada por BLE)
      else if (fieldNum == 3 && wireType == _WireType.lengthDelimited) {
        final myInfoBytes = reader.readBytes();
        return _decodeMyNodeInfo(myInfoBytes);
      }
      // Tag 4: NodeInfo (info de un nodo de la malla almacenado en la DB del WisBlock)
      else if (fieldNum == 4 && wireType == _WireType.lengthDelimited) {
        final nodeInfoBytes = reader.readBytes();
        return _decodeNodeInfo(nodeInfoBytes);
      }
      // Tag 5, 13, 17: DeviceMetadata / Config
      else if ((fieldNum == 5 || fieldNum == 13 || fieldNum == 17) && wireType == _WireType.lengthDelimited) {
        final metaBytes = reader.readBytes();
        return _decodeDeviceMetadata(metaBytes);
      }
      // Tag 7: config_complete_id
      else if (fieldNum == 7) {
        final configId = reader.readVarint();
        return {'type': 'config_complete', 'config_id': configId};
      }
      // Fallback para variantes antiguas
      else if (fieldNum == 1 && wireType == _WireType.lengthDelimited) {
        final subBytes = reader.readBytes();
        final res = _decodeMeshPacket(subBytes) ?? _decodeMyNodeInfo(subBytes);
        if (res != null) return res;
      } else {
        reader.skipField(wireType);
      }
    }
    return null;
  }

  static MeshtasticMyNodeInfo _decodeMyNodeInfo(Uint8List bytes) {
    final reader = _ProtobufReader(bytes);
    int nodeNum = 0;
    bool hasGps = false;
    String fw = '';
    int rebootCount = 0;
    double chUtil = 0.0;
    double airUtil = 0.0;

    while (reader.hasMore) {
      final tag = reader.readTag();
      switch (tag.fieldNumber) {
        case 1:
          nodeNum = reader.readVarint();
          break;
        case 2:
          hasGps = reader.readVarint() != 0;
          break;
        case 4:
          fw = reader.readString();
          break;
        case 8:
          rebootCount = reader.readVarint();
          break;
        case 14:
        case 15:
          chUtil = reader.readFloat();
          break;
        case 16:
          airUtil = reader.readFloat();
          break;
        default:
          reader.skipField(tag.wireType);
      }
    }

    return MeshtasticMyNodeInfo(
      myNodeNum: nodeNum,
      hasGps: hasGps,
      firmwareVersion: fw,
      rebootCount: rebootCount,
      channelUtilization: chUtil,
      airUtilTx: airUtil,
    );
  }

  static MeshtasticDeviceMetadata _decodeDeviceMetadata(Uint8List bytes) {
    final reader = _ProtobufReader(bytes);
    String fw = '';
    int hwModel = 0;
    int role = 0;

    while (reader.hasMore) {
      final tag = reader.readTag();
      switch (tag.fieldNumber) {
        case 1:
          fw = reader.readString();
          break;
        case 7:
          role = reader.readVarint();
          break;
        case 9:
          hwModel = reader.readVarint();
          break;
        default:
          reader.skipField(tag.wireType);
      }
    }

    return MeshtasticDeviceMetadata(
      firmwareVersion: fw,
      hwModel: hwModel,
      role: role,
    );
  }

  static MeshtasticNode _decodeNodeInfo(Uint8List bytes) {
    final reader = _ProtobufReader(bytes);
    int num = 0;
    String id = '';
    String longName = '';
    String shortName = '';
    String macAddr = '';
    double? lat;
    double? lon;
    int? alt;
    int battery = 100;
    double? voltage;
    double? snr;
    int lastHeardSec = 0;
    int hops = 0;

    while (reader.hasMore) {
      final tag = reader.readTag();
      switch (tag.fieldNumber) {
        case 1:
          num = reader.readVarint();
          id = '!${num.toRadixString(16).padLeft(8, '0')}';
          break;
        case 2: // User submessage
          final userBytes = reader.readBytes();
          final userReader = _ProtobufReader(userBytes);
          while (userReader.hasMore) {
            final uTag = userReader.readTag();
            if (uTag.fieldNumber == 1) {
              id = userReader.readString();
            } else if (uTag.fieldNumber == 2) {
              longName = userReader.readString();
            } else if (uTag.fieldNumber == 3) {
              shortName = userReader.readString();
            } else if (uTag.fieldNumber == 4) {
              final macBytes = userReader.readBytes();
              macAddr = macBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
            } else {
              userReader.skipField(uTag.wireType);
            }
          }
          break;
        case 3: // Position submessage
          final posBytes = reader.readBytes();
          final posReader = _ProtobufReader(posBytes);
          int? rawLatI;
          int? rawLonI;
          while (posReader.hasMore) {
            final pTag = posReader.readTag();
            if (pTag.fieldNumber == 1) {
              if (pTag.wireType == _WireType.fixed32) {
                rawLatI = posReader.readSFixed32();
                if (rawLatI != 0) lat = rawLatI / 10000000.0;
              } else {
                posReader.skipField(pTag.wireType);
              }
            } else if (pTag.fieldNumber == 2) {
              if (pTag.wireType == _WireType.fixed32) {
                rawLonI = posReader.readSFixed32();
                if (rawLonI != 0) lon = rawLonI / 10000000.0;
              } else {
                posReader.skipField(pTag.wireType);
              }
            } else if (pTag.fieldNumber == 3) {
              alt = posReader.readVarint();
            } else if (pTag.fieldNumber == 11) {
              battery = posReader.readVarint();
            } else {
              posReader.skipField(pTag.wireType);
            }
          }
          if (lat != null && lon != null) {
            final nodeHex = num != 0 ? '!${num.toRadixString(16).padLeft(8, "0")}' : '';
            RadioLogger().gps(
              'GPS EN NODEINFO',
              '📍 Coordenadas en NodeInfo de $nodeHex:\n'
              '   • Latitud: ${lat.toStringAsFixed(6)} (raw: $rawLatI)\n'
              '   • Longitud: ${lon.toStringAsFixed(6)} (raw: $rawLonI)\n'
              '   • Altitud: ${alt ?? 0}m',
            );
          }
          break;
        case 4:
          snr = reader.readFloat();
          break;
        case 5:
          lastHeardSec = reader.readFixed32();
          break;
        case 6: // DeviceMetrics submessage
          final dmBytes = reader.readBytes();
          final dmReader = _ProtobufReader(dmBytes);
          while (dmReader.hasMore) {
            final dTag = dmReader.readTag();
            if (dTag.fieldNumber == 1) {
              battery = dmReader.readVarint();
            } else if (dTag.fieldNumber == 2) {
              voltage = dmReader.readFloat();
            } else {
              dmReader.skipField(dTag.wireType);
            }
          }
          break;
        case 11: // hops_away (Meshtastic protobuf tag 11)
          hops = reader.readVarint();
          break;
        default:
          reader.skipField(tag.wireType);
      }
    }

    DateTime lastHeard = DateTime.now();
    if (lastHeardSec > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(lastHeardSec * 1000);
      if (dt.isAfter(DateTime(2024, 1, 1))) {
        lastHeard = dt;
      }
    }

    return MeshtasticNode(
      num: num,
      id: id.isNotEmpty ? id : '!${num.toRadixString(16).padLeft(8, '0')}',
      longName: longName,
      shortName: shortName,
      macAddr: macAddr,
      latitude: lat,
      longitude: lon,
      altitude: alt,
      batteryLevel: battery,
      voltage: voltage,
      snr: snr,
      lastHeard: lastHeard,
      hopsAway: hops,
    );
  }

  static dynamic _decodeMeshPacket(Uint8List bytes) {
    final reader = _ProtobufReader(bytes);
    int from = 0;
    int to = 0;
    int portnum = 0;
    Uint8List? rawPayload;
    String payloadText = '';
    int? rssi;
    double? snr;
    int hopLimit = 3;
    int hopStart = 3;
    int rxTimeSec = 0;

    while (reader.hasMore) {
      final tag = reader.readTag();
      switch (tag.fieldNumber) {
        case 1:
          from = reader.readFixed32();
          break;
        case 2:
          to = reader.readFixed32();
          break;
        case 4: // Decoded (Data submessage)
          final dataBytes = reader.readBytes();
          final dataReader = _ProtobufReader(dataBytes);
          while (dataReader.hasMore) {
            final dTag = dataReader.readTag();
            if (dTag.fieldNumber == 1) {
              portnum = dataReader.readVarint();
            } else if (dTag.fieldNumber == 2) {
              rawPayload = dataReader.readBytes();
              payloadText = utf8.decode(rawPayload, allowMalformed: true);
            } else {
              dataReader.skipField(dTag.wireType);
            }
          }
          break;
        case 7:
          rxTimeSec = reader.readFixed32();
          break;
        case 8:
          snr = reader.readFloat();
          break;
        case 9:
          hopLimit = reader.readVarint();
          break;
        case 12:
          rssi = reader.readVarint();
          if (rssi > 0x7FFFFFFF) rssi = rssi - 0x100000000;
          break;
        case 15:
          hopStart = reader.readVarint();
          break;
        default:
          reader.skipField(tag.wireType);
      }
    }

    final now = DateTime.now();
    DateTime timestamp = now;
    if (rxTimeSec > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(rxTimeSec * 1000);
      if (dt.isAfter(DateTime(2024, 1, 1)) && dt.isBefore(now.add(const Duration(days: 2)))) {
        timestamp = dt;
      }
    }
    final senderHex = '!${from.toRadixString(16).padLeft(8, '0')}';

    // 1. Mensaje de texto (TEXT_MESSAGE_APP = 1)
    if ((portnum == kPortNumTextMessage || (portnum == 0 && payloadText.isNotEmpty)) && payloadText.isNotEmpty) {
      final isUrgent = payloadText.toUpperCase().contains('AYUDA') ||
          payloadText.toUpperCase().contains('SOS') ||
          payloadText.toUpperCase().contains('EMERGENCIA');

      return MeshtasticInboundMessage(
        from: from,
        to: to,
        senderName: senderHex,
        text: payloadText,
        portNum: portnum,
        timestamp: timestamp,
        rssi: rssi,
        snr: snr,
        hopLimit: hopLimit,
        hopStart: hopStart,
        isUrgent: isUrgent,
      );
    }

    // 2. Telemetría LoRa (TELEMETRY_APP = 67)
    if (portnum == kPortNumTelemetry && rawPayload != null && rawPayload.isNotEmpty) {
      return _decodeTelemetryPayload(from, rawPayload, timestamp);
    }

    // 3. Info de Nodo / Usuario (NODEINFO_APP = 4)
    if (portnum == kPortNumNodeInfo && rawPayload != null && rawPayload.isNotEmpty) {
      return _decodeUserPayload(from, rawPayload, timestamp, snr: snr);
    }

    // 4. Posición GPS (POSITION_APP = 3 o canal directo exacto PRIVATE_APP = 256)
    if ((portnum == kPortNumPosition || portnum == kPortNumPrivateApp) && rawPayload != null && rawPayload.isNotEmpty) {
      return _decodePositionPayload(
        from,
        rawPayload,
        timestamp,
        snr: snr,
        isHighPrecisionPort: portnum == kPortNumPrivateApp,
      );
    }

    return null;
  }

  static MeshtasticTelemetry _decodeTelemetryPayload(int fromNodeNum, Uint8List payloadBytes, DateTime timestamp) {
    final reader = _ProtobufReader(payloadBytes);
    int battery = 100;
    double? voltage;
    double? chUtil;
    double? airUtil;
    int? uptime;

    while (reader.hasMore) {
      final tag = reader.readTag();
      if (tag.fieldNumber == 2 && tag.wireType == _WireType.lengthDelimited) {
        // DeviceMetrics submessage
        final dmBytes = reader.readBytes();
        final dmReader = _ProtobufReader(dmBytes);
        while (dmReader.hasMore) {
          final dTag = dmReader.readTag();
          switch (dTag.fieldNumber) {
            case 1:
              battery = dmReader.readVarint();
              break;
            case 2:
              voltage = dmReader.readFloat();
              break;
            case 3:
              chUtil = dmReader.readFloat();
              break;
            case 4:
              airUtil = dmReader.readFloat();
              break;
            case 5:
              uptime = dmReader.readVarint();
              break;
            default:
              dmReader.skipField(dTag.wireType);
          }
        }
      } else if (tag.fieldNumber == 3 && tag.wireType == _WireType.lengthDelimited) {
        // EnvironmentMetrics submessage
        final envBytes = reader.readBytes();
        final envReader = _ProtobufReader(envBytes);
        while (envReader.hasMore) {
          final eTag = envReader.readTag();
          if (eTag.fieldNumber == 5) {
            voltage = envReader.readFloat();
          } else {
            envReader.skipField(eTag.wireType);
          }
        }
      } else {
        reader.skipField(tag.wireType);
      }
    }

    return MeshtasticTelemetry(
      nodeNum: fromNodeNum,
      batteryLevel: battery,
      voltage: voltage,
      channelUtilization: chUtil,
      airUtilTx: airUtil,
      uptimeSeconds: uptime,
      timestamp: timestamp,
    );
  }

  static MeshtasticNode _decodeUserPayload(int fromNodeNum, Uint8List payloadBytes, DateTime timestamp, {double? snr}) {
    final reader = _ProtobufReader(payloadBytes);
    String id = '!${fromNodeNum.toRadixString(16).padLeft(8, '0')}';
    String longName = '';
    String shortName = '';
    String macAddr = '';

    while (reader.hasMore) {
      final tag = reader.readTag();
      switch (tag.fieldNumber) {
        case 1:
          id = reader.readString();
          break;
        case 2:
          longName = reader.readString();
          break;
        case 3:
          shortName = reader.readString();
          break;
        case 4:
          final macBytes = reader.readBytes();
          macAddr = macBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
          break;
        default:
          reader.skipField(tag.wireType);
      }
    }

    return MeshtasticNode(
      num: fromNodeNum,
      id: id,
      longName: longName,
      shortName: shortName,
      macAddr: macAddr,
      snr: snr,
      lastHeard: timestamp,
    );
  }

  static MeshtasticNode _decodePositionPayload(
    int fromNodeNum,
    Uint8List payloadBytes,
    DateTime timestamp, {
    double? snr,
    bool isHighPrecisionPort = false,
  }) {
    final reader = _ProtobufReader(payloadBytes);
    double? lat;
    double? lon;
    int? alt;
    int battery = 100;
    int? rawLatI;
    int? rawLonI;
    int? precisionBits;

    while (reader.hasMore) {
      final tag = reader.readTag();
      switch (tag.fieldNumber) {
        case 1:
          if (tag.wireType == _WireType.fixed32) {
            rawLatI = reader.readSFixed32();
            if (rawLatI != 0) lat = rawLatI / 10000000.0;
          } else {
            reader.skipField(tag.wireType);
          }
          break;
        case 2:
          if (tag.wireType == _WireType.fixed32) {
            rawLonI = reader.readSFixed32();
            if (rawLonI != 0) lon = rawLonI / 10000000.0;
          } else {
            reader.skipField(tag.wireType);
          }
          break;
        case 3:
          alt = reader.readVarint();
          break;
        case 11:
          battery = reader.readVarint();
          break;
        case 23:
          precisionBits = reader.readVarint();
          break;
        default:
          reader.skipField(tag.wireType);
      }
    }

    final hexId = '!${fromNodeNum.toRadixString(16).padLeft(8, '0')}';
    final effectiveBits = isHighPrecisionPort ? 32 : (precisionBits ?? 32);
    final isFuzzed = !isHighPrecisionPort && precisionBits != null && precisionBits < 32;

    if (lat != null && lon != null) {
      RadioLogger().gps(
        isHighPrecisionPort ? 'GPS DIRECTO EXACTO' : 'GPS EN POSITION_APP',
        '📍 Coordenadas de $hexId:\n'
        '   • Latitud: ${lat.toStringAsFixed(6)} (raw: $rawLatI)\n'
        '   • Longitud: ${lon.toStringAsFixed(6)} (raw: $rawLonI)\n'
        '   • Altitud: ${alt ?? 0}m\n'
        '   • Precisión bits: $effectiveBits'
        '${isFuzzed ? ' ⚠️ (DIFUMINADO a ${precisionBits}b por canal WisBlock: desvío ~1.9km)' : ' (Exacta / 1m)'}',
      );
    } else {
      RadioLogger().warn(
        'GPS SIN LOCK',
        '⚠️ Paquete de posición recibido de $hexId pero con coordenadas en 0 (sin fijación de satélites).',
      );
    }

    return MeshtasticNode(
      num: fromNodeNum,
      id: hexId,
      longName: '',
      shortName: '',
      latitude: lat,
      longitude: lon,
      altitude: alt,
      batteryLevel: battery,
      snr: snr,
      lastHeard: timestamp,
      isHighPrecision: isHighPrecisionPort || (precisionBits != null && precisionBits >= 32),
      precisionBits: effectiveBits,
    );
  }

  /// Construye un paquete `ToRadio` para solicitar la configuración inicial de la malla (`want_config_id`)
  static Uint8List buildWantConfigPacket(int configId) {
    final writer = _ProtobufWriter();
    // ToRadio field 3: want_config_id (uint32)
    writer.writeVarintField(3, configId);
    return writer.toBytes();
  }

  /// Construye un paquete `ToRadio` con un `MeshPacket` de texto para transmitir por la malla LoRa
  static Uint8List buildTextMessagePacket({
    required String text,
    int myNodeNum = 0,
    int toNodeNum = kBroadcastNodeNum,
    int channel = 0,
    int hopLimit = 3,
  }) {
    final rand = Random();
    final packetId = rand.nextInt(0x7FFFFFFF);

    // 1. Data submessage
    final dataWriter = _ProtobufWriter();
    dataWriter.writeVarintField(1, kPortNumTextMessage); // portnum = TEXT_MESSAGE_APP
    dataWriter.writeBytesField(2, utf8.encode(text));    // payload = UTF-8 text
    dataWriter.writeVarintField(3, 1);                   // want_response = true
    final dataBytes = dataWriter.toBytes();

    // 2. MeshPacket submessage
    final packetWriter = _ProtobufWriter();
    if (myNodeNum > 0) {
      packetWriter.writeFixed32Field(1, myNodeNum);     // from
    }
    packetWriter.writeFixed32Field(2, toNodeNum);        // to (0xFFFFFFFF = broadcast)
    packetWriter.writeVarintField(3, channel);          // channel
    packetWriter.writeBytesField(4, dataBytes);          // decoded (Data)
    packetWriter.writeFixed32Field(6, packetId);         // id
    packetWriter.writeVarintField(9, hopLimit);          // hop_limit
    packetWriter.writeVarintField(10, 1);                // want_ack = true
    final meshPacketBytes = packetWriter.toBytes();

    // 3. ToRadio message (field 1: packet)
    final toRadioWriter = _ProtobufWriter();
    toRadioWriter.writeBytesField(1, meshPacketBytes);

    return toRadioWriter.toBytes();
  }

  /// Construye un paquete `ToRadio` con un `MeshPacket` de posición GPS para transmitir por la malla LoRa
  static Uint8List buildPositionPacket({
    required double latitude,
    required double longitude,
    int? altitude,
    int myNodeNum = 0,
    int toNodeNum = kBroadcastNodeNum,
    int channel = 0,
    int hopLimit = 3,
    int portnum = kPortNumPosition,
  }) {
    final rand = Random();
    final packetId = rand.nextInt(0x7FFFFFFF);

    // 1. Position submessage
    final posWriter = _ProtobufWriter();
    // latitude_i: sfixed32 = round(latitude * 1e7)
    posWriter.writeSFixed32Field(1, (latitude * 10000000.0).round());
    // longitude_i: sfixed32 = round(longitude * 1e7)
    posWriter.writeSFixed32Field(2, (longitude * 10000000.0).round());
    if (altitude != null) {
      posWriter.writeVarintField(3, altitude);
    }
    posWriter.writeFixed32Field(4, DateTime.now().millisecondsSinceEpoch ~/ 1000);
    // location_source = 3 (LOC_EXTERNAL: GPS nativo de alta precisión desde el teléfono)
    posWriter.writeVarintField(5, 3);
    // precision_bits = 32 (Máxima resolución exacta sin fuzzing de privacidad)
    posWriter.writeVarintField(23, 32);
    final posBytes = posWriter.toBytes();

    // 2. Data submessage
    final dataWriter = _ProtobufWriter();
    dataWriter.writeVarintField(1, portnum); // POSITION_APP (3) o PRIVATE_APP (256)
    dataWriter.writeBytesField(2, posBytes);          // payload = Position protobuf
    dataWriter.writeVarintField(3, 0);                // want_response = false
    final dataBytes = dataWriter.toBytes();

    // 3. MeshPacket submessage
    final packetWriter = _ProtobufWriter();
    if (myNodeNum > 0) {
      packetWriter.writeFixed32Field(1, myNodeNum);   // from
    }
    packetWriter.writeFixed32Field(2, toNodeNum);      // to (0xFFFFFFFF = broadcast)
    packetWriter.writeVarintField(3, channel);        // channel
    packetWriter.writeBytesField(4, dataBytes);        // decoded (Data)
    packetWriter.writeFixed32Field(6, packetId);       // id
    packetWriter.writeVarintField(9, hopLimit);        // hop_limit
    packetWriter.writeVarintField(10, 0);               // want_ack = false
    final meshPacketBytes = packetWriter.toBytes();

    // 4. ToRadio message (field 1: packet)
    final toRadioWriter = _ProtobufWriter();
    toRadioWriter.writeBytesField(1, meshPacketBytes);

    return toRadioWriter.toBytes();
  }
}

// -----------------------------------------------------------------------------
// Helpers de Lectura y Escritura Protobuf
// -----------------------------------------------------------------------------

enum _WireType {
  varint,
  fixed64,
  lengthDelimited,
  fixed32,
}

class _ProtobufTag {
  final int fieldNumber;
  final _WireType wireType;
  _ProtobufTag(this.fieldNumber, this.wireType);
}

class _ProtobufReader {
  final Uint8List _buffer;
  int _offset = 0;

  _ProtobufReader(this._buffer);

  bool get hasMore => _offset < _buffer.length;

  _ProtobufTag readTag() {
    final value = readVarint();
    final wireTypeVal = value & 0x07;
    final fieldNum = value >> 3;
    _WireType wireType;
    switch (wireTypeVal) {
      case 0:
        wireType = _WireType.varint;
        break;
      case 1:
        wireType = _WireType.fixed64;
        break;
      case 2:
        wireType = _WireType.lengthDelimited;
        break;
      case 5:
        wireType = _WireType.fixed32;
        break;
      default:
        wireType = _WireType.varint;
    }
    return _ProtobufTag(fieldNum, wireType);
  }

  int readVarint() {
    int result = 0;
    int shift = 0;
    while (_offset < _buffer.length) {
      final byte = _buffer[_offset++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
      if (shift >= 64) break;
    }
    return result;
  }

  int readFixed32() {
    if (_offset + 4 > _buffer.length) return 0;
    final byteData = ByteData.sublistView(_buffer, _offset, _offset + 4);
    _offset += 4;
    return byteData.getUint32(0, Endian.little);
  }

  int readSFixed32() {
    if (_offset + 4 > _buffer.length) return 0;
    final byteData = ByteData.sublistView(_buffer, _offset, _offset + 4);
    _offset += 4;
    return byteData.getInt32(0, Endian.little);
  }

  double readFloat() {
    if (_offset + 4 > _buffer.length) return 0.0;
    final byteData = ByteData.sublistView(_buffer, _offset, _offset + 4);
    _offset += 4;
    return byteData.getFloat32(0, Endian.little);
  }

  Uint8List readBytes() {
    final length = readVarint();
    if (_offset + length > _buffer.length) return Uint8List(0);
    final bytes = _buffer.sublist(_offset, _offset + length);
    _offset += length;
    return bytes;
  }

  String readString() {
    final bytes = readBytes();
    return utf8.decode(bytes, allowMalformed: true);
  }

  void skipField(_WireType wireType) {
    switch (wireType) {
      case _WireType.varint:
        readVarint();
        break;
      case _WireType.fixed64:
        _offset = min(_offset + 8, _buffer.length);
        break;
      case _WireType.lengthDelimited:
        final len = readVarint();
        _offset = min(_offset + len, _buffer.length);
        break;
      case _WireType.fixed32:
        _offset = min(_offset + 4, _buffer.length);
        break;
    }
  }
}

class _ProtobufWriter {
  final List<int> _bytes = [];

  Uint8List toBytes() => Uint8List.fromList(_bytes);

  void writeVarint(int value) {
    while (value >= 0x80) {
      _bytes.add((value & 0x7F) | 0x80);
      value >>= 7;
    }
    _bytes.add(value & 0x7F);
  }

  void writeTag(int fieldNumber, _WireType wireType) {
    int wireVal = 0;
    switch (wireType) {
      case _WireType.varint:
        wireVal = 0;
        break;
      case _WireType.lengthDelimited:
        wireVal = 2;
        break;
      case _WireType.fixed32:
        wireVal = 5;
        break;
      default:
        wireVal = 0;
    }
    writeVarint((fieldNumber << 3) | wireVal);
  }

  void writeVarintField(int fieldNumber, int value) {
    writeTag(fieldNumber, _WireType.varint);
    writeVarint(value);
  }

  void writeFixed32Field(int fieldNumber, int value) {
    writeTag(fieldNumber, _WireType.fixed32);
    final bd = ByteData(4)..setUint32(0, value, Endian.little);
    _bytes.addAll(bd.buffer.asUint8List());
  }

  void writeSFixed32Field(int fieldNumber, int value) {
    writeTag(fieldNumber, _WireType.fixed32);
    final bd = ByteData(4)..setInt32(0, value, Endian.little);
    _bytes.addAll(bd.buffer.asUint8List());
  }

  void writeBytesField(int fieldNumber, List<int> bytes) {
    writeTag(fieldNumber, _WireType.lengthDelimited);
    writeVarint(bytes.length);
    _bytes.addAll(bytes);
  }
}
