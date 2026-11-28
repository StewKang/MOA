import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moa/features/travel_plan/data/models/schedule_item_model.dart';
import 'package:moa/features/travel_plan/data/models/travel_plan_model.dart';
import 'package:moa/features/travel_plan/data/repositories/travel_plan_repository.dart';

/// Firebase Firestore 기반 원격 저장소 Repository 구현체
class FirebaseTravelPlanRepository implements TravelPlanRepository {
  final FirebaseFirestore _firestore;

  FirebaseTravelPlanRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore 컬렉션 레퍼런스
  CollectionReference<Map<String, dynamic>> get _plansCollection =>
      _firestore.collection('travel_plans');

  @override
  Future<List<TravelPlanModel>> getAllTravelPlans() async {
    try {
      final snapshot = await _plansCollection
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['travelId'] = doc.id;
        return TravelPlanModel.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<TravelPlanModel>> getPastTravelPlans() async {
    try {
      final snapshot = await _plansCollection
          .where('isCompleted', isEqualTo: true)
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['travelId'] = doc.id;
        return TravelPlanModel.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<TravelPlanModel?> getTravelPlanById(String travelId) async {
    try {
      final doc = await _plansCollection.doc(travelId).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      data['travelId'] = doc.id;
      return TravelPlanModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveTravelPlan(TravelPlanModel plan) async {
    final docRef = _plansCollection.doc(plan.travelId);
    final json = plan.toJson();
    json['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(json, SetOptions(merge: true));
  }

  @override
  Future<List<ScheduleItemModel>> getScheduleItems(String travelId) async {
    try {
      final snapshot = await _plansCollection
          .doc(travelId)
          .collection('schedules')
          .orderBy('date', descending: false)
          .orderBy('startSlotIndex', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['travelId'] = travelId;
        return ScheduleItemModel.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveScheduleItems(
      String travelId, List<ScheduleItemModel> items) async {
    final batch = _firestore.batch();
    final schedulesRef =
        _plansCollection.doc(travelId).collection('schedules');

    // 1. 기존 일정을 일괄 삭제 후 재등록 (덮어쓰기 동기화)
    final existingSnapshot = await schedulesRef.get();
    for (final doc in existingSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. 신규 일정 배치 등록
    for (final item in items) {
      final itemDocRef = schedulesRef.doc(item.id);
      batch.set(itemDocRef, item.toJson());
    }

    await batch.commit();
  }

  @override
  Future<void> deleteTravelPlan(String travelId) async {
    final docRef = _plansCollection.doc(travelId);

    // 하위 schedules 서브컬렉션 삭제 후 메인 문서 삭제
    final schedulesSnapshot = await docRef.collection('schedules').get();
    final batch = _firestore.batch();

    for (final doc in schedulesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(docRef);

    await batch.commit();
  }
}
