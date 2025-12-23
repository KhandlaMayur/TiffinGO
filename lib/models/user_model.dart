class UserModel {
  final String fullName;
  final String email;
  final String contact;
  final String password;

  UserModel({
    required this.fullName,
    required this.email,
    required this.contact,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'contact': contact,
      'password': password,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      fullName: json['fullName'],
      email: json['email'],
      contact: json['contact'],
      password: json['password'],
    );
  }
}
