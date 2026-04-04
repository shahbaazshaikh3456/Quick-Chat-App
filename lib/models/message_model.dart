class MessageModel {
  final String senderId;      // The ID of the person sending the message / tells us who sent it
  final String receiverId;    // The ID of the person getting the message / tells us who it is for
  final String message;       // The actual text typed / the words in the chat
  final int timestamp;        // The time the message was sent / used to show messages in order
  final String status;        // Status like 'sent' or 'seen' / used for read receipts (ticks)
  final String type;          // Type of message (text, image, etc.) / tells the app what to display
  final String? imageUrl;     // Link to an image / used only if a photo is sent
  final String? videoUrl;     // Link to a video / used only if a video is sent
  final String? fileUrl;      // Link to a document / used only if a file is sent
  final String? fileName;     // The name of the file / shows the file name to the user

  // Constructor / used to create a new message object in the app
  MessageModel({
    required this.senderId,   // Sender ID is a must / cannot send without a sender
    required this.receiverId, // Receiver ID is a must / cannot send without a receiver
    required this.message,    // Message text is a must / cannot send an empty message
    required this.timestamp,  // Time is a must / required to keep the chat organized
    required this.status,     // Status is a must / usually starts as 'sent'
    required this.type,       // Type is a must / app needs to know if it's text or media
    this.imageUrl,            // Image is optional / only if needed
    this.videoUrl,            // Video is optional / only if needed
    this.fileUrl,             // File is optional / only if needed
    this.fileName,            // File name is optional / only if needed
  });

  // toMap method / converts the data into a format Firebase understands
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,   // Store senderId in database / gives a label to the ID
      'receiverId': receiverId, // Store receiverId in database / gives a label to the ID
      'message': message,     // Store the text in database / saves the chat words
      'timestamp': timestamp, // Store the time in database / saves when it happened
      'status': status,       // Store the status in database / saves the tick status
      'type': type,           // Store the type in database / saves what kind of message it is
      // These 'if' lines only save media links if they actually exist / keeps database clean
      if (imageUrl != null) 'imageUrl': imageUrl, 
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
    };
  }

  // fromMap factory / takes data from Firebase and turns it back into the app's format
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      // The ?? part provides a default value if data is missing / prevents the app from crashing
      senderId: map['senderId'] ?? '',     // Get senderId / use empty text if not found
      receiverId: map['receiverId'] ?? '', // Get receiverId / use empty text if not found
      message: map['message'] ?? '',       // Get the text / use empty text if not found
      timestamp: map['timestamp'] ?? 0,    // Get the time / use 0 if not found
      status: map['status'] ?? 'sent',     // Get the status / default to 'sent'
      type: map['type'] ?? 'text',         // Get the type / default to 'text'
      imageUrl: map['imageUrl'],           // Get the image link if it exists
      videoUrl: map['videoUrl'],           // Get the video link if it exists
      fileUrl: map['fileUrl'],             // Get the file link if it exists
      fileName: map['fileName'],           // Get the file name if it exists
    );
  }
}
