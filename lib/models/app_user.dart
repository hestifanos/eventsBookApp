class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String role;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
  });

  // from the app to firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
    };
  }

  // from firestore to the app
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      role: map['role'] as String? ?? 'student',
    );
  }
}
