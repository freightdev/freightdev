import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:surrealdb/surrealdb.dart';

class DatabaseService {
  static SurrealDB? _db;
  static String? _dbDir;
  static String? _dbFilePath;

  /// Initialize embedded SurrealDB instance
  static Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _dbDir = '${appDir.path}/hwy_tms_db';
      final dbDir = Directory(_dbDir!);
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      _dbFilePath = '$_dbDir/hwy_tms.db';
      _db = SurrealDB('file://$_dbFilePath');

      _db!.connect();
      _db!.use('hwy_tms', 'local');

      print('✅ Embedded SurrealDB initialized at: $_dbFilePath');
    } catch (e) {
      print('❌ Failed to initialize SurrealDB: $e');
      rethrow;
    }
  }

  /// Get database instance
  static SurrealDB get db {
    if (_db == null) {
      throw Exception(
          'DatabaseService not initialized. Call initialize() first.');
    }
    return _db!;
  }

  /// Get database directory for backup/export
  static String? get dbPath => _dbDir;

  static String? get dbFilePath => _dbFilePath;

  /// Close database connection
  static Future<void> close() async {
    _db?.close();
    _db = null;
  }

  /// Export database to file for backup
  static Future<File> exportDatabase() async {
    final dbFilePath = _dbFilePath;
    final dbDir = _dbDir;
    if (dbFilePath == null || dbDir == null) {
      throw Exception('Database not initialized');
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final downloadsDir = await getDownloadsDirectory();
    final exportBase = downloadsDir?.path ?? dbDir;
    final exportDir = Directory(exportBase);
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final exportFile = File('${exportDir.path}/hwy_tms_backup_$timestamp.db');
    await File(dbFilePath).copy(exportFile.path);

    return exportFile;
  }

  /// Import database from backup file
  static Future<void> importDatabase(String backupPath) async {
    if (_dbDir == null || _dbFilePath == null) {
      throw Exception('Database not initialized');
    }

    await close();

    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw Exception('Backup file not found');
    }

    final dbDir = Directory(_dbDir!);
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    final targetFile = File(_dbFilePath!);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await backupFile.copy(_dbFilePath!);

    await initialize();
  }

  /// Clear all data (for reset)
  static Future<void> clearAllData() async {
    if (_dbFilePath == null) return;

    await close();

    final dbFile = File(_dbFilePath!);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    await initialize();
  }
}
