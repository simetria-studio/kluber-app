import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'db/planos.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE planolub (
      id INTEGER PRIMARY KEY,
      cliente TEXT,
      data_cadastro TEXT,
      data_revisao TEXT,
      responsavel_lubrificacao TEXT,
      responsavel_kluber TEXT
    )
  ''');
    // Criação da tabela 'area' com uma coluna 'plano_id' para relacionar a área ao plano
    await db.execute('''
  CREATE TABLE area (
    id INTEGER PRIMARY KEY,
    nome TEXT,
    plano_id INTEGER,
    FOREIGN KEY (plano_id) REFERENCES planolub (id)
  )
  ''');
    await db.execute('''
  CREATE TABLE subarea (
    id INTEGER PRIMARY KEY,
    nome TEXT,
    area_id INTEGER,
    FOREIGN KEY (area_id) REFERENCES area (id)
  )
  ''');
    await db.execute('''
  CREATE TABLE linha (
    id INTEGER PRIMARY KEY,
    nome TEXT,
    subarea_id INTEGER,
    FOREIGN KEY (subarea_id) REFERENCES subarea (id)
  )
  ''');
  }

  Future<int> insertPlanoLub(Map<String, dynamic> planoLubData) async {
    Database db = await database;
    int id = await db.insert('planolub', planoLubData);
    return id;
  }

  Future<int> insertArea(Map<String, dynamic> areaData) async {
    Database db = await database;
    return await db.insert('area', areaData);
  }

  Future<int> insertSubArea(Map<String, dynamic> subAreaData) async {
    Database db = await database;
    return await db.insert('subarea', subAreaData);
  }

  Future<int> insertLinha(Map<String, dynamic> linhaData) async {
    Database db = await database;
    return await db.insert('linha', linhaData);
  }

  Future<List<Map<String, dynamic>>> getPlanosLub() async {
    Database db = await database;
    return await db.query('planolub');
  }

  Future<Map<String, dynamic>?> getPlanoLubById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'planolub',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAreasByPlanoId(int planoId) async {
    Database db = await database;
    final List<Map<String, dynamic>> areas = await db.query(
      'area',
      where: 'plano_id = ?',
      whereArgs: [planoId],
    );
    return areas;
  }

  Future<List<Map<String, dynamic>>> getSubareasByAreaId(int areaId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> subareasResult = await db.query(
      'subarea',
      where: 'area_id = ?',
      whereArgs: [areaId],
    );
    return subareasResult;
  }

  Future<List<Map<String, dynamic>>> getLinhasBySubareaId(int subareaId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> linhasResult = await db.query(
      'linha',
      where: 'subarea_id = ?',
      whereArgs: [subareaId],
    );
    return linhasResult;
  }

  Future<void> excluirArea(int areaId) async {
    final db = await database;

    // Buscar e excluir todas as subáreas relacionadas à área
    await db.delete(
      'subarea',
      where: 'area_id = ?',
      whereArgs: [areaId],
    );

    // Em seguida, excluir a área
    await db.delete(
      'area',
      where: 'id = ?',
      whereArgs: [areaId],
    );
  }

  Future<Map<String, dynamic>?> getAreaById(int areaId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'area',
      where: 'id = ?',
      whereArgs: [areaId],
    );
    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
  }

  Future<void> editarArea(Map<String, dynamic> areaData) async {
    final db = await database;
    await db.update(
      'area',
      areaData,
      where: 'id = ?',
      whereArgs: [areaData['id']],
    );
  }
}
