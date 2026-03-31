/// Represents a user within the Quick Chat application.
/// Stores essential profile information and real-time status.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String profilePhoto;
  final bool isOnline;
  final int lastSeen;
  final String bio;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.profilePhoto,
    required this.isOnline,
    required this.lastSeen,
    required this.bio,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePhoto': profilePhoto,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'bio': bio,
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
      bio: map['bio'] ?? '',
    );
  }

  UserModel copyWith({
    String? name,
    String? profilePhoto,
    String? bio,
    bool? isOnline,
    int? lastSeen,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      bio: bio ?? this.bio,
    );
  }
}
