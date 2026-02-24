import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? gender;

  final String? phoneNumber;
  final String? photoUrl;

  final DateTime createdAt;
  final double? trustScore;
  final bool? isVerified;

  final double? lastLatitude;
  final double? lastLongitude;

  final String? emergencyName;
  final String? emergencyContact;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.gender,
    this.phoneNumber,
    this.photoUrl,
    required this.createdAt,
    this.trustScore,
    this.isVerified,
    this.lastLatitude,
    this.lastLongitude,
    this.emergencyName,
    this.emergencyContact,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'trustScore': trustScore,
      'isVerified': isVerified,
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
      'emergencyName': emergencyName,
      'emergencyContact': emergencyContact,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      gender: json['gender'],
      phoneNumber: json['phoneNumber'],
      photoUrl: json['photoUrl'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      trustScore: (json['trustScore'] as num?)?.toDouble(),
      isVerified: json['isVerified'],
      lastLatitude: (json['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (json['lastLongitude'] as num?)?.toDouble(),
      emergencyName: json['emergencyName'],
      emergencyContact: json['emergencyContact'],
    );
  }
}
