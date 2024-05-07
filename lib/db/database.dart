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
      responsavel_kluber TEXT,
      codigo_mobile TEXT
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
    plano_id INTEGER,
    area_id INTEGER,
    FOREIGN KEY (area_id) REFERENCES area (id)
  )
  ''');
    await db.execute('''
  CREATE TABLE linha (
    id INTEGER PRIMARY KEY,
    nome TEXT,
    plano_id INTEGER,
    subarea_id INTEGER,
    FOREIGN KEY (subarea_id) REFERENCES subarea (id)
  )
  ''');
    await db.execute('''
  CREATE TABLE tag_maquina (
    id INTEGER PRIMARY KEY,
    tag_nome TEXT,
    maquina_nome TEXT,
    plano_id INTEGER,
    linha_id INTEGER,
    FOREIGN KEY (linha_id) REFERENCES linha (id)
  )
  ''');

    await db.execute('''
  CREATE TABLE conjunto_equip (
    id INTEGER PRIMARY KEY,
    conj_nome TEXT,
    equi_nome TEXT,
    plano_id INTEGER,
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
    tempo_atv TEXT NULL,
    qty_pessoas TEXT,
    plano_id INTEGER,
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

    // Primeiro, encontre todas as subáreas relacionadas à área
    List<Map<String, dynamic>> subareas = await db.query(
      'subarea',
      where: 'area_id = ?',
      whereArgs: [areaId],
    );

    // Para cada subárea, encontre e exclua todas as linhas relacionadas
    for (var subarea in subareas) {
      int subareaId = subarea['id'];

      List<Map<String, dynamic>> linhas = await db.query(
        'linha',
        where: 'subarea_id = ?',
        whereArgs: [subareaId],
      );

      // Para cada linha, encontre e exclua todas as tags de máquinas relacionadas
      for (var linha in linhas) {
        int linhaId = linha['id'];

        List<Map<String, dynamic>> tagsMaquinas = await db.query(
          'tag_maquina',
          where: 'linha_id = ?',
          whereArgs: [linhaId],
        );

        // Para cada tag de máquina, encontre e exclua todos os conjuntos de equipamentos relacionados
        for (var tagMaquina in tagsMaquinas) {
          int tagMaquinaId = tagMaquina['id'];

          // Excluir os pontos associados a cada conjunto de equipamento
          await db.delete(
            'pontos',
            where:
                'conjunto_equip_id IN (SELECT id FROM conjunto_equip WHERE tag_maquina_id = ?)',
            whereArgs: [tagMaquinaId],
          );

          // Excluir os conjuntos de equipamentos
          await db.delete(
            'conjunto_equip',
            where: 'tag_maquina_id = ?',
            whereArgs: [tagMaquinaId],
          );

          // Excluir a tag da máquina
          await db.delete(
            'tag_maquina',
            where: 'id = ?',
            whereArgs: [tagMaquinaId],
          );
        }

        // Excluir as linhas
        await db.delete(
          'linha',
          where: 'id = ?',
          whereArgs: [linhaId],
        );
      }

      // Excluir as subáreas
      await db.delete(
        'subarea',
        where: 'id = ?',
        whereArgs: [subareaId],
      );
    }

    // Finalmente, excluir a área
    await db.delete(
      'area',
      where: 'id = ?',
      whereArgs: [areaId],
    );
  }

  Future<void> excluirSubArea(int areaId) async {
    final db = await database;

    // Primeiro, encontre todas as subáreas relacionadas à área
    List<Map<String, dynamic>> subareas = await db.query(
      'subarea',
      where: 'area_id = ?',
      whereArgs: [areaId],
    );

    // Para cada subárea, encontre e exclua todas as linhas relacionadas
    for (var subarea in subareas) {
      int subareaId = subarea['id'];

      List<Map<String, dynamic>> linhas = await db.query(
        'linha',
        where: 'subarea_id = ?',
        whereArgs: [subareaId],
      );

      // Para cada linha, encontre e exclua todas as tags de máquinas relacionadas
      for (var linha in linhas) {
        int linhaId = linha['id'];

        List<Map<String, dynamic>> tagsMaquinas = await db.query(
          'tag_maquina',
          where: 'linha_id = ?',
          whereArgs: [linhaId],
        );

        // Para cada tag de máquina, encontre e exclua todos os conjuntos de equipamentos relacionados
        for (var tagMaquina in tagsMaquinas) {
          int tagMaquinaId = tagMaquina['id'];

          // Excluir os pontos associados a cada conjunto de equipamento
          await db.delete(
            'pontos',
            where:
                'conjunto_equip_id IN (SELECT id FROM conjunto_equip WHERE tag_maquina_id = ?)',
            whereArgs: [tagMaquinaId],
          );

          // Excluir os conjuntos de equipamentos
          await db.delete(
            'conjunto_equip',
            where: 'tag_maquina_id = ?',
            whereArgs: [tagMaquinaId],
          );

          // Excluir a tag da máquina
          await db.delete(
            'tag_maquina',
            where: 'id = ?',
            whereArgs: [tagMaquinaId],
          );
        }

        // Excluir as linhas
        await db.delete(
          'linha',
          where: 'id = ?',
          whereArgs: [linhaId],
        );
      }

      // Excluir as subáreas
      await db.delete(
        'subarea',
        where: 'id = ?',
        whereArgs: [subareaId],
      );
    }
  }

  Future<void> excluirLinhas(int areaId) async {
    final db = await database;

    // Primeiro, encontre todas as subáreas relacionadas à área
    List<Map<String, dynamic>> subareas = await db.query(
      'subarea',
      where: 'area_id = ?',
      whereArgs: [areaId],
    );

    // Para cada subárea, encontre e exclua todas as linhas relacionadas
    for (var subarea in subareas) {
      int subareaId = subarea['id'];

      List<Map<String, dynamic>> linhas = await db.query(
        'linha',
        where: 'subarea_id = ?',
        whereArgs: [subareaId],
      );

      // Para cada linha, encontre e exclua todas as tags de máquinas relacionadas
      for (var linha in linhas) {
        int linhaId = linha['id'];

        List<Map<String, dynamic>> tagsMaquinas = await db.query(
          'tag_maquina',
          where: 'linha_id = ?',
          whereArgs: [linhaId],
        );

        // Para cada tag de máquina, encontre e exclua todos os conjuntos de equipamentos relacionados
        for (var tagMaquina in tagsMaquinas) {
          int tagMaquinaId = tagMaquina['id'];

          // Excluir os pontos associados a cada conjunto de equipamento
          await db.delete(
            'pontos',
            where:
                'conjunto_equip_id IN (SELECT id FROM conjunto_equip WHERE tag_maquina_id = ?)',
            whereArgs: [tagMaquinaId],
          );

          // Excluir os conjuntos de equipamentos
          await db.delete(
            'conjunto_equip',
            where: 'tag_maquina_id = ?',
            whereArgs: [tagMaquinaId],
          );

          // Excluir a tag da máquina
          await db.delete(
            'tag_maquina',
            where: 'id = ?',
            whereArgs: [tagMaquinaId],
          );
        }

        // Excluir as linhas
        await db.delete(
          'linha',
          where: 'id = ?',
          whereArgs: [linhaId],
        );
      }
    }
  }

  Future<void> excluirTagEquip(int areaId) async {
    final db = await database;

    // Para cada tag de máquina, encontre e exclua todos os conjuntos de equipamentos relacionados

    List<Map<String, dynamic>> tagsMaquinas = await db.query(
      'tag_maquina',
      where: 'id = ?',
      whereArgs: [areaId],
    );

    for (var tagMaquina in tagsMaquinas) {
      int tagMaquinaId = tagMaquina['id'];

      await db.delete(
        'pontos',
        where:
            'conjunto_equip_id IN (SELECT id FROM conjunto_equip WHERE tag_maquina_id = ?)',
        whereArgs: [tagMaquinaId],
      );

      // Excluir os conjuntos de equipamentos
      await db.delete(
        'conjunto_equip',
        where: 'tag_maquina_id = ?',
        whereArgs: [tagMaquinaId],
      );

      // Excluir a tag da máquina
      await db.delete(
        'tag_maquina',
        where: 'id = ?',
        whereArgs: [tagMaquinaId],
      );
    }
  }

  Future<void> excluirConjEquip(int areaId) async {
    // Abra o banco de dados
    final Database db = await database;

    // Excluir os pontos relacionados à área
    await db.delete(
      'pontos', // Substitua 'pontos' pelo nome da tabela dos pontos
      where:
          'conjunto_equip_id = ?', // Condição para encontrar os pontos da área específica
      whereArgs: [areaId], // Argumento a ser substituído na condição WHERE
    );

    // Excluir a área
    await db.delete(
      'conjunto_equip', // Substitua 'tag_maquina' pelo nome da tabela de áreas
      where: 'id = ?', // Condição para encontrar a área específica
      whereArgs: [areaId], // Argumento a ser substituído na condição WHERE
    );
  }

  Future<int> updatePlanoLub(int id, Map<String, dynamic> planoData) async {
    final db = await database;
    return await db.update(
      'planolub',
      planoData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getPlanoById(int areaId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'planolub',
      where: 'id = ?',
      whereArgs: [areaId],
    );
    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
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

  Future<Map<String, dynamic>?> geTagMaquinaById(int tagMaquina) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'tag_maquina',
      where: 'id = ?',
      whereArgs: [tagMaquina],
    );
    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getConjEquiById(int tagMaquina) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'conjunto_equip',
      where: 'id = ?',
      whereArgs: [tagMaquina],
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

  Future<void> editarTagMaquina(Map<String, dynamic> areaData) async {
    final db = await database;
    await db.update(
      'tag_maquina',
      areaData,
      where: 'id = ?',
      whereArgs: [areaData['id']],
    );
  }

  Future<void> editarConjEquip(Map<String, dynamic> areaData) async {
    final db = await database;
    await db.update(
      'conjunto_equip',
      areaData,
      where: 'id = ?',
      whereArgs: [areaData['id']],
    );
  }

  Future<void> updatePonto(Map<String, dynamic> areaData) async {
    final db = await database;
    await db.update(
      'pontos',
      areaData,
      where: 'id = ?',
      whereArgs: [areaData['id']],
    );
  }

  Future<void> excluirPonto(int pontoId) async {
    final db = await database;
    await db.delete(
      'pontos',
      where: 'id = ?',
      whereArgs: [pontoId],
    );
  }

// Define outras classes de modelo para Subarea, Linha, TagMaquina, ConjuntoEquip, e Pontos aqui
  Future<List<Planolub>> getPlanolubCompleto() async {
    final db = await _initDatabase();
    final List<Map<String, dynamic>> planolubData = await db.query('planolub');
    List<Planolub> planolubs = [];

    for (var data in planolubData) {
      int planolubId = data['id'];
      List<Map<String, dynamic>> areaData = await db
          .query('area', where: 'plano_id = ?', whereArgs: [planolubId]);
      List<Area> areas = [];

      for (var area in areaData) {
        int areaId = area['id'];
        List<Map<String, dynamic>> subareaData = await db
            .query('subarea', where: 'area_id = ?', whereArgs: [areaId]);
        List<Subarea> subareas = [];

        for (var subarea in subareaData) {
          int subareaId = subarea['id'];
          List<Map<String, dynamic>> linhaData = await db
              .query('linha', where: 'subarea_id = ?', whereArgs: [subareaId]);
          List<Linha> linhas = [];

          for (var linha in linhaData) {
            int linhaId = linha['id'];
            List<Map<String, dynamic>> tagMaquinaData = await db.query(
                'tag_maquina',
                where: 'linha_id = ?',
                whereArgs: [linhaId]);
            List<TagMaquina> tagsMaquinas = [];

            for (var tagMaquina in tagMaquinaData) {
              int tagMaquinaId = tagMaquina['id'];
              List<Map<String, dynamic>> conjuntoEquipData = await db.query(
                  'conjunto_equip',
                  where: 'tag_maquina_id = ?',
                  whereArgs: [tagMaquinaId]);
              List<ConjuntoEquip> conjuntosEquip = [];

              for (var conjEquip in conjuntoEquipData) {
                int conjEquipId = conjEquip['id'];
                List<Map<String, dynamic>> pontosData = await db.query('pontos',
                    where: 'conjunto_equip_id = ?', whereArgs: [conjEquipId]);
                List<Pontos> pontos = [];

                for (var ponto in pontosData) {
                  pontos.add(Pontos(
                    id: ponto['id'],
                    componentName: ponto['component_name'],
                    componentCodigo: ponto['component_codigo'],
                    qtyPontos: ponto['qty_pontos'],
                    atvBreveName: ponto['atv_breve_name'],
                    atvBreveCodigo: ponto['atv_breve_codigo'],
                    lubName: ponto['lub_name'],
                    lubCodigo: ponto['lub_codigo'],
                    qtyMaterial: ponto['qty_material'],
                    condOpName: ponto['cond_op_name'],
                    condOpCodigo: ponto['cond_op_codigo'],
                    tempoAtv: ponto['tempo_atv'],
                    periodName: ponto['period_name'],
                    periodCodigo: ponto['period_codigo'],
                    qtyPessoas: ponto['qty_pessoas'],
                    planoId: ponto['plano_id'],
                    conjuntoEquipId: ponto['conjunto_equip_id'],
                  ));
                }

                conjuntosEquip.add(ConjuntoEquip(
                  id: conjEquip['id'],
                  conjNome: conjEquip['conj_nome'],
                  equiNome: conjEquip['equi_nome'],
                  planoId: conjEquip['plano_id'],
                  tagMaquinaId: conjEquip['tag_maquina_id'],
                  pontos: pontos,
                ));
              }

              tagsMaquinas.add(TagMaquina(
                id: tagMaquina['id'],
                tagNome: tagMaquina['tag_nome'],
                maquinaNome: tagMaquina['maquina_nome'],
                planoId: tagMaquina['plano_id'],
                linhaId: tagMaquina['linha_id'],
                conjuntosEquip: conjuntosEquip,
              ));
            }

            linhas.add(Linha(
              id: linha['id'],
              nome: linha['nome'],
              planoId: linha['plano_id'],
              subareaId: linha['subarea_id'],
              tagsMaquinas: tagsMaquinas,
            ));
          }

          subareas.add(Subarea(
            id: subarea['id'],
            nome: subarea['nome'],
            planoId: subarea['plano_id'],
            areaId: subarea['area_id'],
            linhas: linhas,
          ));
        }

        areas.add(Area(
          id: area['id'],
          nome: area['nome'],
          planoId: area['plano_id'],
          subareas: subareas,
        ));
      }

      planolubs.add(Planolub(
        id: data['id'],
        cliente: data['cliente'],
        dataCadastro: data['data_cadastro'],
        dataRevisao: data['data_revisao'],
        responsavelLubrificacao: data['responsavel_lubrificacao'],
        responsavelKluber: data['responsavel_kluber'],
        codigoMobile: data['codigo_mobile'],
        areas: areas,
      ));
    }
    print(planolubs);

    return planolubs;
  }
}

