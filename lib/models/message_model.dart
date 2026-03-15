class MessageModel {
  final String senderId;
  final String receiverId;
  final String message;
  final int timestamp;
  final String status;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'status': status,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      status: map['status'] ?? 'sent',
    );
  }
}
