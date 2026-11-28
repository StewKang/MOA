import 'package:flutter/foundation.dart';

/// 동행자의 출발 지점 정보 DTO
@immutable
class DeparturePoint {
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final String transportMode; // 예: 'car', 'transit', 'walk'

  const DeparturePoint({
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    this.transportMode = 'transit',
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'transportMode': transportMode,
    };
  }

  factory DeparturePoint.fromJson(Map<String, dynamic> json) {
    return DeparturePoint(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      transportMode: json['transportMode'] as String? ?? 'transit',
    );
  }
}

/// 알고리즘에 의해 계산된 중간 집결지 추천 결과 DTO
@immutable
class RecommendedMeetingPoint {
  final String locationName;
  final String address;
  final double latitude;
  final double longitude;
  final int averageTravelTimeMinutes; // 동행자 평균 이동 시간(분)
  final String? description;

  const RecommendedMeetingPoint({
    required this.locationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.averageTravelTimeMinutes,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationName': locationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'averageTravelTimeMinutes': averageTravelTimeMinutes,
      'description': description,
    };
  }

  factory RecommendedMeetingPoint.fromJson(Map<String, dynamic> json) {
    return RecommendedMeetingPoint(
      locationName: json['locationName'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      averageTravelTimeMinutes: json['averageTravelTimeMinutes'] as int,
      description: json['description'] as String?,
    );
  }
}
