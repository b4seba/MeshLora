import 'package:flutter_test/flutter_test.dart';
import 'package:radio_mesh/models/device_status.dart';
import 'package:radio_mesh/services/meshtastic_protocol.dart';

void main() {
  group('Meshtastic Position & Anti-Fuzzing Protocol Tests', () {
    test('buildPositionPacket encodes full precision and location_source', () {
      final bytes = MeshtasticProtocol.buildPositionPacket(
        latitude: -35.420588,
        longitude: -71.676624,
        altitude: 112,
        myNodeNum: 0xEEE91234,
        portnum: kPortNumPosition,
      );

      expect(bytes, isNotEmpty);

      // Decodificamos el paquete de radio simulado
      final decoded = MeshtasticProtocol.decodeFromRadio(bytes);
      expect(decoded, isA<MeshtasticNode>());
      final node = decoded as MeshtasticNode;

      expect(node.latitude, closeTo(-35.420588, 0.000001));
      expect(node.longitude, closeTo(-71.676624, 0.000001));
      expect(node.altitude, equals(112));
      expect(node.precisionBits, equals(32));
      expect(node.isHighPrecision, isTrue);
    });

    test('buildPositionPacket supports kPortNumPrivateApp anti-fuzzing port', () {
      final bytes = MeshtasticProtocol.buildPositionPacket(
        latitude: -35.420588,
        longitude: -71.676624,
        altitude: 112,
        myNodeNum: 0xEEE91234,
        portnum: kPortNumPrivateApp,
      );

      final decoded = MeshtasticProtocol.decodeFromRadio(bytes);
      expect(decoded, isA<MeshtasticNode>());
      final node = decoded as MeshtasticNode;

      expect(node.latitude, closeTo(-35.420588, 0.000001));
      expect(node.longitude, closeTo(-71.676624, 0.000001));
      expect(node.isHighPrecision, isTrue);
      expect(node.precisionBits, equals(32));
    });

    test('buildNodeInfoPacket encodes user info and decodes back correctly', () {
      final bytes = MeshtasticProtocol.buildNodeInfoPacket(
        longName: 'Juan P. - Central',
        shortName: 'JP01',
        myNodeNum: 0xEEE91234,
      );

      expect(bytes, isNotEmpty);

      final decoded = MeshtasticProtocol.decodeFromRadio(bytes);
      expect(decoded, isA<MeshtasticNode>());
      final node = decoded as MeshtasticNode;

      expect(node.longName, equals('Juan P. - Central'));
      expect(node.shortName, equals('JP01'));
      expect(node.num, equals(0xEEE91234));
      expect(node.id, equals('!eee91234'));
    });

    test('buildSetOwnerPacket creates valid AdminMessage ToRadio packet', () {
      final bytes = MeshtasticProtocol.buildSetOwnerPacket(
        longName: 'Base Maule',
        shortName: 'BM01',
        myNodeNum: 0xEEE91234,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(10));
    });

    test('buildSetFixedPositionPacket encodes AdminMessage set_fixed_position correctly', () {
      final bytes = MeshtasticProtocol.buildSetFixedPositionPacket(
        latitude: -35.420588,
        longitude: -71.676624,
        altitude: 120,
        myNodeNum: 0xEEE91234,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(15));
    });

    test('buildRemoveFixedPositionPacket encodes AdminMessage remove_fixed_position correctly', () {
      final bytes = MeshtasticProtocol.buildRemoveFixedPositionPacket(
        myNodeNum: 0xEEE91234,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(5));
    });

    test('DeviceStatus calculates exact LiPo curve: 3.86V gives 66%, only >=4.20V gives 100%', () {
      const status386 = DeviceStatus(voltage: 3.86, batteryPercent: 100);
      expect(status386.batteryPercent, equals(66)); // Never 100% when 3.86V

      const status420 = DeviceStatus(voltage: 4.20, batteryPercent: 0);
      expect(status420.batteryPercent, equals(100));

      const status370 = DeviceStatus(voltage: 3.70, batteryPercent: 100);
      expect(status370.batteryPercent, equals(50));

      const status320 = DeviceStatus(voltage: 3.20, batteryPercent: 100);
      expect(status320.batteryPercent, equals(0));

      const status00 = DeviceStatus(voltage: 0.0, batteryPercent: 0);
      expect(status00.batteryPercent, equals(0));
    });
  });
}
