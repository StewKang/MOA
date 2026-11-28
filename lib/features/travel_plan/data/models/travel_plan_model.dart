import 'package:flutter/foundation.dart';

/// 전체 여행 계획 메타데이터 모델
@immutable
class TravelPlanModel {
  final String travelId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool isFavorite;
  final bool isCompleted;
  final String? destination;
  final String? ownerId;
  final String? inviteCode;
  final DateTime? updatedAt;

  const TravelPlanModel({
    required this.travelId,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.isFavorite = false,
    this.isCompleted = false,
    this.destination,
    this.ownerId,
    this.inviteCode,
    this.updatedAt,
  });

  /// 여행 기간(일수) 계산
  int get durationInDays {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }

  /// 특정 Day 번호(1부터 시작)에 해당하는 DateTime 반환
  DateTime getDateForDayIndex(int dayIndex) {
    return startDate.add(Duration(days: dayIndex - 1));
  }

  TravelPlanModel copyWith({
    String? travelId,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool? isFavorite,
    bool? isCompleted,
    String? destination,
    String? ownerId,
    String? inviteCode,
    DateTime? updatedAt,
  }) {
    return TravelPlanModel(
      travelId: travelId ?? this.travelId,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isFavorite: isFavorite ?? this.isFavorite,
      isCompleted: isCompleted ?? this.isCompleted,
      destination: destination ?? this.destination,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'travelId': travelId,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isFavorite': isFavorite,
      'isCompleted': isCompleted,
      'destination': destination,
      'ownerId': ownerId,
      'inviteCode': inviteCode,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory TravelPlanModel.fromJson(Map<String, dynamic> json) {
    return TravelPlanModel(
      travelId: json['travelId'] as String,
      title: json['title'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      destination: json['destination'] as String?,
      ownerId: json['ownerId'] as String?,
      inviteCode: json['inviteCode'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// SQLite DB 전용 Map 직렬화
  Map<String, dynamic> toSqliteMap() {
    return {
      'travel_id': travelId,
      'title': title,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'destination': destination,
      'is_favorite': isFavorite ? 1 : 0,
      'is_completed': isCompleted ? 1 : 0,
      'owner_id': ownerId,
      'invite_code': inviteCode,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// SQLite DB 전용 Map 역직렬화
  factory TravelPlanModel.fromSqliteMap(Map<String, dynamic> map) {
    return TravelPlanModel(
      travelId: map['travel_id'] as String,
      title: map['title'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      destination: map['destination'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      ownerId: map['owner_id'] as String?,
      inviteCode: map['invite_code'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
