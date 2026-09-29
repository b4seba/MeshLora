import 'package:flutter_test/flutter_test.dart';
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
  });
}
