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
    return await openDatabase(path,
        version: 1, onCreate: _onCreate, readOnly: false);
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
    await db.execute('''
  CREATE TABLE tag_maquina (
    id INTEGER PRIMARY KEY,
    tag_nome TEXT,
    maquina_nome TEXT,
    linha_id INTEGER,
    FOREIGN KEY (linha_id) REFERENCES linha (id)
  )
  ''');

    await db.execute('''
  CREATE TABLE conjunto_equip (
    id INTEGER PRIMARY KEY,
    conj_nome TEXT,
    equi_nome TEXT,
    tag_maquina_id INTEGER,
    FOREIGN KEY (tag_maquina_id) REFERENCES tag_maquina (id)
  )
  ''');
    await db.execute('''
  CREATE TABLE pontos (
    id INTEGER PRIMARY KEY,
    component_name TEXT,
    component_codigo TEXT,
    qty_pontos TEXT,
    atv_breve_name TEXT,
    atv_breve_codigo TEXT,
    lub_name TEXT,
    lub_codigo TEXT,
    qty_material TEXT,
    cond_op_name TEXT,
    cond_op_codigo TEXT,
    period_name TEXT,
    period_codigo TEXT,
    qty_pessoas TEXT,
    conjunto_equip_id INTEGER,
    FOREIGN KEY (conjunto_equip_id) REFERENCES conjunto_equip (id)
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

  Future<int> insertTag(Map<String, dynamic> tagData) async {
    Database db = await database;
    return await db.insert('tag_maquina', tagData);
  }

  Future<int> insertConjuntoAndEquip(Map<String, dynamic> conjuntoData) async {
    Database db = await database;
    return await db.insert('conjunto_equip', conjuntoData);
  }

  Future<int> insertPontos(Map<String, dynamic> pontosData) async {
    Database db = await database;
    return await db.insert('pontos', pontosData);
  }

  Future<List<Map<String, dynamic>>> getPlanosLub() async {
    Database db = await database;
    return await db.query('planolub');
  }

  Future<List<Map<String, dynamic>>> getAreas(int idPlano) async {
    final db = await database;
    final List<Map<String, dynamic>> areas = await db.query(
      'area',
      where: 'plano_id = ?',
      whereArgs: [idPlano],
    );
    return areas;
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

  Future<Map<String, dynamic>?> getPontoById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'pontos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
  }

  // Em DatabaseHelper
  Future<List<Map<String, dynamic>>> getTagsMaquinasEConjuntos() async {
    Database db = await database;
    List<Map<String, dynamic>> tagsMaquinas = await db.query('tag_maquina');
    // Aqui você também pode buscar os conjuntos de equipamentos associados a cada tag, se necessário
    return tagsMaquinas;
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

  Future<List<Map<String, dynamic>>> getTagsAndMaquinasByLinhaId(
      int linhaId) async {
    final db = await database;
    final List<Map<String, dynamic>> tags = await db.query(
      'tag_maquina',
      where: 'linha_id = ?',
      whereArgs: [linhaId],
    );
    return tags;
  }

  Future<List<Map<String, dynamic>>> getConjuntoEquipByTagMaquinaId(
      int tagMaquinaId) async {
    final db = await database;
    final List<Map<String, dynamic>> conjuntoEquip = await db.query(
      'conjunto_equip',
      where: 'tag_maquina_id = ?',
      whereArgs: [tagMaquinaId],
    );
    return conjuntoEquip;
  }

  Future<List<Map<String, dynamic>>> getPontosByConjuntoEquipId(
      int conjuntoEquipId) async {
    final db = await database;
    final List<Map<String, dynamic>> pontos = await db.query(
      'pontos',
      where: 'conjunto_equip_id = ?',
      whereArgs: [conjuntoEquipId],
    );
    return pontos;
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

  Future<Map<String, dynamic>?> getSubAreaById(int subareaId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'subarea',
      where: 'id = ?',
      whereArgs: [subareaId],
    );
    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLinhaById(int subareaId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'linha',
      where: 'id = ?',
      whereArgs: [subareaId],
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

  Future<void> editarSubArea(Map<String, dynamic> areaData) async {
    final db = await database;
    await db.update(
      'subarea',
      areaData,
      where: 'id = ?',
      whereArgs: [areaData['id']],
    );
  }

  Future<void> editarLinha(Map<String, dynamic> areaData) async {
    final db = await database;
    await db.update(
      'linha',
      areaData,
      where: 'id = ?',
      whereArgs: [areaData['id']],
    );
  }
}
