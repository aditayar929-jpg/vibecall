import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final List<String> photos;
  final String bio;
  final String gender;
  final int age;
  final String location;
  final List<String> interests;
  final bool isOnline;
  final bool isVerified;
  final bool isPremium;
  final int coins;
  final int followers;
  final int following;
  final int profileCompletion;
  final DateTime? lastSeen;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.avatar = '',
    this.photos = const [],
    this.bio = '',
    this.gender = '',
    this.age = 0,
    this.location = '',
    this.interests = const [],
    this.isOnline = false,
    this.isVerified = false,
    this.isPremium = false,
    this.coins = 0,
    this.followers = 0,
    this.following = 0,
    this.profileCompletion = 0,
    this.lastSeen,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      avatar: map['avatar'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      bio: map['bio'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age'] ?? 0,
      location: map['location'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      isOnline: map['isOnline'] ?? false,
      isVerified: map['isVerified'] ?? false,
      isPremium: map['isPremium'] ?? false,
      coins: map['coins'] ?? 0,
      followers: map['followers'] ?? 0,
      following: map['following'] ?? 0,
      profileCompletion: map['profileCompletion'] ?? 0,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'photos': photos,
      'bio': bio,
      'gender': gender,
      'age': age,
      'location': location,
      'interests': interests,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'isPremium': isPremium,
      'coins': coins,
      'followers': followers,
      'following': following,
      'profileCompletion': profileCompletion,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    List<String>? photos,
    String? bio,
    String? gender,
    int? age,
    String? location,
    List<String>? interests,
    bool? isOnline,
    bool? isVerified,
    bool? isPremium,
    int? coins,
    int? followers,
    int? following,
    int? profileCompletion,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      photos: photos ?? this.photos,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      coins: coins ?? this.coins,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
    );
  }
}
