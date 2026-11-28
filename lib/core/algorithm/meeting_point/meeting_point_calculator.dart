import 'meeting_point_model.dart';

/// [인터페이스] 이동시간 기반 최적 중간 집결지 계산 알고리즘 서비스
/// 다른 팀원이 이 추상 클래스를 상속받아 실제 알고리즘(예: Weighted Centroid, Transit API 등)을 구현하게 됩니다.
abstract class MeetingPointCalculator {
  /// 여러 동행자의 출발지 목록을 기반으로 최적의 중간 집결지 장소들을 계산합니다.
  Future<List<RecommendedMeetingPoint>> calculateOptimalMeetingPoints(
    List<DeparturePoint> departures,
  );
}

/// [더미/테스트 구현체] 다른 팀원의 실제 알고리즘 완성 전까지 기본 탑재되는 예시 서비스
class DefaultMeetingPointCalculator implements MeetingPointCalculator {
  @override
  Future<List<RecommendedMeetingPoint>> calculateOptimalMeetingPoints(
    List<DeparturePoint> departures,
  ) async {
    if (departures.isEmpty) {
      return [];
    }

    // 1. 위경도 단순 평균값(중심점) 계산
    double totalLat = 0.0;
    double totalLng = 0.0;

    for (final point in departures) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    final avgLat = totalLat / departures.length;
    final avgLng = totalLng / departures.length;

    // 2. 가상 예시 집결지 장소 반환
    return [
      RecommendedMeetingPoint(
        locationName: '중간 지점 강남역 (추천 1위)',
        address: '서울특별시 강남구 강남대로 396',
        latitude: avgLat,
        longitude: avgLng,
        averageTravelTimeMinutes: 25,
        description: '참여자 이동 시간 편차가 가장 적은 최적 지점입니다.',
      ),
      RecommendedMeetingPoint(
        locationName: '고속터미널역 (대중교통 환승 우수)',
        address: '서울특별시 서초구 신반포로 188',
        latitude: avgLat + 0.01,
        longitude: avgLng - 0.01,
        averageTravelTimeMinutes: 30,
        description: '지하철 3/7/9호선 환승이 편리한 지점입니다.',
      ),
    ];
  }
}
