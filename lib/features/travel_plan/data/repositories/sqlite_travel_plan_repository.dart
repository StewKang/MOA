import 'package:sqflite/sqflite.dart';
import 'package:moa/core/database/app_database.dart';
import 'package:moa/features/travel_plan/data/models/schedule_item_model.dart';
import 'package:moa/features/travel_plan/data/models/travel_plan_model.dart';
import 'package:moa/features/travel_plan/data/repositories/travel_plan_repository.dart';

/// SQLite 기반 영구 로컬 저장소 Repository 구현체
class SqliteTravelPlanRepository implements TravelPlanRepository {
  final AppDatabase _appDatabase;
  final LocalTravelPlanRepository _fallbackRepository = LocalTravelPlanRepository();

  SqliteTravelPlanRepository(this._appDatabase);

  @override
  Future<List<TravelPlanModel>> getAllTravelPlans() async {
    final db = await _appDatabase.database;
    if (db == null) {
      return _fallbackRepository.getAllTravelPlans();
    }

    final maps = await db.query(
      'travel_plans',
      orderBy: 'start_date DESC',
    );
    return maps.map((m) => TravelPlanModel.fromSqliteMap(m)).toList();
  }

  @override
  Future<List<TravelPlanModel>> getPastTravelPlans() async {
    final db = await _appDatabase.database;
    if (db == null) {
      return _fallbackRepository.getPastTravelPlans();
    }

    final maps = await db.query(
      'travel_plans',
      where: 'is_completed = 1 OR is_favorite = 1',
      orderBy: 'start_date DESC',
    );
    return maps.map((m) => TravelPlanModel.fromSqliteMap(m)).toList();
  }

  @override
  Future<TravelPlanModel?> getTravelPlanById(String travelId) async {
    final db = await _appDatabase.database;
    if (db == null) {
      return _fallbackRepository.getTravelPlanById(travelId);
    }

    final maps = await db.query(
      'travel_plans',
      where: 'travel_id = ?',
      whereArgs: [travelId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TravelPlanModel.fromSqliteMap(maps.first);
  }

  @override
  Future<void> saveTravelPlan(TravelPlanModel plan) async {
    final db = await _appDatabase.database;
    if (db == null) {
      await _fallbackRepository.saveTravelPlan(plan);
      return;
    }

    await db.insert(
      'travel_plans',
      plan.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ScheduleItemModel>> getScheduleItems(String travelId) async {
    final db = await _appDatabase.database;
    if (db == null) {
      return _fallbackRepository.getScheduleItems(travelId);
    }

    final maps = await db.query(
      'schedule_items',
      where: 'travel_id = ?',
      whereArgs: [travelId],
      orderBy: 'date ASC, start_slot_index ASC',
    );
    return maps.map((m) => ScheduleItemModel.fromSqliteMap(m)).toList();
  }

  @override
  Future<void> saveScheduleItems(
      String travelId, List<ScheduleItemModel> items) async {
    final db = await _appDatabase.database;
    if (db == null) {
      await _fallbackRepository.saveScheduleItems(travelId, items);
      return;
    }

    // DB 트랜잭션: 기존 항목 삭제 후 신규 항목 일괄 원자적 저장
    await db.transaction((txn) async {
      await txn.delete(
        'schedule_items',
        where: 'travel_id = ?',
        whereArgs: [travelId],
      );

      for (final item in items) {
        await txn.insert(
          'schedule_items',
          item.toSqliteMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> deleteTravelPlan(String travelId) async {
    final db = await _appDatabase.database;
    if (db == null) {
      await _fallbackRepository.deleteTravelPlan(travelId);
      return;
    }

    // DB 트랜잭션: 하위 일정 및 여행 메타데이터 원자적 삭제
    await db.transaction((txn) async {
      await txn.delete(
        'schedule_items',
        where: 'travel_id = ?',
        whereArgs: [travelId],
      );
      await txn.delete(
        'travel_plans',
        where: 'travel_id = ?',
        whereArgs: [travelId],
      );
    });
  }
}
