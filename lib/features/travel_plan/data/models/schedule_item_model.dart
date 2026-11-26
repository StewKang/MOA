import 'package:flutter/foundation.dart';

/// 개별 일정 블록 모델
@immutable
class ScheduleItemModel {
  final String id;
  final String travelId;
  final DateTime date;
  final int startSlotIndex; // 00:00 = 0, 00:30 = 1, ..., 23:30 = 47
  final int durationSlots; // 1슬롯 = 30분
  final String category; // 'activity', 'transport', 'meal', 'custom'
  final String title;
  final String location;
  final String memo;

  // 이동 카테고리 전용 상세 정보
  final String origin; // 출발지
  final String destination; // 목적지
  final String transportMode; // 이동 수단 (예: KTX, 지하철, 버스, 렌터카, 도보 등)

  const ScheduleItemModel({
    required this.id,
    required this.travelId,
    required this.date,
    required this.startSlotIndex,
    required this.durationSlots,
    required this.category,
    required this.title,
    this.location = '',
    this.memo = '',
    this.origin = '',
    this.destination = '',
    this.transportMode = '',
  });

  /// 종료 슬롯 인덱스 (non-inclusive)
  int get endSlotIndex => startSlotIndex + durationSlots;

  /// 시작 시간 포맷 (예: "09:00")
  String get startTimeFormatted {
    final hour = startSlotIndex ~/ 2;
    final minute = (startSlotIndex % 2) * 30;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 종료 시간 포맷 (예: "10:30")
  String get endTimeFormatted {
    final hour = endSlotIndex ~/ 2;
    final minute = (endSlotIndex % 2) * 30;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 소요 시간 포맷 (예: "1시간 30분")
  String get durationFormatted {
    final totalMinutes = durationSlots * 30;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours시간 $minutes분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$minutes분';
    }
  }

  /// 카테고리 표시 한글 라벨
  String get categoryLabel {
    switch (category) {
      case 'activity':
        return '일정';
      case 'transport':
        return '이동';
      case 'meal':
        return '식사';
      case 'custom':
      default:
        return '직접추가';
    }
  }

  /// 장소/위치 또는 출발지->목적지 대표 표시 텍스트
  String get displayLocation {
    if (category == 'transport') {
      final List<String> parts = [];
      if (origin.isNotEmpty && destination.isNotEmpty) {
        parts.add('$origin ➔ $destination');
      } else if (origin.isNotEmpty) {
        parts.add('출발: $origin');
      } else if (destination.isNotEmpty) {
        parts.add('도착: $destination');
      }

      if (transportMode.isNotEmpty) {
        parts.add('($transportMode)');
      }

      if (parts.isNotEmpty) {
        return parts.join(' ');
      }
    }
    return location;
  }

  ScheduleItemModel copyWith({
    String? id,
    String? travelId,
    DateTime? date,
    int? startSlotIndex,
    int? durationSlots,
    String? category,
    String? title,
    String? location,
    String? memo,
    String? origin,
    String? destination,
    String? transportMode,
  }) {
    return ScheduleItemModel(
      id: id ?? this.id,
      travelId: travelId ?? this.travelId,
      date: date ?? this.date,
      startSlotIndex: startSlotIndex ?? this.startSlotIndex,
      durationSlots: durationSlots ?? this.durationSlots,
      category: category ?? this.category,
      title: title ?? this.title,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      transportMode: transportMode ?? this.transportMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'travelId': travelId,
      'date': date.toIso8601String(),
      'startSlotIndex': startSlotIndex,
      'durationSlots': durationSlots,
      'category': category,
      'title': title,
      'location': location,
      'memo': memo,
      'origin': origin,
      'destination': destination,
      'transportMode': transportMode,
    };
  }

  factory ScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return ScheduleItemModel(
      id: json['id'] as String,
      travelId: json['travelId'] as String,
      date: DateTime.parse(json['date'] as String),
      startSlotIndex: json['startSlotIndex'] as int,
      durationSlots: json['durationSlots'] as int,
      category: json['category'] as String,
      title: json['title'] as String,
      location: json['location'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      transportMode: json['transportMode'] as String? ?? '',
    );
  }

  /// SQLite DB 전용 Map 직렬화
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'travel_id': travelId,
      'date': date.toIso8601String(),
      'start_slot_index': startSlotIndex,
      'duration_slots': durationSlots,
      'category': category,
      'title': title,
      'location': location,
      'memo': memo,
      'origin': origin,
      'destination': destination,
      'transport_mode': transportMode,
    };
  }

  /// SQLite DB 전용 Map 역직렬화
  factory ScheduleItemModel.fromSqliteMap(Map<String, dynamic> map) {
    return ScheduleItemModel(
      id: map['id'] as String,
      travelId: map['travel_id'] as String,
      date: DateTime.parse(map['date'] as String),
      startSlotIndex: map['start_slot_index'] as int,
      durationSlots: map['duration_slots'] as int,
      category: map['category'] as String,
      title: map['title'] as String,
      location: map['location'] as String? ?? '',
      memo: map['memo'] as String? ?? '',
      origin: map['origin'] as String? ?? '',
      destination: map['destination'] as String? ?? '',
      transportMode: map['transport_mode'] as String? ?? '',
    );
  }
}