class Planolub {
  int id;
  String cliente;
  String dataCadastro;
  String dataRevisao;
  String responsavelLubrificacao;
  String responsavelKluber;
  String codigoMobile;
  List<Area> areas;

  Planolub({
    required this.id,
    required this.cliente,
    required this.dataCadastro,
    required this.dataRevisao,
    required this.responsavelLubrificacao,
    required this.responsavelKluber,
    required this.codigoMobile,
    required this.areas,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente': cliente,
      'data_cadastro': dataCadastro,
      'data_revisao': dataRevisao,
      'responsavel_lubrificacao': responsavelLubrificacao,
      'responsavel_kluber': responsavelKluber,
      'codigo_mobile': codigoMobile,
      'areas': areas.map((area) => area.toJson()).toList(),
    };
  }
}

class Area {
  int id;
  String nome;
  int planoId;
  List<Subarea> subareas;

  Area({
    required this.id,
    required this.nome,
    required this.planoId,
    required this.subareas,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'plano_id': planoId,
      'subareas': subareas.map((subarea) => subarea.toJson()).toList(),
    };
  }
}

class Subarea {
  int id;
  String nome;
  int planoId;
  int areaId;
  List<Linha> linhas;

  Subarea({
    required this.id,
    required this.nome,
    required this.planoId,
    required this.areaId,
    required this.linhas,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'plano_id': planoId,
      'area_id': areaId,
      'linhas': linhas.map((linha) => linha.toJson()).toList(),
    };
  }
}

