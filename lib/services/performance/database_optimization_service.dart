import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for optimizing database performance and queries
class DatabaseOptimizationService {
  static const String _queryStatsPrefix = 'query_stats_';
  static const String _indexStatsPrefix = 'index_stats_';
  static const Duration _slowQueryThreshold = Duration(milliseconds: 100);

  Database? _database;
  SharedPreferences? _prefs;

  final Map<String, QueryStats> _queryStats = {};
  final Map<String, IndexStats> _indexStats = {};
  final List<SlowQuery> _slowQueries = [];

  /// Initialize the database optimization service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadQueryStats();

    print('🗄️ Database optimization service initialized');
  }

  /// Set the database instance to optimize
  void setDatabase(Database database) {
    _database = database;
  }

  /// Execute an optimized query with performance tracking
  Future<List<Map<String, dynamic>>> executeOptimizedQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    if (_database == null) {
      throw Exception('Database not set');
    }

    final queryId = _generateQueryId(sql);
    final stopwatch = Stopwatch()..start();

    try {
      // Check if query can be optimized
      final optimizedSql = _optimizeQuery(sql);

      // Execute query
      final result = await _database!.rawQuery(optimizedSql, arguments);

      stopwatch.stop();

      // Record query statistics
      await _recordQueryStats(queryId, sql, stopwatch.elapsed, result.length);

      // Check for slow queries
      if (stopwatch.elapsed > _slowQueryThreshold) {
        _recordSlowQuery(sql, stopwatch.elapsed, arguments);
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      await _recordQueryStats(
        queryId,
        sql,
        stopwatch.elapsed,
        0,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Analyze database performance and suggest optimizations
  Future<DatabaseAnalysis> analyzePerformance() async {
    if (_database == null) {
      throw Exception('Database not set');
    }

    final analysis = DatabaseAnalysis();

    // Analyze table sizes
    analysis.tableSizes = await _analyzeTableSizes();

    // Analyze index usage
    analysis.indexAnalysis = await _analyzeIndexUsage();

    // Analyze slow queries
    analysis.slowQueries = List.from(_slowQueries);

    // Generate optimization recommendations
    analysis.recommendations = _generateOptimizationRecommendations(analysis);

    return analysis;
  }

  /// Create optimized indexes based on query patterns
  Future<void> createOptimizedIndexes() async {
    if (_database == null) return;

    final recommendations = await _getIndexRecommendations();

    for (final recommendation in recommendations) {
      try {
        await _database!.execute(recommendation.createIndexSql);
        print('✅ Created index: ${recommendation.indexName}');

        // Record index creation
        _indexStats[recommendation.indexName] = IndexStats(
          indexName: recommendation.indexName,
          tableName: recommendation.tableName,
          columns: recommendation.columns,
          createdAt: DateTime.now(),
          usageCount: 0,
        );
      } catch (e) {
        print('❌ Failed to create index ${recommendation.indexName}: $e');
      }
    }
  }

  /// Optimize database by running maintenance tasks
  Future<void> optimizeDatabase() async {
    if (_database == null) return;

    try {
      // Analyze database
      await _database!.execute('ANALYZE');

      // Vacuum database to reclaim space
      await _database!.execute('VACUUM');

      // Update statistics
      await _database!.execute('PRAGMA optimize');

      print('🔧 Database optimization completed');
    } catch (e) {
      print('❌ Database optimization failed: $e');
    }
  }

  /// Get query performance statistics
  Map<String, QueryStats> getQueryStats() {
    return Map.from(_queryStats);
  }

  /// Get slow query report
  List<SlowQuery> getSlowQueries({int limit = 10}) {
    final sortedQueries = List<SlowQuery>.from(_slowQueries);
    sortedQueries.sort((a, b) => b.executionTime.compareTo(a.executionTime));
    return sortedQueries.take(limit).toList();
  }

  /// Clear performance statistics
  Future<void> clearStats() async {
    _queryStats.clear();
    _slowQueries.clear();

    // Clear from persistent storage
    final keys = _prefs?.getKeys() ?? <String>{};
    final statsKeys = keys.where(
      (key) =>
          key.startsWith(_queryStatsPrefix) ||
          key.startsWith(_indexStatsPrefix),
    );

    for (final key in statsKeys) {
      await _prefs?.remove(key);
    }

    print('🧹 Cleared database performance statistics');
  }

  // Private helper methods

  String _generateQueryId(String sql) {
    // Normalize SQL for consistent ID generation
    final normalized = sql.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return normalized.hashCode.toString();
  }

  String _optimizeQuery(String sql) {
    String optimized = sql;

    // Add LIMIT if missing for potentially large result sets
    if (optimized.toLowerCase().contains('select') &&
        !optimized.toLowerCase().contains('limit') &&
        !optimized.toLowerCase().contains('count(')) {
      // Only add limit for SELECT queries without COUNT
      if (!optimized.toLowerCase().contains('order by')) {
        optimized += ' LIMIT 1000';
      }
    }

    // Add indexes hints if beneficial
    optimized = _addIndexHints(optimized);

    return optimized;
  }

  String _addIndexHints(String sql) {
    // This would analyze the query and add appropriate index hints
    // For now, return the original SQL
    return sql;
  }

  Future<void> _recordQueryStats(
    String queryId,
    String sql,
    Duration executionTime,
    int resultCount, {
    String? error,
  }) async {
    final stats =
        _queryStats[queryId] ??
        QueryStats(
          queryId: queryId,
          sql: sql,
          executionCount: 0,
          totalExecutionTime: Duration.zero,
          averageExecutionTime: Duration.zero,
          minExecutionTime: Duration(days: 1),
          maxExecutionTime: Duration.zero,
          totalResultCount: 0,
          errorCount: 0,
        );

    stats.executionCount++;
    stats.totalExecutionTime += executionTime;
    stats.averageExecutionTime = Duration(
      milliseconds:
          stats.totalExecutionTime.inMilliseconds ~/ stats.executionCount,
    );

    if (executionTime < stats.minExecutionTime) {
      stats.minExecutionTime = executionTime;
    }

    if (executionTime > stats.maxExecutionTime) {
      stats.maxExecutionTime = executionTime;
    }

    stats.totalResultCount += resultCount;

    if (error != null) {
      stats.errorCount++;
    }

    _queryStats[queryId] = stats;

    // Save to persistent storage
    await _saveQueryStats(queryId, stats);
  }

  void _recordSlowQuery(
    String sql,
    Duration executionTime,
    List<Object?>? arguments,
  ) {
    final slowQuery = SlowQuery(
      sql: sql,
      executionTime: executionTime,
      arguments: arguments,
      timestamp: DateTime.now(),
    );

    _slowQueries.add(slowQuery);

    // Keep only the last 100 slow queries
    if (_slowQueries.length > 100) {
      _slowQueries.removeAt(0);
    }

    print(
      '🐌 Slow query detected: ${executionTime.inMilliseconds}ms - ${sql.substring(0, 50)}...',
    );
  }

  Future<Map<String, int>> _analyzeTableSizes() async {
    if (_database == null) return {};

    try {
      final result = await _database!.rawQuery('''
        SELECT name, 
               (SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=m.name) as row_count
        FROM sqlite_master m 
        WHERE type='table' AND name NOT LIKE 'sqlite_%'
      ''');

      final tableSizes = <String, int>{};
      for (final row in result) {
        final tableName = row['name'] as String;
        final rowCount = row['row_count'] as int;
        tableSizes[tableName] = rowCount;
      }

      return tableSizes;
    } catch (e) {
      print('❌ Error analyzing table sizes: $e');
      return {};
    }
  }

  Future<Map<String, IndexAnalysis>> _analyzeIndexUsage() async {
    if (_database == null) return {};

    try {
      final result = await _database!.rawQuery('''
        SELECT name, tbl_name 
        FROM sqlite_master 
        WHERE type='index' AND name NOT LIKE 'sqlite_%'
      ''');

      final indexAnalysis = <String, IndexAnalysis>{};
      for (final row in result) {
        final indexName = row['name'] as String;
        final tableName = row['tbl_name'] as String;

        indexAnalysis[indexName] = IndexAnalysis(
          indexName: indexName,
          tableName: tableName,
          isUsed: _isIndexUsed(indexName),
          usageCount: _getIndexUsageCount(indexName),
        );
      }

      return indexAnalysis;
    } catch (e) {
      print('❌ Error analyzing index usage: $e');
      return {};
    }
  }

  bool _isIndexUsed(String indexName) {
    // Check if index is referenced in query plans
    final usageCount = _indexStats[indexName]?.usageCount ?? 0;
    return usageCount > 0;
  }

  int _getIndexUsageCount(String indexName) {
    return _indexStats[indexName]?.usageCount ?? 0;
  }

  List<String> _generateOptimizationRecommendations(DatabaseAnalysis analysis) {
    final recommendations = <String>[];

    // Recommend indexes for slow queries
    for (final slowQuery in analysis.slowQueries) {
      if (slowQuery.sql.toLowerCase().contains('where')) {
        recommendations.add(
          'Consider adding an index for WHERE clause in: ${slowQuery.sql.substring(0, 50)}...',
        );
      }
    }

    // Recommend removing unused indexes
    for (final entry in analysis.indexAnalysis.entries) {
      if (!entry.value.isUsed) {
        recommendations.add('Consider removing unused index: ${entry.key}');
      }
    }

    // Recommend table optimization for large tables
    for (final entry in analysis.tableSizes.entries) {
      if (entry.value > 10000) {
        recommendations.add(
          'Consider partitioning or archiving large table: ${entry.key} (${entry.value} rows)',
        );
      }
    }

    return recommendations;
  }

  Future<List<IndexRecommendation>> _getIndexRecommendations() async {
    final recommendations = <IndexRecommendation>[];

    // Analyze slow queries for index opportunities
    for (final slowQuery in _slowQueries) {
      final indexRec = _analyzeQueryForIndexes(slowQuery.sql);
      if (indexRec != null) {
        recommendations.add(indexRec);
      }
    }

    return recommendations;
  }

  IndexRecommendation? _analyzeQueryForIndexes(String sql) {
    // Simple analysis - look for WHERE clauses
    final lowerSql = sql.toLowerCase();

    if (lowerSql.contains('where')) {
      // Extract table name and potential index columns
      // This is a simplified implementation
      return IndexRecommendation(
        indexName: 'idx_auto_${DateTime.now().millisecondsSinceEpoch}',
        tableName: 'unknown_table',
        columns: ['unknown_column'],
        createIndexSql:
            'CREATE INDEX idx_auto ON unknown_table (unknown_column)',
      );
    }

    return null;
  }

  Future<void> _saveQueryStats(String queryId, QueryStats stats) async {
    try {
      final statsJson = jsonEncode(stats.toJson());
      await _prefs?.setString('$_queryStatsPrefix$queryId', statsJson);
    } catch (e) {
      print('❌ Error saving query stats: $e');
    }
  }

  Future<void> _loadQueryStats() async {
    try {
      final keys = _prefs?.getKeys() ?? <String>{};
      final statsKeys = keys.where((key) => key.startsWith(_queryStatsPrefix));

      for (final key in statsKeys) {
        final statsJson = _prefs?.getString(key);
        if (statsJson != null) {
          final stats = QueryStats.fromJson(jsonDecode(statsJson));
          _queryStats[stats.queryId] = stats;
        }
      }
    } catch (e) {
      print('❌ Error loading query stats: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _queryStats.clear();
    _slowQueries.clear();
    _indexStats.clear();
  }
}

/// Query performance statistics
class QueryStats {
  final String queryId;
  final String sql;
  int executionCount;
  Duration totalExecutionTime;
  Duration averageExecutionTime;
  Duration minExecutionTime;
  Duration maxExecutionTime;
  int totalResultCount;
  int errorCount;

  QueryStats({
    required this.queryId,
    required this.sql,
    required this.executionCount,
    required this.totalExecutionTime,
    required this.averageExecutionTime,
    required this.minExecutionTime,
    required this.maxExecutionTime,
    required this.totalResultCount,
    required this.errorCount,
  });

  Map<String, dynamic> toJson() => {
    'queryId': queryId,
    'sql': sql,
    'executionCount': executionCount,
    'totalExecutionTimeMs': totalExecutionTime.inMilliseconds,
    'averageExecutionTimeMs': averageExecutionTime.inMilliseconds,
    'minExecutionTimeMs': minExecutionTime.inMilliseconds,
    'maxExecutionTimeMs': maxExecutionTime.inMilliseconds,
    'totalResultCount': totalResultCount,
    'errorCount': errorCount,
  };

  factory QueryStats.fromJson(Map<String, dynamic> json) => QueryStats(
    queryId: json['queryId'],
    sql: json['sql'],
    executionCount: json['executionCount'],
    totalExecutionTime: Duration(milliseconds: json['totalExecutionTimeMs']),
    averageExecutionTime: Duration(
      milliseconds: json['averageExecutionTimeMs'],
    ),
    minExecutionTime: Duration(milliseconds: json['minExecutionTimeMs']),
    maxExecutionTime: Duration(milliseconds: json['maxExecutionTimeMs']),
    totalResultCount: json['totalResultCount'],
    errorCount: json['errorCount'],
  );
}

/// Slow query information
class SlowQuery {
  final String sql;
  final Duration executionTime;
  final List<Object?>? arguments;
  final DateTime timestamp;

  SlowQuery({
    required this.sql,
    required this.executionTime,
    this.arguments,
    required this.timestamp,
  });
}

/// Index statistics
class IndexStats {
  final String indexName;
  final String tableName;
  final List<String> columns;
  final DateTime createdAt;
  int usageCount;

  IndexStats({
    required this.indexName,
    required this.tableName,
    required this.columns,
    required this.createdAt,
    required this.usageCount,
  });
}

/// Database analysis results
class DatabaseAnalysis {
  Map<String, int> tableSizes = {};
  Map<String, IndexAnalysis> indexAnalysis = {};
  List<SlowQuery> slowQueries = [];
  List<String> recommendations = [];
}

/// Index analysis information
class IndexAnalysis {
  final String indexName;
  final String tableName;
  final bool isUsed;
  final int usageCount;

  IndexAnalysis({
    required this.indexName,
    required this.tableName,
    required this.isUsed,
    required this.usageCount,
  });
}

/// Index recommendation
class IndexRecommendation {
  final String indexName;
  final String tableName;
  final List<String> columns;
  final String createIndexSql;

  IndexRecommendation({
    required this.indexName,
    required this.tableName,
    required this.columns,
    required this.createIndexSql,
  });
}

