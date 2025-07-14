import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? bio;
  final int followers;
  final int following;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.bio,
    this.followers = 0,
    this.following = 0,
  });

  /// Boş bir kullanıcı modeli.
  static const empty = UserModel(id: '', name: '', email: '');

  factory UserModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return UserModel(
      id: id ?? json['UID'] ?? json['id'] ?? '',
      name: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['image_url'] ?? json['profileImageUrl'],
      bio: json['bio'],
      followers: (json['followers'] ?? 0).toInt(),
      following: (json['following'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UID': id,
      'fullName': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'image_url': profileImageUrl,
      'bio': bio,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? bio,
    int? followers,
    int? following,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phoneNumber,
    profileImageUrl,
    bio,
    followers,
    following,
  ];
}