class Linha {
  int id;
  String nome;
  int planoId;
  int subareaId;
  List<TagMaquina> tagsMaquinas;

  Linha({
    required this.id,
    required this.nome,
    required this.planoId,
    required this.subareaId,
    required this.tagsMaquinas,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'plano_id': planoId,
      'subarea_id': subareaId,
      'tags_maquinas':
          tagsMaquinas.map((tagMaquina) => tagMaquina.toJson()).toList(),
    };
  }
}

class TagMaquina {
  int id;
  String tagNome;
  String maquinaNome;
  int planoId;
  int linhaId;
  List<ConjuntoEquip> conjuntosEquip;

  TagMaquina({
    required this.id,
    required this.tagNome,
    required this.maquinaNome,
    required this.planoId,
    required this.linhaId,
    required this.conjuntosEquip,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag_nome': tagNome,
      'maquina_nome': maquinaNome,
      'plano_id': planoId,
      'linha_id': linhaId,
      'conjuntos_equip':
          conjuntosEquip.map((conjEquip) => conjEquip.toJson()).toList(),
    };
  }
}

class ConjuntoEquip {
  int id;
  String conjNome;
  String equiNome;
  int planoId;
  int tagMaquinaId;
  List<Pontos> pontos;

  ConjuntoEquip({
    required this.id,
    required this.conjNome,
    required this.equiNome,
    required this.planoId,
    required this.tagMaquinaId,
    required this.pontos,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conj_nome': conjNome,
      'equi_nome': equiNome,
      'plano_id': planoId,
      'tag_maquina_id': tagMaquinaId,
      'pontos': pontos.map((ponto) => ponto.toJson()).toList(),
    };
  }
}

