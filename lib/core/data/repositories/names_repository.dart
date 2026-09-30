import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/name_of_allah_entity.dart';

class NamesRepository {
  final AppDatabase _appDatabase;

  NamesRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db => _appDatabase.database;

  /// Retrieves all 99 Names of Allah in order.
  Future<List<NameOfAllahEntity>> getNames() async {
    final db = await _db;
    final results = await db.query(
      'names_of_allah',
      orderBy: 'id ASC',
    );
    return results.map((m) => NameOfAllahEntity.fromMap(m)).toList();
  }

  /// Retrieves a specific Name of Allah by its ID (1..99).
  Future<NameOfAllahEntity?> getNameById(int id) async {
    final db = await _db;
    final results = await db.query(
      'names_of_allah',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return NameOfAllahEntity.fromMap(results.first);
  }
}
