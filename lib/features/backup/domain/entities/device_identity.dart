class DeviceIdentity {
  const DeviceIdentity({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.firstSeenAt,
    required this.appVersion,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime firstSeenAt;
  final String appVersion;
}
