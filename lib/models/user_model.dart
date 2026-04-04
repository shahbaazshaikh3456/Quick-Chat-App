class UserModel {
  final String uid;           // Unique ID for the user / their permanent "ID card" number
  final String name;          // The user's display name / what people see in their chat list
  final String email;         // The user's email address / used for login and identification
  final String profilePhoto;  // Link to their profile picture / the image shown next to their name
  final bool isOnline;        // True or False status / shows if the person is currently in the app
  final int lastSeen;         // A time number / shows exactly when the user was last active
  final String bio;           // A short description / a small "About Me" section for the profile

  // Constructor / used to create a new user profile in the app's memory
  UserModel({
    required this.uid,        // UID is a must / you can't have a user without an ID
    required this.name,       // Name is a must / everyone needs a name to be identified
    required this.email,      // Email is a must / required for account security
    required this.profilePhoto,// Photo is a must / even if it's just a default picture
    required this.isOnline,   // Online status is a must / helps others see if they can chat
    required this.lastSeen,   // Last seen time is a must / tracks user activity
    required this.bio,        // Bio is a must / even if it is left empty at first
  });

  // toMap method / converts the user's info into a format Firebase can save
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,             // Saves the ID / puts the "ID card" number in the database
      'name': name,           // Saves the name / puts the display name in the database
      'email': email,         // Saves the email / stores the contact info in the database
      'profilePhoto': profilePhoto, // Saves the photo link / stores the image path in the database
      'isOnline': isOnline,   // Saves online status / stores the green-dot status in the database
      'lastSeen': lastSeen,   // Saves the time / stores the activity timer in the database
      'bio': bio,             // Saves the bio / stores the "About Me" text in the database
    };
  }

  // fromMap factory / takes data from Firebase and turns it back into a Dart object
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,               // Uses the ID provided by the database / assigns the "ID card"
      name: map['name'] ?? '', // Gets the name / uses empty text if the name is missing
      email: map['email'] ?? '', // Gets the email / uses empty text if the email is missing
      profilePhoto: map['profilePhoto'] ?? '', // Gets the photo link / uses empty text if missing
      isOnline: map['isOnline'] ?? false, // Gets online status / defaults to "offline" if missing
      lastSeen: map['lastSeen'] ?? DateTime.now().millisecondsSinceEpoch, // Gets time / uses current time if missing
      bio: map['bio'] ?? '',  // Gets the bio / uses empty text if the bio is missing
    );
  }

  // copyWith method / used to update only specific parts of the profile
  UserModel copyWith({
    String? name,             // Optional new name / used if user changes their name
    String? profilePhoto,     // Optional new photo / used if user uploads a new picture
    String? bio,              // Optional new bio / used if user edits their "About Me"
    bool? isOnline,           // Optional new status / used when user logs in or out
    int? lastSeen,            // Optional new time / used to update the activity timer
  }) {
    return UserModel(
      uid: uid,               // Keeps the same ID / the "ID card" number never changes
      name: name ?? this.name, // Uses the new name / if no new name, keeps the old one
      email: email,           // Keeps the same email / email stays fixed for the account
      profilePhoto: profilePhoto ?? this.profilePhoto, // Uses new photo / or keeps the old one
      isOnline: isOnline ?? this.isOnline, // Updates status / or keeps the current one
      lastSeen: lastSeen ?? this.lastSeen, // Updates time / or keeps the current one
      bio: bio ?? this.bio,   // Updates bio / or keeps the old one
    );
  }
}
