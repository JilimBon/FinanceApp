class UserModel {
  final int? id;
  final String username;
  final String passwordHash;

  UserModel({this.id, required this.username, required this.passwordHash});

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] as int?,
    username: map['username'] as String,
    passwordHash: map['password_hash'] as String,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'password_hash': passwordHash,
  };
}