import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// MOA 애플리케이션 SQLite 데이터베이스 인스턴스 및 생명주기 관리자
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;
  static Future<Database?>? _initFuture;

  AppDatabase._internal();

  /// SQLite 데이터베이스 인스턴스 반환 (동시성 접근 락 적용)
  Future<Database?> get database async {
    if (kIsWeb) {
      // Flutter Web 등 sqflite 네이티브 미지원 플랫폼인 경우 null 반환 (인메모리 폴백 구동)
      return null;
    }
    if (_database != null && _database!.isOpen) {
      return _database;
    }
    
    // 여러 비동기 호출이 동시에 들어와도 _initDatabase()가 단 1회만 실행되도록 락 체이닝
    _initFuture ??= _initDatabase();
    try {
      _database = await _initFuture;
    } catch (e) {
      _initFuture = null; // 실패 시 재시도를 위해 초기화 락 리셋
      rethrow;
    }
    return _database;
  }

  /// SQLite DB 미지원 플랫폼 여부
  bool get isSupported => !kIsWeb;

  /// DB 개설 및 테이블 생성
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'moa_travel.db');

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        // SQLite 외래키(Foreign Key) 제약조건 활성화
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedInitialData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _upgradeTablesToV2(db);
        }
      },
    );
  }

  /// DDL 구문: 테이블 생성 (v2 스키마 반영)
  Future<void> _createTables(Database db) async {
    // 1. 사용자 정보 테이블
    await db.execute('''
      CREATE TABLE users (
        user_id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        nickname TEXT NOT NULL,
        profile_image_url TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    // 2. 여행 계획 메타데이터 테이블
    await db.execute('''
      CREATE TABLE travel_plans (
        travel_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        destination TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        owner_id TEXT,
        invite_code TEXT,
        updated_at TEXT
      );
    ''');

    // 3. 여행 동행자 멤버 관계 테이블
    await db.execute('''
      CREATE TABLE travel_members (
        plan_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'MEMBER',
        joined_at TEXT NOT NULL,
        PRIMARY KEY (plan_id, user_id),
        FOREIGN KEY (plan_id) REFERENCES travel_plans (travel_id) ON DELETE CASCADE
      );
    ''');

    // 4. 개별 일정 타임 블록 테이블 (외래키 CASCADE 삭제 지원)
    await db.execute('''
      CREATE TABLE schedule_items (
        id TEXT PRIMARY KEY,
        travel_id TEXT NOT NULL,
        date TEXT NOT NULL,
        start_slot_index INTEGER NOT NULL,
        duration_slots INTEGER NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        location TEXT,
        latitude REAL,
        longitude REAL,
        memo TEXT,
        origin TEXT,
        destination TEXT,
        transport_mode TEXT,
        FOREIGN KEY (travel_id) REFERENCES travel_plans (travel_id) ON DELETE CASCADE
      );
    ''');

    // 5. 정산 & N빵 계산 내역 테이블
    await db.execute('''
      CREATE TABLE expenses (
        expense_id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        payer_id TEXT NOT NULL,
        amount REAL NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        split_members TEXT,
        is_settled INTEGER NOT NULL DEFAULT 0,
        expense_date TEXT NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES travel_plans (travel_id) ON DELETE CASCADE
      );
    ''');

    // 6. 준비물 체크리스트 테이블
    await db.execute('''
      CREATE TABLE checklists (
        item_id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '일반',
        is_checked INTEGER NOT NULL DEFAULT 0,
        assigned_user_id TEXT,
        FOREIGN KEY (plan_id) REFERENCES travel_plans (travel_id) ON DELETE CASCADE
      );
    ''');

    // 7. 오프라인 지도 & 메모 테이블
    await db.execute('''
      CREATE TABLE memos (
        memo_id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        latitude REAL,
        longitude REAL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES travel_plans (travel_id) ON DELETE CASCADE
      );
    ''');
  }

  /// v1 -> v2 마이그레이션 스크립트
  Future<void> _upgradeTablesToV2(Database db) async {
    // travel_plans 신규 컬럼 추가
    await db.execute('ALTER TABLE travel_plans ADD COLUMN owner_id TEXT;');
    await db.execute('ALTER TABLE travel_plans ADD COLUMN invite_code TEXT;');
    await db.execute('ALTER TABLE travel_plans ADD COLUMN updated_at TEXT;');

    // schedule_items 위경도 컬럼 추가
    await db.execute('ALTER TABLE schedule_items ADD COLUMN latitude REAL;');
    await db.execute('ALTER TABLE schedule_items ADD COLUMN longitude REAL;');

    // 신규 테이블 생성
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        user_id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        nickname TEXT NOT NULL,
        profile_image_url TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS travel_members (
        plan_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'MEMBER',
        joined_at TEXT NOT NULL,
        PRIMARY KEY (plan_id, user_id),
        FOREIGN KEY (plan_id) REFERENCES travel_plans (travel_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        expense_id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        payer_id TEXT NOT NULL,
        amount REAL NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        split_members TEXT,
        is_settled INTEGER NOT NULL DEFAULT 0,
        expense_date TEXT NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES travel_plans (travel_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS checklists (
        item_id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '일반',
        is_checked INTEGER NOT NULL DEFAULT 0,
        assigned_user_id TEXT,
        FOREIGN KEY (plan_id) REFERENCES travel_plans (travel_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS memos (
        memo_id TEXT PRIMARY KEY,
        plan_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        latitude REAL,
        longitude REAL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES travel_plans (travel_id) ON DELETE CASCADE
      );
    ''');
  }

  /// 최초 실행 시 기본 시드(Seed) 과거 일정을 DB에 자동 삽입
  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();

    // 1. 부산 식도락 과거 여행 시드
    const plan1Id = 'past_plan_busan_01';
    final plan1Start = now.subtract(const Duration(days: 30));
    final plan1End = plan1Start.add(const Duration(days: 2));

    await db.insert('travel_plans', {
      'travel_id': plan1Id,
      'title': '부산 맛집 탐방 식도락 여행',
      'start_date': plan1Start.toIso8601String(),
      'end_date': plan1End.toIso8601String(),
      'destination': '부산광역시',
      'is_favorite': 1,
      'is_completed': 1,
    });

    await db.insert('schedule_items', {
      'id': 'item_b1',
      'travel_id': plan1Id,
      'date': plan1Start.toIso8601String(),
      'start_slot_index': 18, // 09:00
      'duration_slots': 2,
      'category': 'transport',
      'title': 'KTX 부산역 이동',
      'location': '서울역 ➔ 부산역 (KTX/기차)',
      'memo': '짐 보관소에 가방 맡기기',
      'origin': '서울역',
      'destination': '부산역',
      'transport_mode': 'KTX/기차',
    });

    await db.insert('schedule_items', {
      'id': 'item_b2',
      'travel_id': plan1Id,
      'date': plan1Start.toIso8601String(),
      'start_slot_index': 24, // 12:00
      'duration_slots': 3,
      'category': 'meal',
      'title': '초량밀면 점심 식사',
      'location': '부산 동구 중앙대로 225',
      'memo': '물밀면 + 만두 조합 강추',
      'origin': '',
      'destination': '',
      'transport_mode': '',
    });

    await db.insert('schedule_items', {
      'id': 'item_b3',
      'travel_id': plan1Id,
      'date': plan1Start.toIso8601String(),
      'start_slot_index': 28, // 14:00
      'duration_slots': 4,
      'category': 'activity',
      'title': '해운대 해변 산책 및 미포철길',
      'location': '해운대구',
      'memo': '스카이캡슐 탑승 예약 확인',
      'origin': '',
      'destination': '',
      'transport_mode': '',
    });

    // 2. 제주 힐링 과거 여행 시드
    const plan2Id = 'past_plan_jeju_02';
    final plan2Start = now.subtract(const Duration(days: 60));
    final plan2End = plan2Start.add(const Duration(days: 3));

    await db.insert('travel_plans', {
      'travel_id': plan2Id,
      'title': '제주 자연 속 힐링 3박 4일',
      'start_date': plan2Start.toIso8601String(),
      'end_date': plan2End.toIso8601String(),
      'destination': '제주특별자치도',
      'is_favorite': 1,
      'is_completed': 1,
    });

    await db.insert('schedule_items', {
      'id': 'item_j1',
      'travel_id': plan2Id,
      'date': plan2Start.toIso8601String(),
      'start_slot_index': 20, // 10:00
      'duration_slots': 3,
      'category': 'transport',
      'title': '제주 공항 도착 & 렌터카 인수',
      'location': '제주공항 (비행기)',
      'memo': '차량 외관 사진 촬영 필수',
      'origin': '김포공항',
      'destination': '제주공항',
      'transport_mode': '비행기',
    });
  }

  /// 데이터베이스 닫기
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      _initFuture = null;
    }
  }
}