class Pontos {
  int id;
  String componentName;
  String componentCodigo;
  String qtyPontos;
  String atvBreveName;
  String atvBreveCodigo;
  String lubName;
  String lubCodigo;
  String qtyMaterial;
  String condOpName;
  String condOpCodigo;
  String periodName;
  String periodCodigo;
  String qtyPessoas;
  String tempoAtv;
  int planoId;
  int conjuntoEquipId;

  Pontos({
    required this.id,
    required this.componentName,
    required this.componentCodigo,
    required this.qtyPontos,
    required this.atvBreveName,
    required this.atvBreveCodigo,
    required this.lubName,
    required this.lubCodigo,
    required this.qtyMaterial,
    required this.condOpName,
    required this.condOpCodigo,
    required this.periodName,
    required this.periodCodigo,
    required this.qtyPessoas,
    required this.tempoAtv,
    required this.planoId,
    required this.conjuntoEquipId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'component_name': componentName,
      'component_codigo': componentCodigo,
      'qty_pontos': qtyPontos,
      'atv_breve_name': atvBreveName,
      'atv_breve_codigo': atvBreveCodigo,
      'lub_name': lubName,
      'lub_codigo': lubCodigo,
      'qty_material': qtyMaterial,
      'cond_op_name': condOpName,
      'cond_op_codigo': condOpCodigo,
      'period_name': periodName,
      'period_codigo': periodCodigo,
      'tempo_atv': tempoAtv,
      'qty_pessoas': qtyPessoas,
      'plano_id': planoId,
      'conjunto_equip_id': conjuntoEquipId,
    };
  }

  static fromJson(Map<String, dynamic> ponto) {
    return Pontos(
      id: ponto['id'],
      componentName: ponto['component_name'],
      componentCodigo: ponto['component_codigo'],
      qtyPontos: ponto['qty_pontos'],
      atvBreveName: ponto['atv_breve_name'],
      atvBreveCodigo: ponto['atv_breve_codigo'],
      lubName: ponto['lub_name'],
      lubCodigo: ponto['lub_codigo'],
      qtyMaterial: ponto['qty_material'],
      condOpName: ponto['cond_op_name'],
      condOpCodigo: ponto['cond_op_codigo'],
      tempoAtv: ponto['tempo_atv'],
      periodName: ponto['period_name'],
      periodCodigo: ponto['period_codigo'],
      qtyPessoas: ponto['qty_pessoas'],
      planoId: ponto['plano_id'],
      conjuntoEquipId: ponto['conjunto_equip_id'],
    );
  }
}
