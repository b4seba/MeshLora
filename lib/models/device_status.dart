class DeviceStatus {
  final int myNodeNum;
  final String nodeId;
  final int batteryPercent;
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
    this.batteryPercent = 0,
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
  });

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
      batteryPercent: batteryPercent ?? this.batteryPercent,
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
    if (batteryPercent <= 0) return 'Conectando telemetría...';
    final hours = (batteryPercent * 0.28).round();
    return voltage > 0 
        ? '$voltage V · Aprox. $hours horas restantes'
        : 'Aprox. $hours horas restantes';
  }
}
