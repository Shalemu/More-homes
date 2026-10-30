class UserModel {
  final String uuid;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String location;
  final String password;
  final List<int> groups;
  final List<String> permissions;
  final String? profilePictureUrl;

  UserModel({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.location,
    required this.password,
    required this.groups,
    this.permissions = const [],
    this.profilePictureUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      "uuid": uuid,
      "username": email,
      "first_name": firstName,
      "last_name": lastName,
      "phone": phone,
      "email": email,
      "location": location,
      "password": password,
      "groups": groups,
      "permissions": permissions,
      "profile_picture_url": profilePictureUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uuid: json["uuid"] ?? '',
      firstName: json["first_name"] ?? '',
      lastName: json["last_name"] ?? '',
      phone: json["phone"] ?? '',
      email: json["email"] ?? '',
      location: json["location"] ?? '',
      password: json["password"] ?? '',
      groups: List<int>.from(json["groups"] ?? []),
      permissions: List<String>.from(json["permissions"] ?? []),
      profilePictureUrl: json["profile_picture_url"] ??
          json["profile_image_url"] ??
          json["profile_image"],
    );
  }
}
