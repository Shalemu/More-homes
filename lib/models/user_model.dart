class UserModel {
  final String? uuid;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? username;
  final String? location;
  final String? gender;
  final String? dateOfBirth;
  final String? profilePictureUrl;
  final double? serviceCharge;
  final String? password;
  final List<String>? permissions;
  final List<String>? groups;

  UserModel({
    this.uuid,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.username,
    this.location,
    this.gender,
    this.dateOfBirth,
    this.profilePictureUrl,
    this.serviceCharge,
    this.password,
    this.permissions,
    this.groups,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uuid: json['uuid'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      email: json['email'],
      username: json['username'],
      location: json['location'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      profilePictureUrl: json['profile_picture_url'],
      serviceCharge: json['service_charge'] != null
          ? double.tryParse(json['service_charge'].toString())
          : null,
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
      groups: json['groups'] != null
          ? List<String>.from(json['groups'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'username': username,
      'location': location,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'profile_picture_url': profilePictureUrl,
      'service_charge': serviceCharge,
      'password': password,
      'permissions': permissions,
      'groups': groups,
    };
  }
}
