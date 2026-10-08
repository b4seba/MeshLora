class DeviceStatus {
  final int myNodeNum;
  final String nodeId;
  final int _rawBatteryPercent;
  final double voltage;
  final bool isCharging;
  final int signalDbm;
  final double snr;
  final double channelUtilization;
  final double airUtilTx;
  final int activeNodesCount;
  final int totalMessagesTransmitted;
  final String hardwareModel;
  final String firmwareVersion;
  final double frequencyMhz;
  final bool isLoRaActive;
  final bool isBleConnected;
  final String connectedDeviceName;
  final String connectedDeviceId;

  const DeviceStatus({
    this.myNodeNum = 0,
    this.nodeId = 'Sin vincular',
    int batteryPercent = 0,
    this.voltage = 0.0,
    this.isCharging = false,
    this.signalDbm = 0,
    this.snr = 0.0,
    this.channelUtilization = 0.0,
    this.airUtilTx = 0.0,
    this.activeNodesCount = 0,
    this.totalMessagesTransmitted = 0,
    this.hardwareModel = 'WisBlock RAK4630 (Meshtastic)',
    this.firmwareVersion = '--',
    this.frequencyMhz = 915.0,
    this.isLoRaActive = false,
    this.isBleConnected = false,
    this.connectedDeviceName = '',
    this.connectedDeviceId = '',
  }) : _rawBatteryPercent = batteryPercent;

  /// Porcentaje de batería LiPo calculado estrictamente por voltaje (3.20V a 4.20V)
  /// Solo marca 100% si el voltaje alcanza o supera los 4.20V reales.
  int get batteryPercent {
    if (voltage > 0.0) {
      if (voltage >= 4.20) return 100;
      if (voltage <= 3.20) return 0;
      return ((voltage - 3.20) / (4.20 - 3.20) * 100).clamp(0, 100).round();
    }
    return (_rawBatteryPercent > 0 && _rawBatteryPercent < 100) ? _rawBatteryPercent : 0;
  }

  DeviceStatus copyWith({
    int? myNodeNum,
    String? nodeId,
    int? batteryPercent,
    double? voltage,
    bool? isCharging,
    int? signalDbm,
    double? snr,
    double? channelUtilization,
    double? airUtilTx,
    int? activeNodesCount,
    int? totalMessagesTransmitted,
    String? hardwareModel,
    String? firmwareVersion,
    double? frequencyMhz,
    bool? isLoRaActive,
    bool? isBleConnected,
    String? connectedDeviceName,
    String? connectedDeviceId,
  }) {
    return DeviceStatus(
      myNodeNum: myNodeNum ?? this.myNodeNum,
      nodeId: nodeId ?? this.nodeId,
      batteryPercent: batteryPercent ?? _rawBatteryPercent,
      voltage: voltage ?? this.voltage,
      isCharging: isCharging ?? this.isCharging,
      signalDbm: signalDbm ?? this.signalDbm,
      snr: snr ?? this.snr,
      channelUtilization: channelUtilization ?? this.channelUtilization,
      airUtilTx: airUtilTx ?? this.airUtilTx,
      activeNodesCount: activeNodesCount ?? this.activeNodesCount,
      totalMessagesTransmitted: totalMessagesTransmitted ?? this.totalMessagesTransmitted,
      hardwareModel: hardwareModel ?? this.hardwareModel,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      frequencyMhz: frequencyMhz ?? this.frequencyMhz,
      isLoRaActive: isLoRaActive ?? this.isLoRaActive,
      isBleConnected: isBleConnected ?? this.isBleConnected,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
    );
  }

  String get batteryRemainingEstimated {
    if (voltage <= 0.0 && batteryPercent <= 0) return 'Esperando telemetría...';
    final hours = (batteryPercent * 0.28).round();
    return voltage > 0 
        ? '${voltage.toStringAsFixed(2)} V · Aprox. $hours horas restantes'
        : 'Aprox. $hours horas restantes';
  }
}
