class DeviceSettings {
  const DeviceSettings({this.romLimit = 45, this.vibrationSeconds = 5});

  static const romOptions = [15, 30, 45, 60, 75, 90];
  static const vibrationOptions = [3, 5, 7];
  static const vibrationMargin = 5;

  final int romLimit;
  final int vibrationSeconds;

  int get vibrationStartAngle =>
      (romLimit - vibrationMargin).clamp(0, romLimit);

  DeviceSettings copyWith({int? romLimit, int? vibrationSeconds}) =>
      DeviceSettings(
        romLimit: romLimit ?? this.romLimit,
        vibrationSeconds: vibrationSeconds ?? this.vibrationSeconds,
      );

  Map<String, Object?> toJson() => {
    'romLimit': romLimit,
    'vibrationStartAngle': vibrationStartAngle,
    'vibrationSeconds': vibrationSeconds,
  };
}
