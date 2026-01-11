import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:math' show cos, pi;

/// SQLite database helper for offline data storage
class DatabaseHelper {
  static const String _databaseName = 'aivonity.db';
  static const int _databaseVersion = 1;

  static Database? _database;
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      await _createTables(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // Vehicle data table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicle_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        data_type TEXT NOT NULL,
        data_json TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        hash TEXT NOT NULL
      )
    ''');

    // Cached API responses
    await db.execute('''
      CREATE TABLE IF NOT EXISTS api_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT NOT NULL UNIQUE,
        response_data TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        etag TEXT,
        content_hash TEXT NOT NULL
      )
    ''');

    // Sync queue for offline changes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        priority INTEGER DEFAULT 1,
        retry_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_attempt_at INTEGER,
        error_message TEXT
      )
    ''');

    // User preferences and settings
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        data_type TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Offline chat messages
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message_id TEXT UNIQUE,
        conversation_id TEXT NOT NULL,
        content TEXT NOT NULL,
        sender_type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        sync_status INTEGER DEFAULT 0,
        metadata_json TEXT
      )
    ''');

    // Service centers cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_centers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        center_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        phone TEXT,
        services_json TEXT,
        rating REAL,
        cached_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vehicle_data_vehicle_id ON vehicle_data(vehicle_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vehicle_data_timestamp ON vehicle_data(timestamp)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_api_cache_endpoint ON api_cache(endpoint)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_priority ON sync_queue(priority DESC, created_at ASC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation ON chat_messages(conversation_id, timestamp)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_service_centers_location ON service_centers(latitude, longitude)',
    );
  }

  // Vehicle data operations
  Future<int> insertVehicleData(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final dataWithTimestamp = {
      ...data,
      'created_at': now,
      'updated_at': now,
      'hash': _generateHash(data),
    };

    return await db.insert('vehicle_data', dataWithTimestamp);
  }

  Future<List<Map<String, dynamic>>> getVehicleData({
    required String vehicleId,
    String? dataType,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    final db = await database;
    String whereClause = 'vehicle_id = ?';
    List<dynamic> whereArgs = [vehicleId];

    if (dataType != null) {
      whereClause += ' AND data_type = ?';
      whereArgs.add(dataType);
    }

    if (startTime != null) {
      whereClause += ' AND timestamp >= ?';
      whereArgs.add(startTime.millisecondsSinceEpoch);
    }

    if (endTime != null) {
      whereClause += ' AND timestamp <= ?';
      whereArgs.add(endTime.millisecondsSinceEpoch);
    }

    return await db.query(
      'vehicle_data',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // API cache operations
  Future<void> cacheApiResponse({
    required String endpoint,
    required Map<String, dynamic> responseData,
    required Duration ttl,
    String? etag,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + ttl.inMilliseconds;
    final responseJson = json.encode(responseData);

    await db.insert('api_cache', {
      'endpoint': endpoint,
      'response_data': responseJson,
      'expires_at': expiresAt,
      'created_at': now,
      'etag': etag,
      'content_hash': _generateHash({'data': responseJson}),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedApiResponse(String endpoint) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final results = await db.query(
      'api_cache',
      where: 'endpoint = ? AND expires_at > ?',
      whereArgs: [endpoint, now],
    );

    if (results.isNotEmpty) {
      final cached = results.first;
      return {
        'data': json.decode(cached['response_data'] as String),
        'etag': cached['etag'],
        'cached_at': cached['created_at'],
      };
    }

    return null;
  }

  Future<void> clearExpiredCache() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.delete('api_cache', where: 'expires_at <= ?', whereArgs: [now]);
  }

  // Sync queue operations
  Future<int> addToSyncQueue({
    required String operationType,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
    int priority = 1,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    return await db.insert('sync_queue', {
      'operation_type': operationType,
      'table_name': tableName,
      'record_id': recordId,
      'data_json': json.encode(data),
      'priority': priority,
      'created_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems({int? limit}) async {
    final db = await database;

    return await db.query(
      'sync_queue',
      orderBy: 'priority DESC, created_at ASC',
      limit: limit,
    );
  }

  Future<void> removeSyncItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSyncItemRetry(int id, String? errorMessage) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'sync_queue',
      {
        'retry_count': 'retry_count + 1',
        'last_attempt_at': now,
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Chat messages operations
  Future<int> insertChatMessage(Map<String, dynamic> message) async {
    final db = await database;
    return await db.insert('chat_messages', message);
  }

  Future<List<Map<String, dynamic>>> getChatMessages({
    required String conversationId,
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    return await db.query(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  // Service centers operations
  Future<void> cacheServiceCenters(List<Map<String, dynamic>> centers) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + const Duration(days: 7).inMilliseconds;

    final batch = db.batch();
    for (final center in centers) {
      batch.insert('service_centers', {
        ...center,
        'cached_at': now,
        'expires_at': expiresAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getCachedServiceCenters({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String whereClause = 'expires_at > ?';
    List<dynamic> whereArgs = [now];

    // Simple bounding box filter for location-based queries
    if (latitude != null && longitude != null && radiusKm != null) {
      final latDelta = radiusKm / 111.0; // Rough conversion
      final lonDelta = radiusKm / (111.0 * cos(latitude * pi / 180));

      whereClause +=
          ' AND latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?';
      whereArgs.addAll([
        latitude - latDelta,
        latitude + latDelta,
        longitude - lonDelta,
        longitude + lonDelta,
      ]);
    }

    return await db.query(
      'service_centers',
      where: whereClause,
      whereArgs: whereArgs,
    );
  }

  // Utility methods
  String _generateHash(Map<String, dynamic> data) {
    final content = json.encode(data);
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<int> getDatabaseSize() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA page_count');
    final pageCount = result.first['page_count'] as int;
    final pageSize = await db.rawQuery('PRAGMA page_size');
    final size = pageCount * (pageSize.first['page_size'] as int);
    return size;
  }

  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<void> clearAllData() async {
    final db = await database;
    final tables = [
      'vehicle_data',
      'api_cache',
      'sync_queue',
      'chat_messages',
      'service_centers',
    ];

    for (final table in tables) {
      await db.delete(table);
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

