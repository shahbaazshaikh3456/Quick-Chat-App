class UserModel {
  final String uid;
  final String name;
  final String email;
  final String profilePhoto;
  final bool isOnline;
  final int lastSeen;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.profilePhoto,
    required this.isOnline,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePhoto': profilePhoto,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePhoto: map['profilePhoto'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
