class XboxDevice {
  final String ip;
  final int port;
  final String name;
  final String liveId;
  final bool isConnected;
  final DateTime lastSeen;

  const XboxDevice({
    required this.ip,
    this.port = 5050,
    required this.name,
    this.liveId = '',
    this.isConnected = false,
    required this.lastSeen,
  });

  XboxDevice copyWith({
    String? ip,
    int? port,
    String? name,
    String? liveId,
    bool? isConnected,
    DateTime? lastSeen,
  }) {
    return XboxDevice(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      name: name ?? this.name,
      liveId: liveId ?? this.liveId,
      isConnected: isConnected ?? this.isConnected,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
    'ip': ip,
    'port': port,
    'name': name,
    'liveId': liveId,
    'lastSeen': lastSeen.toIso8601String(),
  };

  factory XboxDevice.fromJson(Map<String, dynamic> json) {
    return XboxDevice(
      ip: json['ip'] as String,
      port: json['port'] as int? ?? 5050,
      name: json['name'] as String? ?? 'Xbox Console',
      liveId: json['liveId'] as String? ?? '',
      lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'XboxDevice(name: $name, ip: $ip:$port, liveId: $liveId, connected: $isConnected)';
}
