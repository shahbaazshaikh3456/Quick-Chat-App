class MessageModel {
  final String senderId;
  final String receiverId;
  final String message;
  final int timestamp;
  final String status;
  final String type; // text | image | video | file
  final String? imageUrl;
  final String? videoUrl;
  final String? fileUrl;
  final String? fileName;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.status,
    required this.type,
    this.imageUrl,
    this.videoUrl,
    this.fileUrl,
    this.fileName,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'status': status,
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      status: map['status'] ?? 'sent',
      type: map['type'] ?? 'text',
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
    );
  }
}
