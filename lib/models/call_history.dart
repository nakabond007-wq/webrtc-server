class CallHistory {
  final String id;
  final String callerId;
  final String receiverId;
  final DateTime timestamp;
  final Duration duration;
  final CallType type;
  final CallStatus status;

  CallHistory({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.timestamp,
    required this.duration,
    required this.type,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'callerId': callerId,
    'receiverId': receiverId,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inSeconds,
    'type': type.toString(),
    'status': status.toString(),
  };

  factory CallHistory.fromJson(Map<String, dynamic> json) => CallHistory(
    id: json['id'],
    callerId: json['callerId'],
    receiverId: json['receiverId'],
    timestamp: DateTime.parse(json['timestamp']),
    duration: Duration(seconds: json['duration']),
    type: CallType.values.firstWhere((e) => e.toString() == json['type']),
    status: CallStatus.values.firstWhere((e) => e.toString() == json['status']),
  );
}

enum CallType {
  incoming,
  outgoing,
  missed,
}

enum CallStatus {
  completed,
  rejected,
  missed,
  failed,
}
