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

  const TravelPlanModel({
    required this.travelId,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.isFavorite = false,
    this.isCompleted = false,
    this.destination,
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
  }) {
    return TravelPlanModel(
      travelId: travelId ?? this.travelId,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isFavorite: isFavorite ?? this.isFavorite,
      isCompleted: isCompleted ?? this.isCompleted,
      destination: destination ?? this.destination,
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
    );
  }
}
