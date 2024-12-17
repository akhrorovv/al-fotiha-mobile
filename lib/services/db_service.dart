import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SqlService {
  static const String _dbName = 'audio_database.db';
  static const String _tableName = 'audios';
  static const String _columnId = 'id';
  static const String _columnPath = 'path';

  late Database _database;

  static final SqlService _instance = SqlService._internal();

  factory SqlService() => _instance;

  SqlService._internal();

  /// Initialize the database
  Future<void> init() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, _dbName);

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create table when database is created
        await db.execute('''
          CREATE TABLE $_tableName (
            $_columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_columnPath TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> saveAudio(String path) async {
    await _database.insert(
      _tableName,
      {_columnPath: path},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> loadAudios() async {
    final List<Map<String, dynamic>> results =
        await _database.query(_tableName);
    return results.map((row) => row[_columnPath] as String).toList();
  }

  Future<void> deleteAudio(int id) async {
    await _database.delete(
      _tableName,
      where: '$_columnId = ?',
      whereArgs: [id],
    );
  }
}
