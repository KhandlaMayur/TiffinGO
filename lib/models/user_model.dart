class UserModel {
  final String fullName;
  final String email;
  final String contact;
  final String password;
  final String role; // 'user' or 'seller'

  UserModel({
    required this.fullName,
    required this.email,
    required this.contact,
    required this.password,
    this.role = 'user',
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'contact': contact,
      'password': password,
      'role': role,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      fullName: json['fullName'],
      email: json['email'],
      contact: json['contact'],
      password: json['password'],
      role: (json['role'] as String?) ?? 'user',
    );
  }
}
