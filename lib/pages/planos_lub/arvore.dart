import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/class/float_buttom.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/cad_area.dart';
import 'package:kluber/pages/planos_lub/cad_conjunto_equip.dart';
import 'package:kluber/pages/planos_lub/cad_linha.dart';
import 'package:kluber/pages/planos_lub/cad_pontos.dart';
import 'package:kluber/pages/planos_lub/cad_subarea.dart';
import 'package:kluber/pages/planos_lub/cad_tag_motor.dart';
import 'package:kluber/pages/planos_lub/edit_area.dart';
import 'package:kluber/pages/planos_lub/edit_conj_equi.dart';
import 'package:kluber/pages/planos_lub/edit_linha.dart';
import 'package:kluber/pages/planos_lub/edit_subarea.dart';
import 'package:kluber/pages/planos_lub/edit_tag_maquina.dart';
import 'package:kluber/pages/planos_lub/ponto_detail.dart';
import 'package:sqflite/sqflite.dart';

class Arvore extends StatefulWidget {
  final int idPlano;

  const Arvore({Key? key, required this.idPlano}) : super(key: key);

  @override
  State<Arvore> createState() => _AreaState();
}

class _AreaState extends State<Arvore> {
  List<AreaModel> areas = []; // Alteração aqui

  String cliente = '';
  String dataCadastro = '';
  String dataRevisao = '';
  String responsavelLubrificacao = '';
  String responsavelKluber = '';
  int id = 0;
  final databaseHelper = DatabaseHelper();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<void> _carregarDados() async {
    var plano = await databaseHelper.getPlanoLubById(widget.idPlano);
    if (plano != null) {
      setState(() {
        id = plano['id'];
        cliente = plano['cliente'];
        dataCadastro = plano['data_cadastro'];
        dataRevisao = plano['data_revisao'];
        responsavelLubrificacao = plano['responsavel_lubrificacao'];
        responsavelKluber = plano['responsavel_kluber'];
      });
    }
    // Aqui buscamos as áreas associadas ao plano e elas já vêm com as subáreas e linhas corretamente formatadas
    var areasResult = await getAreasByPlanoId(widget.idPlano);
    setState(() {
      areas = areasResult;
    });
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _carregarAreas();
  }

  Future<void> duplicarTagEMaquina(int tagMaquinaId) async {
    final Database db = await databaseHelper.database;
    // Passo 2.1: Recuperar a tag de máquina original
    var tagMaquina = await db
        .query('tag_maquina', where: 'id = ?', whereArgs: [tagMaquinaId]);
    if (tagMaquina.isNotEmpty) {
      // Passo 2.2: Duplicar a tag de máquina
      var novaTagId = await db.insert('tag_maquina', {
        ...tagMaquina.first,
        "id": null // Remover ID para garantir que um novo seja gerado
      });

      // Passo 2.3: Recuperar e duplicar os conjuntos de equipamentos associados
      var conjuntos = await db.query('conjunto_equip',
          where: 'tag_maquina_id = ?', whereArgs: [tagMaquinaId]);
      Map<int, int> idMap = {}; // Mapear ID original para novo ID do conjunto
      for (var conjunto in conjuntos) {
        int? originalId = conjunto['id'] as int?;

        int novoConjuntoId = await db.insert('conjunto_equip', {
          ...conjunto,
          "id": null, // Remover o ID original
          "tag_maquina_id":
              novaTagId // Atribuir novaTagId como a tag_maquina_id
        });

        idMap[originalId!] = novoConjuntoId;
      }

      // Novo Passo: Recuperar e duplicar os pontos associados aos conjuntos de equipamentos
      for (var originalId in idMap.keys) {
        var pontos = await db.query('pontos',
            where: 'conjunto_equip_id = ?', whereArgs: [originalId]);
        for (var ponto in pontos) {
          await db.insert('pontos', {
            ...ponto,
            "id": null, // Remover o ID original para que um novo seja gerado
            "conjunto_equip_id": idMap[
                originalId] // Usar o novo ID do conjunto para os pontos duplicados
          });
        }
      }
    }
  }

  Future<void> _excluirArea(int areaId) async {
    // Chama o método para excluir a área do banco de dados
    await databaseHelper.excluirArea(areaId);
    // Atualiza a lista de áreas após a exclusão
    await _carregarDados();
  }

  Future<void> _excluirSubArea(int areaId) async {
    // Chama o método para excluir a área do banco de dados
    await databaseHelper.excluirSubArea(areaId);
    // Atualiza a lista de áreas após a exclusão
    await _carregarDados();
  }

  Future<void> _excluirLinha(int areaId) async {
    // Chama o método para excluir a área do banco de dados
    await databaseHelper.excluirLinhas(areaId);
    // Atualiza a lista de áreas após a exclusão
    await _carregarDados();
  }

  Future<void> _excluirTagEquip(int areaId) async {
    // Chama o método para excluir a área do banco de dados
    await databaseHelper.excluirTagEquip(areaId);
    // Atualiza a lista de áreas após a exclusão
    await _carregarDados();
  }

  Future<void> _excluirConEquip(int areaId) async {
    // Chama o método para excluir a área do banco de dados
    await databaseHelper.excluirConjEquip(areaId);
    // Atualiza a lista de áreas após a exclusão
    await _carregarDados();
  }

  void _atualizarArea(AreaModel novaArea) {
    // Alteração aqui
    setState(() {
      final index = areas.indexWhere((area) => area.id == novaArea.id);
      if (index != -1) {
        areas[index] = novaArea;
      }
    });
  }

  Future<List<AreaModel>> getAreasByPlanoId(int planoId) async {
    final Database db = await databaseHelper.database;
    final List<Map<String, dynamic>> areasResult = await db.query(
      'area',
      where: 'plano_id = ?',
      whereArgs: [planoId],
    );
    List<AreaModel> areas = [];

    for (var areaData in areasResult) {
      int areaId = areaData['id'];
      List<Map<String, dynamic>> subareasMaps =
          await databaseHelper.getSubareasByAreaId(areaId);
      List<SubareaModel> subareasModels = [];

      for (var subareaMap in subareasMaps) {
        List<Map<String, dynamic>> linhasMaps =
            await databaseHelper.getLinhasBySubareaId(subareaMap['id']);
        List<LinhaModel> linhasModels = [];

        for (var linhaMap in linhasMaps) {
          List<Map<String, dynamic>> tagsMaquinasData =
              await databaseHelper.getTagsAndMaquinasByLinhaId(linhaMap['id']);

          // Dentro do loop que itera sobre as tags e máquinas
          List<TagMaquina> tagsMaquinas =
              await Future.wait(tagsMaquinasData.map((item) async {
            List<Map<String, dynamic>> conjEquipData =
                await databaseHelper.getConjuntoEquipByTagMaquinaId(item['id']);
            List<ConjuntoEquipModel> conjuntosEquip =
                await Future.wait(conjEquipData.map((conjEquip) async {
              List<Map<String, dynamic>> pontosData = await databaseHelper
                  .getPontosByConjuntoEquipId(conjEquip['id']);
              List<PontoLubModel> pontos = pontosData
                  .map((ponto) => PontoLubModel.fromMap(ponto))
                  .toList();

              return ConjuntoEquipModel(
                id: conjEquip['id'],
                conjNome: conjEquip['conj_nome'],
                equiNome: conjEquip['equi_nome'],
                pontosLub: pontos,
              );
            }).toList());

            return TagMaquina(
              tagNome: item['tag_nome'],
              maquinaNome: item['maquina_nome'],
              id: item['id'],
              conjuntosEquip: conjuntosEquip,
            );
          }).toList());

          linhasModels.add(LinhaModel(
            id: linhaMap['id'],
            nome: linhaMap['nome'],
            tagsMaquinas: tagsMaquinas,
            isVisible: true,
          ));
        }

        subareasModels.add(SubareaModel(
          id: subareaMap['id'],
          nome: subareaMap['nome'],
          linhas: linhasModels,
          isVisible: true,
        ));
      }

      areas.add(AreaModel(
        id: areaId,
        nome: areaData['nome'],
        subareas: subareasModels,
        isVisible: false,
      ));
    }

    return areas;
  }

  final List<Map<String, dynamic>> _areas = [];
  final List<SubareaModel> _subareas = [];
  final List<LinhaModel> _linhas = [];
  AreaModel? _selectedArea;
  SubareaModel? _selectedSubarea;
  LinhaModel? _selectedLinha;

  Future<void> _carregarAreas() async {
    final areas = await _databaseHelper.getAreas(widget.idPlano);

    setState(() {
      _areas.clear();
      _areas.addAll(areas);
      _subareas.clear();
      // Chame o método para carregar as subáreas (se necessário
    });
  }

  Future<void> _carregarSubareas(int areaId) async {
    try {
      // Carrega as subáreas correspondentes à área selecionada
      final List<Map<String, dynamic>> subareasRaw =
          await _databaseHelper.getSubareasByAreaId(areaId);

      // Convertendo cada mapa em uma instância de SubareaModel
      final List<SubareaModel> subareas =
          subareasRaw.map((map) => SubareaModel.fromMap(map)).toList();

      setState(() {
        _subareas.clear();
        _subareas.addAll(subareas);

        // Verifica se a lista de subáreas não está vazia
        if (_subareas.isNotEmpty) {
          // Atribui a primeira subárea selecionada, se necessário
          _selectedSubarea = _subareas.first;
        } else {
          _selectedSubarea =
              null; // Garante que _selectedSubarea é nulo se não houver subáreas
        }
      });
    } catch (error) {
      print('Erro ao carregar subáreas: $error');
      // Tratamento de erros, como mostrar uma mensagem de erro ao usuário
    }
  }

  Future<void> _carregarLinhas(int subareaId) async {
    // Carrega as linhas correspondentes à subárea selecionada
    final List<Map<String, dynamic>> linhasRaw =
        await _databaseHelper.getLinhasBySubareaId(subareaId);

    // Convertendo cada mapa em uma instância de LinhaModel
    final List<LinhaModel> linhas =
        linhasRaw.map((map) => LinhaModel.fromMap(map)).toList();

    setState(() {
      // Atualiza a lista de linhas
      _linhas.clear();
      _linhas.addAll(linhas);

      // Verifica se a lista de linhas não está vazia
      if (_linhas.isNotEmpty) {
        // Atribui a primeira linha selecionada, se necessário
        _selectedLinha = _linhas.first;
      } else {
        _selectedLinha =
            null; // Garante que _selectedLinha é nulo se não houver linhas
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'plano #$id'.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              textBaseline: TextBaseline.alphabetic,
            ),
          ),
        ),
        backgroundColor: ColorConfig.amarelo,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 3, left: 10),
                      child: Text(
                        'Plano: $id',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 3, left: 10),
                      child: Text(
                        'Cliente: $cliente',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorConfig.cinza),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CadArea(idPlano: id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.amarelo,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cadastrar Área',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Para evitar problemas de rolagem dentro de um SingleChildScrollView
              itemCount: areas.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: const Border(
                            bottom: BorderSide(
                              color: ColorConfig.preto,
                            ),
                            left: BorderSide(
                              color: ColorConfig.preto,
                            ),
                            top: BorderSide(
                              color: ColorConfig.preto,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.only(left: 10),
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              flex:
                                  3, // Isso permite que o widget de texto ocupe 75% do espaço
                              child: Text(
                                  'Área: ${areas[index].nome}'), // Alteração aqui
                            ),
                            const SizedBox(
                                width: 10), // Espaço entre o texto e o botão
                            Expanded(
                              flex:
                                  1, // Isso permite que o botão ocupe 25% do espaço
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: ColorConfig.amarelo,
                                      border: Border.all(
                                        color: ColorConfig.preto,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    width: 40,
                                    child: IconButton(
                                      icon: areas[index].isVisible
                                          ? const Icon(Icons.visibility_off)
                                          : const Icon(Icons.visibility),
                                      color: Colors.black,
                                      onPressed: () {
                                        setState(() {
                                          areas[index].isVisible =
                                              !areas[index].isVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: ColorConfig.amarelo,
                                      border: Border.all(
                                        color: ColorConfig.preto,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    width: 40,
                                    child: IconButton(
                                      icon: const Icon(Icons.menu),
                                      color: Colors.black,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            // Retorna um AlertDialog ou um Widget personalizado
                                            return AlertDialog(
                                              title: const Text('Ações'),
                                              content: SingleChildScrollView(
                                                child: ListBody(
                                                  children: <Widget>[
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                CadSubArea(
                                                                    areaId: areas[
                                                                            index]
                                                                        .id, // Alteração aqui
                                                                    idPlano:
                                                                        id),
                                                          ),
                                                        );
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            ColorConfig.amarelo,
                                                      ),
                                                      child: const Text(
                                                        'Cadastrar Sub Area',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        // Substitua `context` e `suaAreaId` pelos valores apropriados
                                                        final novosDados =
                                                            await Navigator
                                                                .push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    EditArea(
                                                              areaId:
                                                                  areas[index]
                                                                      .id,
                                                              id: widget
                                                                  .idPlano, // Alteração aqui
                                                            ),
                                                          ),
                                                        );

                                                        // Verifica se novosDados não é nulo
                                                        if (novosDados !=
                                                            null) {
                                                          // Aqui você chama o método para atualizar os dados no banco
                                                          await databaseHelper
                                                              .editarArea(
                                                                  novosDados);
                                                          // Atualiza a lista de áreas
                                                          _atualizarArea(
                                                              novosDados);
                                                        }
                                                      },
                                                      child: const Text(
                                                          'Editar Área',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .black)),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        // Exibe um diálogo de confirmação antes de excluir
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                  "Confirmação"),
                                                              content: const Text(
                                                                  "Tem certeza de que deseja excluir este item?"),
                                                              actions: <Widget>[
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(); // Fecha o diálogo de confirmação
                                                                  },
                                                                  child: const Text(
                                                                      "Cancelar"),
                                                                ),
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    // Confirma a exclusão
                                                                    _excluirArea(
                                                                        areas[index]
                                                                            .id); // Chama o método de exclusão
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(); // Fecha o diálogo de confirmação
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(); // Fecha a tela atual
                                                                  },
                                                                  child: const Text(
                                                                      "Confirmar"),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.black,
                                                      ),
                                                      child: const Text(
                                                        'Deletar',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: const Text('Fechar',
                                                      style: TextStyle(
                                                          color: ColorConfig
                                                              .preto)),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Aqui, verificamos se a área está visível e se ela possui subáreas
                      if (areas[index].isVisible &&
                          areas[index].subareas.isNotEmpty)
                        ...areas[index]
                            .subareas
                            .map(
                              (subarea) => Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8, top: 8),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: const Border(
                                                bottom: BorderSide(
                                                  color: ColorConfig.preto,
                                                ),
                                                left: BorderSide(
                                                  color: ColorConfig.preto,
                                                ),
                                                top: BorderSide(
                                                  color: ColorConfig.preto,
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    child: Text(
                                                        'Subárea: ${subarea.nome}'),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Container(
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        Container(
                                                          width: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: ColorConfig
                                                                .amarelo,
                                                            border: Border.all(
                                                              color: ColorConfig
                                                                  .preto,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: IconButton(
                                                            onPressed: () {
                                                              setState(() {
                                                                // Aqui você inverteria o valor de isVisible para a subárea específica
                                                                subarea.isVisible =
                                                                    !subarea
                                                                        .isVisible;
                                                              });
                                                            },
                                                            icon: Icon(subarea
                                                                    .isVisible
                                                                ? Icons
                                                                    .visibility_off
                                                                : Icons
                                                                    .visibility),
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: ColorConfig
                                                                .amarelo,
                                                            border: Border.all(
                                                              color: ColorConfig
                                                                  .preto,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: IconButton(
                                                            onPressed: () {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
                                                                  // Retorna um AlertDialog ou um Widget personalizado
                                                                  return AlertDialog(
                                                                    title: const Text(
                                                                        'Ações'),
                                                                    content:
                                                                        SingleChildScrollView(
                                                                      child:
                                                                          ListBody(
                                                                        children: <Widget>[
                                                                          ElevatedButton(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.push(
                                                                                context,
                                                                                MaterialPageRoute(
                                                                                  builder: (context) => CadLinha(
                                                                                      subAreaId: subarea.id, // Alteração aqui
                                                                                      idPlano: id),
                                                                                ),
                                                                              );
                                                                            },
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              backgroundColor: ColorConfig.amarelo,
                                                                            ),
                                                                            child:
                                                                                const Text(
                                                                              'Cadastrar Linha',
                                                                              style: TextStyle(color: Colors.black),
                                                                            ),
                                                                          ),
                                                                          ElevatedButton(
                                                                            onPressed:
                                                                                () async {
                                                                              await Navigator.push(
                                                                                context,
                                                                                MaterialPageRoute(
                                                                                  builder: (context) => EditSubArea(
                                                                                    subAreaId: subarea.id,
                                                                                    id: widget.idPlano, // Alteração aqui
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                            child:
                                                                                const Text('Editar Sub Area', style: TextStyle(color: Colors.black)),
                                                                          ),
                                                                          ElevatedButton(
                                                                            onPressed:
                                                                                () {
                                                                              showDialog(
                                                                                context: context,
                                                                                builder: (BuildContext context) {
                                                                                  return AlertDialog(
                                                                                    title: const Text("Confirmação"),
                                                                                    content: const Text("Tem certeza de que deseja excluir este item?"),
                                                                                    actions: <Widget>[
                                                                                      TextButton(
                                                                                        onPressed: () {
                                                                                          Navigator.of(context).pop(); // Fecha o diálogo de confirmação
                                                                                        },
                                                                                        child: const Text("Cancelar"),
                                                                                      ),
                                                                                      TextButton(
                                                                                        onPressed: () {
                                                                                          _excluirSubArea(subarea.id); // Chama o método de exclusão
                                                                                          Navigator.of(context).pop(); // Fecha o diálogo de confirmação
                                                                                        },
                                                                                        child: const Text("Confirmar"),
                                                                                      ),
                                                                                    ],
                                                                                  );
                                                                                },
                                                                              );
                                                                            },
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              backgroundColor: Colors.black,
                                                                            ),
                                                                            child:
                                                                                const Text('Deletar', style: TextStyle(color: Colors.white)),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    actions: <Widget>[
                                                                      TextButton(
                                                                        child: const Text(
                                                                            'Fechar',
                                                                            style:
                                                                                TextStyle(color: ColorConfig.preto)),
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        },
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            icon: const Icon(
                                                                Icons.menu),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (subarea.isVisible &&
                                      subarea.linhas.isNotEmpty)
                                    ...subarea.linhas
                                        .map(
                                          (linha) => Column(
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  border: const Border(
                                                    bottom: BorderSide(
                                                      color: ColorConfig.preto,
                                                    ),
                                                    left: BorderSide(
                                                      color: ColorConfig.preto,
                                                    ),
                                                    top: BorderSide(
                                                      color: ColorConfig.preto,
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                margin: const EdgeInsets.only(
                                                    left: 40, top: 8),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 2,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4.0),
                                                        child: Text(
                                                            'Linha: ${linha.nome}'),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Container(
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Container(
                                                              width: 40,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color:
                                                                    ColorConfig
                                                                        .amarelo,
                                                                border:
                                                                    Border.all(
                                                                  color:
                                                                      ColorConfig
                                                                          .preto,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                              child: IconButton(
                                                                onPressed: () {
                                                                  setState(() {
                                                                    linha.isVisible =
                                                                        !linha
                                                                            .isVisible; // Alterna o estado de visibilidade
                                                                  });
                                                                },
                                                                icon: Icon(linha
                                                                        .isVisible
                                                                    ? Icons
                                                                        .visibility_off
                                                                    : Icons
                                                                        .visibility),
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 40,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color:
                                                                    ColorConfig
                                                                        .amarelo,
                                                                border:
                                                                    Border.all(
                                                                  color:
                                                                      ColorConfig
                                                                          .preto,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                              child: IconButton(
                                                                onPressed: () {
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      // Retorna um AlertDialog ou um Widget personalizado
                                                                      return AlertDialog(
                                                                        title: const Text(
                                                                            'Ações'),
                                                                        content:
                                                                            SingleChildScrollView(
                                                                          child:
                                                                              ListBody(
                                                                            children: <Widget>[
                                                                              ElevatedButton(
                                                                                onPressed: () {
                                                                                  Navigator.push(
                                                                                    context,
                                                                                    MaterialPageRoute(
                                                                                      builder: (context) => CadTagMotor(
                                                                                          linhaId: linha.id, // Alteração aqui
                                                                                          planoId: id),
                                                                                    ),
                                                                                  );
                                                                                },
                                                                                style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: ColorConfig.amarelo,
                                                                                ),
                                                                                child: const Text(
                                                                                  'Cadastrar TAG e Máquina',
                                                                                  style: TextStyle(color: Colors.black),
                                                                                ),
                                                                              ),
                                                                              ElevatedButton(
                                                                                onPressed: () async {
                                                                                  Navigator.push(
                                                                                    context,
                                                                                    MaterialPageRoute(
                                                                                      builder: (context) => EditLinha(
                                                                                          linhaId: subarea.id, // Alteração aqui
                                                                                          id: id),
                                                                                    ),
                                                                                  );
                                                                                },
                                                                                child: const Text('Editar', style: TextStyle(color: Colors.black)),
                                                                              ),
                                                                              ElevatedButton(
                                                                                onPressed: () {
                                                                                  showDialog(
                                                                                    context: context,
                                                                                    builder: (BuildContext context) {
                                                                                      return AlertDialog(
                                                                                        title: const Text("Confirmação"),
                                                                                        content: const Text("Tem certeza de que deseja excluir este item?"),
                                                                                        actions: <Widget>[
                                                                                          TextButton(
                                                                                            onPressed: () {
                                                                                              Navigator.of(context).pop(); // Fecha o diálogo de confirmação
                                                                                            },
                                                                                            child: const Text("Cancelar"),
                                                                                          ),
                                                                                          TextButton(
                                                                                            onPressed: () {
                                                                                              _excluirLinha(linha.id); // Chama o método de exclusão
                                                                                              Navigator.of(context).pop(); // Fecha o diálogo de confirmação
                                                                                            },
                                                                                            child: const Text("Confirmar"),
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                                    },
                                                                                  );
                                                                                },
                                                                                style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: Colors.black,
                                                                                ),
                                                                                child: const Text('Deletar', style: TextStyle(color: Colors.white)),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        actions: <Widget>[
                                                                          TextButton(
                                                                            child:
                                                                                const Text('Fechar', style: TextStyle(color: ColorConfig.preto)),
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.of(context).pop();
                                                                            },
                                                                          ),
                                                                        ],
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                                icon: const Icon(
                                                                    Icons.menu),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (linha.isVisible &&
                                                  subarea.linhas.isNotEmpty)
                                                ...linha.tagsMaquinas
                                                    .map(
                                                      (tagMaquina) => Column(
                                                        children: [
                                                          Container(
                                                            width:
                                                                double.infinity,
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 80,
                                                                    top: 8),
                                                            decoration:
                                                                BoxDecoration(
                                                              border:
                                                                  const Border(
                                                                bottom:
                                                                    BorderSide(
                                                                  color:
                                                                      ColorConfig
                                                                          .preto,
                                                                ),
                                                                left:
                                                                    BorderSide(
                                                                  color:
                                                                      ColorConfig
                                                                          .preto,
                                                                ),
                                                                top: BorderSide(
                                                                  color:
                                                                      ColorConfig
                                                                          .preto,
                                                                ),
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      flex: 2,
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            4.0),
                                                                        child:
                                                                            Column(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text('TAG: ${tagMaquina.tagNome}'),
                                                                            Text('MAQUINA: ${tagMaquina.maquinaNome}'),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      flex: 2,
                                                                      child:
                                                                          Container(
                                                                        child:
                                                                            Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.end,
                                                                          children: [
                                                                            Container(
                                                                              width: 40,
                                                                              decoration: BoxDecoration(
                                                                                color: ColorConfig.amarelo,
                                                                                border: Border.all(
                                                                                  color: ColorConfig.preto,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(10),
                                                                              ),
                                                                              child: IconButton(
                                                                                onPressed: () {
                                                                                  setState(() {
                                                                                    tagMaquina.isVisible = !tagMaquina.isVisible; // Alterna o estado de visibilidade
                                                                                    // Alterna o estado de visibilidade
                                                                                  });
                                                                                },
                                                                                icon: Icon(tagMaquina.isVisible ? Icons.visibility_off : Icons.visibility),
                                                                              ),
                                                                            ),
                                                                            Container(
                                                                              width: 40,
                                                                              decoration: BoxDecoration(
                                                                                color: ColorConfig.amarelo,
                                                                                border: Border.all(
                                                                                  color: ColorConfig.preto,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(10),
                                                                              ),
                                                                              child: IconButton(
                                                                                onPressed: () {
                                                                                  showDialog(
                                                                                    context: context,
                                                                                    builder: (BuildContext context) {
                                                                                      // Retorna um AlertDialog ou um Widget personalizado
                                                                                      return AlertDialog(
                                                                                        title: const Text('Ações'),
                                                                                        content: SingleChildScrollView(
                                                                                          child: ListBody(
                                                                                            children: [
                                                                                              ElevatedButton(
                                                                                                onPressed: () {
                                                                                                  print(linha.id);
                                                                                                  Navigator.push(
                                                                                                    context,
                                                                                                    MaterialPageRoute(
                                                                                                      builder: (context) => CadConjEqui(
                                                                                                          motorId: tagMaquina.id, // Alteração aqui
                                                                                                          planoId: id),
                                                                                                    ),
                                                                                                  );
                                                                                                },
                                                                                                style: ElevatedButton.styleFrom(
                                                                                                  backgroundColor: ColorConfig.amarelo,
                                                                                                ),
                                                                                                child: const Text(
                                                                                                  'Cadastrar Conjun. Equip.',
                                                                                                  style: TextStyle(color: Colors.black),
                                                                                                ),
                                                                                              ),
                                                                                              ElevatedButton(
                                                                                                onPressed: () async {
                                                                                                  await duplicarTagEMaquina(linha.id); // Supondo que este método já esteja implementado e funcione corretamente

                                                                                                  setState(() async {
                                                                                                    await _carregarDados(); // Isso recarrega todos os dados e atualiza a UI
                                                                                                    Navigator.of(context).pop();
                                                                                                    // Isso vai forçar a reconstrução do widget com os dados atualizados.
                                                                                                  });
                                                                                                },

                                                                                                child: const Text(
                                                                                                  'Duplicar',
                                                                                                  style: TextStyle(color: Colors.black),
                                                                                                ),
                                                                                                // Resto do código do botão...
                                                                                              ),
                                                                                              ElevatedButton(
                                                                                                onPressed: () {
                                                                                                  showDialog(
                                                                                                    context: context,
                                                                                                    builder: (BuildContext context) {
                                                                                                      // Criação de uma variável de estado local para o diálogo
                                                                                                      String? selectedAreaId;
                                                                                                      String? selectedSubareaId;
                                                                                                      String? selectedLinhaId;

                                                                                                      return StatefulBuilder(
                                                                                                        // Adiciona um StatefulBuilder para atualizar o estado dentro do AlertDialog
                                                                                                        builder: (context, setState) {
                                                                                                          return AlertDialog(
                                                                                                            title: const Text('Selecionar Área, Subárea e Linha'),
                                                                                                            content: Column(
                                                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                              mainAxisSize: MainAxisSize.min,
                                                                                                              children: [
                                                                                                                Container(
                                                                                                                  width: double.infinity,
                                                                                                                  padding: const EdgeInsets.all(5),
                                                                                                                  child: DropdownButton<String>(
                                                                                                                    borderRadius: BorderRadius.circular(10),
                                                                                                                    hint: const Text('Selecione a área'),
                                                                                                                    value: selectedAreaId,
                                                                                                                    onChanged: (newValue) {
                                                                                                                      setState(() {
                                                                                                                        selectedAreaId = newValue;
                                                                                                                        _carregarSubareas(int.parse(newValue!));
                                                                                                                      });
                                                                                                                    },
                                                                                                                    items: _areas.map<DropdownMenuItem<String>>((Map<String, dynamic> area) {
                                                                                                                      return DropdownMenuItem<String>(
                                                                                                                        value: area['id'].toString(),
                                                                                                                        child: Text(area['nome']),
                                                                                                                      );
                                                                                                                    }).toList(),
                                                                                                                  ),
                                                                                                                ),
                                                                                                                Container(
                                                                                                                  width: double.infinity,
                                                                                                                  padding: const EdgeInsets.all(5),
                                                                                                                  child: DropdownButton<String>(
                                                                                                                    borderRadius: BorderRadius.circular(10),
                                                                                                                    hint: const Text('Selecione a subárea'),
                                                                                                                    value: selectedSubareaId,
                                                                                                                    onChanged: _subareas.isNotEmpty
                                                                                                                        ? (newValue) {
                                                                                                                            setState(() {
                                                                                                                              selectedSubareaId = newValue;
                                                                                                                              _carregarLinhas(int.parse(newValue!));
                                                                                                                            });
                                                                                                                          }
                                                                                                                        : null,
                                                                                                                    items: _subareas.map<DropdownMenuItem<String>>((SubareaModel subarea) {
                                                                                                                      return DropdownMenuItem<String>(
                                                                                                                        value: subarea.id.toString(), // Asume-se que 'id' é numérico e precisa ser convertido para String
                                                                                                                        child: Text(subarea.nome),
                                                                                                                      );
                                                                                                                    }).toList(),
                                                                                                                  ),
                                                                                                                ),
                                                                                                                Container(
                                                                                                                  width: double.infinity,
                                                                                                                  padding: const EdgeInsets.all(5),
                                                                                                                  child: DropdownButton<String>(
                                                                                                                    borderRadius: BorderRadius.circular(10),
                                                                                                                    hint: const Text('Selecione a linha'),
                                                                                                                    value: selectedLinhaId,
                                                                                                                    onChanged: _linhas.isNotEmpty
                                                                                                                        ? (newValue) {
                                                                                                                            setState(() {
                                                                                                                              selectedLinhaId = newValue;
                                                                                                                              // Certifique-se de que 'id' é uma String ou converta-a conforme necessário
                                                                                                                            });
                                                                                                                          }
                                                                                                                        : null,
                                                                                                                    items: _linhas.map<DropdownMenuItem<String>>((LinhaModel linha) {
                                                                                                                      return DropdownMenuItem<String>(
                                                                                                                        value: linha.id.toString(), // Asume-se que 'id' é numérico e precisa ser convertido para String
                                                                                                                        child: Text(linha.nome),
                                                                                                                      );
                                                                                                                    }).toList(),
                                                                                                                  ),
                                                                                                                ),
                                                                                                                ElevatedButton(
                                                                                                                  onPressed: () async {
                                                                                                                    bool sucesso = true;
                                                                                                                    String mensagem = 'Copiado com sucesso';

                                                                                                                    // Copiar tag_maquina
                                                                                                                    Map<String, dynamic> novaTagMaquinaData = {
                                                                                                                      'tag_nome': tagMaquina.tagNome,
                                                                                                                      'maquina_nome': tagMaquina.maquinaNome,
                                                                                                                      'linha_id': selectedLinhaId,
                                                                                                                    };

                                                                                                                    final int novaTagMaquinaId = await databaseHelper.insertTag(novaTagMaquinaData);

                                                                                                                    if (novaTagMaquinaId > 0) {
                                                                                                                      // Verificar se existem conjuntos_equip associados à tag_maquina original
                                                                                                                      final List<Map<String, dynamic>> conjuntosExistentes = await databaseHelper.getConjuntoEquipByTagMaquinaId(tagMaquina.id);

                                                                                                                      for (var conjunto in conjuntosExistentes) {
                                                                                                                        Map<String, dynamic> novoConjuntoEquipData = {
                                                                                                                          'conj_nome': conjunto['conj_nome'],
                                                                                                                          'equi_nome': conjunto['equi_nome'],
                                                                                                                          'tag_maquina_id': novaTagMaquinaId,
                                                                                                                        };

                                                                                                                        final int novoConjuntoEquipId = await databaseHelper.insertConjuntoAndEquip(novoConjuntoEquipData);

                                                                                                                        if (novoConjuntoEquipId <= 0) {
                                                                                                                          sucesso = false;
                                                                                                                          mensagem = 'Erro ao criar cópia de conjunto e equipamento.';
                                                                                                                          break; // Sai do loop se houver falha
                                                                                                                        } else {
                                                                                                                          // Duplicar os pontos associados ao conjunto de equipamentos original
                                                                                                                          final List<Map<String, dynamic>> pontosExistentes = await databaseHelper.getPontosByConjuntoEquipId(conjunto['id']);

                                                                                                                          for (var ponto in pontosExistentes) {
                                                                                                                            await databaseHelper.insertPontos({
                                                                                                                              ...ponto,
                                                                                                                              'id': null, // Remover o ID original para que um novo seja gerado
                                                                                                                              'conjunto_equip_id': novoConjuntoEquipId, // Atribuir novoConjuntoEquipId como o conjunto_equip_id para os pontos duplicados
                                                                                                                            });
                                                                                                                          }
                                                                                                                        }
                                                                                                                      }
                                                                                                                    } else {
                                                                                                                      sucesso = false;
                                                                                                                      mensagem = 'Erro ao criar nova tag_maquina.';
                                                                                                                    }

                                                                                                                    if (sucesso) {
                                                                                                                      await _carregarDados(); // Certifique-se de que esta função seja assíncrona ou remova o await se não for necessário
                                                                                                                    }

                                                                                                                    // Mostrar mensagem de sucesso ou erro
                                                                                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));

                                                                                                                    // Fechar modal apenas uma vez aqui
                                                                                                                    Navigator.of(context).pop();
                                                                                                                  },
                                                                                                                  style: ElevatedButton.styleFrom(
                                                                                                                    backgroundColor: Colors.amber, // Ajuste conforme necessário
                                                                                                                  ),
                                                                                                                  child: const Text(
                                                                                                                    'Copiar',
                                                                                                                    style: TextStyle(color: Colors.black),
                                                                                                                  ),
                                                                                                                ),
                                                                                                              ],
                                                                                                            ),
                                                                                                            actions: <Widget>[
                                                                                                              TextButton(
                                                                                                                onPressed: () {
                                                                                                                  Navigator.of(context).pop();
                                                                                                                },
                                                                                                                child: const Text('Fechar'),
                                                                                                              ),
                                                                                                              // Adicione outros botões de ação conforme necessário
                                                                                                            ],
                                                                                                          );
                                                                                                        },
                                                                                                      );
                                                                                                    },
                                                                                                  );
                                                                                                },
                                                                                                style: ElevatedButton.styleFrom(
                                                                                                  backgroundColor: ColorConfig.amarelo,
                                                                                                ),
                                                                                                child: const Text(
                                                                                                  'Copiar',
                                                                                                  style: TextStyle(color: Colors.black),
                                                                                                ),
                                                                                              ),
                                                                                              ElevatedButton(
                                                                                                onPressed: () async {
                                                                                                  Navigator.push(
                                                                                                    context,
                                                                                                    MaterialPageRoute(
                                                                                                      builder: (context) => EditTagMaquina(
                                                                                                          tagMaquinaId: tagMaquina.id, // Alteração aqui
                                                                                                          id: id),
                                                                                                    ),
                                                                                                  );
                                                                                                },
                                                                                                child: const Text('Editar', style: TextStyle(color: Colors.black)),
                                                                                              ),
                                                                                              ElevatedButton(
                                                                                                onPressed: () {
                                                                                                  showDialog(
                                                                                                    context: context,
                                                                                                    builder: (BuildContext context) {
                                                                                                      return AlertDialog(
                                                                                                        title: const Text("Confirmação"),
                                                                                                        content: const Text("Tem certeza de que deseja excluir este item?"),
                                                                                                        actions: <Widget>[
                                                                                                          TextButton(
                                                                                                            onPressed: () {
                                                                                                              Navigator.of(context).pop(); // Fecha o diálogo de confirmação
                                                                                                            },
                                                                                                            child: const Text("Cancelar"),
                                                                                                          ),
                                                                                                          TextButton(
                                                                                                            onPressed: () {
                                                                                                              _excluirTagEquip(tagMaquina.id); // Chama o método de exclusão
                                                                                                              Navigator.of(context).pop();
                                                                                                              Navigator.of(context).pop(); // Fecha o diálogo de confirmação
                                                                                                            },
                                                                                                            child: const Text("Confirmar"),
                                                                                                          ),
                                                                                                        ],
                                                                                                      );
                                                                                                    },
                                                                                                  );
                                                                                                },
                                                                                                style: ElevatedButton.styleFrom(
                                                                                                  backgroundColor: Colors.black,
                                                                                                ),
                                                                                                child: const Text('Deletar', style: TextStyle(color: Colors.white)),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                        actions: <Widget>[
                                                                                          TextButton(
                                                                                            child: const Text('Fechar', style: TextStyle(color: ColorConfig.preto)),
                                                                                            onPressed: () {
                                                                                              Navigator.of(context).pop();
                                                                                            },
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                                    },
                                                                                  );
                                                                                },
                                                                                icon: const Icon(Icons.menu),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          // Aqui você pode adicionar os conjuntos de equipamentos
                                                          if (tagMaquina
                                                              .isVisible)
                                                            ...tagMaquina
                                                                .conjuntosEquip
                                                                .map(
                                                                    (conjuntoEquip) {
                                                              return Container(
                                                                width: double
                                                                    .infinity,
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            99,
                                                                        top: 8),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border:
                                                                      const Border(
                                                                    bottom:
                                                                        BorderSide(
                                                                      color: ColorConfig
                                                                          .preto,
                                                                    ),
                                                                    left:
                                                                        BorderSide(
                                                                      color: ColorConfig
                                                                          .preto,
                                                                    ),
                                                                    right:
                                                                        BorderSide(
                                                                      color: ColorConfig
                                                                          .preto,
                                                                    ),
                                                                    top:
                                                                        BorderSide(
                                                                      color: ColorConfig
                                                                          .preto,
                                                                    ),
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                ),
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          flex:
                                                                              4,
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                const EdgeInsets.all(4.0),
                                                                            child:
                                                                                Column(
                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text('CONJUNTO: ${conjuntoEquip.conjNome}'),
                                                                                Text('EQUIPAMENTO: ${conjuntoEquip.equiNome}'),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Expanded(
                                                                          flex:
                                                                              1,
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                20,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: ColorConfig.amarelo,
                                                                              border: Border.all(
                                                                                color: ColorConfig.preto,
                                                                              ),
                                                                              borderRadius: BorderRadius.circular(10),
                                                                            ),
                                                                            child:
                                                                                IconButton(
                                                                              onPressed: () {
                                                                                showDialog(
                                                                                  context: context,
                                                                                  builder: (BuildContext context) {
                                                                                    // Retorna um AlertDialog ou um Widget personalizado
                                                                                    return AlertDialog(
                                                                                      title: const Text('Ações'),
                                                                                      content: SingleChildScrollView(
                                                                                        child: ListBody(
                                                                                          children: [
                                                                                            ElevatedButton(
                                                                                              onPressed: () {
                                                                                                Navigator.push(
                                                                                                  context,
                                                                                                  MaterialPageRoute(
                                                                                                    builder: (context) => CadPontos(
                                                                                                        conjuntoId: conjuntoEquip.id, // Alteração aqui
                                                                                                        idPlano: id),
                                                                                                  ),
                                                                                                );
                                                                                              },
                                                                                              style: ElevatedButton.styleFrom(
                                                                                                backgroundColor: ColorConfig.amarelo,
                                                                                              ),
                                                                                              child: const Text(
                                                                                                'Cadastrar Pontos de Lubrificação',
                                                                                                style: TextStyle(color: Colors.black),
                                                                                              ),
                                                                                            ),
                                                                                            ElevatedButton(
                                                                                              onPressed: () async {
                                                                                                Navigator.push(
                                                                                                  context,
                                                                                                  MaterialPageRoute(
                                                                                                    builder: (context) => EditConjEqui(
                                                                                                        conjEquiId: conjuntoEquip.id, // Alteração aqui
                                                                                                        id: id),
                                                                                                  ),
                                                                                                );
                                                                                              },
                                                                                              child: const Text('Editar', style: TextStyle(color: Colors.black)),
                                                                                            ),
                                                                                            ElevatedButton(
                                                                                              onPressed: () {
                                                                                                // Exibe um diálogo de confirmação antes de excluir
                                                                                                showDialog(
                                                                                                  context: context,
                                                                                                  builder: (BuildContext context) {
                                                                                                    return AlertDialog(
                                                                                                      title: const Text("Confirmação"),
                                                                                                      content: const Text("Tem certeza de que deseja excluir este item?"),
                                                                                                      actions: <Widget>[
                                                                                                        TextButton(
                                                                                                          onPressed: () {
                                                                                                            Navigator.of(context).pop(); // Fecha o diálogo de confirmação
                                                                                                          },
                                                                                                          child: const Text("Cancelar"),
                                                                                                        ),
                                                                                                        TextButton(
                                                                                                          onPressed: () {
                                                                                                            // Confirma a exclusão
                                                                                                            _excluirConEquip(conjuntoEquip.id); // Chama o método de exclusão
                                                                                                            Navigator.of(context).pop(); // Fecha o diálogo de confirmação
                                                                                                            Navigator.of(context).pop(); // Fecha a tela atual
                                                                                                          },
                                                                                                          child: const Text("Confirmar"),
                                                                                                        ),
                                                                                                      ],
                                                                                                    );
                                                                                                  },
                                                                                                );
                                                                                              },
                                                                                              style: ElevatedButton.styleFrom(
                                                                                                backgroundColor: Colors.black,
                                                                                              ),
                                                                                              child: const Text(
                                                                                                'Deletar',
                                                                                                style: TextStyle(color: Colors.white),
                                                                                              ),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ),
                                                                                      actions: <Widget>[
                                                                                        TextButton(
                                                                                          child: const Text('Fechar', style: TextStyle(color: ColorConfig.preto)),
                                                                                          onPressed: () {
                                                                                            Navigator.of(context).pop();
                                                                                          },
                                                                                        ),
                                                                                      ],
                                                                                    );
                                                                                  },
                                                                                );
                                                                              },
                                                                              icon: const Icon(Icons.menu),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    ...conjuntoEquip
                                                                        .pontosLub
                                                                        .map(
                                                                            (ponto) {
                                                                      return Container(
                                                                        child:
                                                                            Column(
                                                                          children: [
                                                                            TextButton(
                                                                              child: Text('Ponto: ${ponto.componentName} - ${ponto.componentDescricao} ', style: const TextStyle(color: ColorConfig.preto)),
                                                                              onPressed: () {
                                                                                Navigator.push(
                                                                                  context,
                                                                                  MaterialPageRoute(
                                                                                    builder: (context) => PontoDetail(id: ponto.id),
                                                                                  ),
                                                                                );
                                                                              },
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                  ],
                                                                ),
                                                              );
                                                            }).toList(),
                                                        ],
                                                      ),
                                                    )
                                                    .toList(),
                                              Container(
                                                width: double.infinity,
                                                margin: const EdgeInsets.only(
                                                    left: 80, top: 8),
                                                child: ElevatedButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all(ColorConfig
                                                                  .amarelo),
                                                      shape: MaterialStateProperty
                                                          .all<
                                                              RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Cadastrar TAG e Máquina',
                                                      style: TextStyle(
                                                          color: ColorConfig
                                                              .preto),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CadTagMotor(
                                                                  linhaId: linha
                                                                      .id, // Alteração aqui
                                                                  planoId: id),
                                                        ),
                                                      );
                                                    }),
                                              ),
                                            ],
                                          ),
                                        )
                                        .toList(),
                                ],
                              ),
                            )
                            .toList(),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatBtn.build(
          context), // Chama o FloatingActionButton da classe FloatBtn
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatBtn.bottomAppBar(
          context), // Chama o BottomAppBar da classe FloatBtn
    );
  }
}

class AreaModel {
  final int id;
  final String nome;
  List<SubareaModel> subareas;
  bool isVisible;

  AreaModel({
    required this.id,
    required this.nome,
    required this.subareas,
    this.isVisible = false,
  });

  factory AreaModel.fromMap(Map<String, dynamic> map) {
    return AreaModel(
      id: map['id'] as int,
      nome: map['nome'] as String,
      // A conversão de subáreas depende de como você quer tratar isso,
      // aqui está um exemplo onde inicializamos vazio já que o map não as contém
      subareas: [],
      isVisible:
          map.containsKey('isVisible') ? map['isVisible'] as bool : false,
    );
  }
}

class SubareaModel {
  final int id;
  final String nome;
  List<LinhaModel> linhas;
  bool isVisible;

  SubareaModel({
    required this.id,
    required this.nome,
    required this.linhas,
    this.isVisible = true,
  });

  factory SubareaModel.fromMap(Map<String, dynamic> map) {
    return SubareaModel(
      id: map['id'],
      nome: map['nome'],
      linhas: [], // Você precisará adaptar isso se linhas vierem do mapa
      isVisible: map['isVisible'] ?? true,
    );
  }
}

class LinhaModel {
  final int id;
  final String nome;
  bool isVisible;
  final List<TagMaquina> tagsMaquinas;
  final List<ConjuntoEquipModel> conjuntosEquip; // Adicione esta linha

  LinhaModel({
    required this.id,
    required this.nome,
    required this.tagsMaquinas,
    this.isVisible = true,
    this.conjuntosEquip = const [], // Adicione esta linha
  });

  factory LinhaModel.fromMap(Map<String, dynamic> map) {
    return LinhaModel(
      id: map['id'],
      nome: map['nome'],
      isVisible: map['isVisible'] ?? true,
      tagsMaquinas: [], // Você precisará adaptar isso se tagsMaquinas vierem do mapa
      conjuntosEquip: [], // Adicione esta linha
    );
  }
}

class TagMaquina {
  final String tagNome;
  final String maquinaNome;
  bool isVisible;
  final int id;
  final List<ConjuntoEquipModel>
      conjuntosEquip; // Adicione esta lista ao modelo

  TagMaquina({
    required this.tagNome,
    required this.maquinaNome,
    required this.conjuntosEquip,
    this.isVisible = true,
    required this.id,
    // Inclua no construtor
  });
}

class ConjuntoEquipModel {
  final int id;
  final String conjNome;
  final String equiNome;
  bool isVisible;
  List<PontoLubModel> pontosLub;

  ConjuntoEquipModel({
    required this.id,
    required this.conjNome,
    required this.equiNome,
    this.isVisible = true,
    this.pontosLub = const [],
  });
}

class PontoLubModel {
  final int id;
  final String componentName;
  final String componentCodigo;
  final String componentDescricao;
  bool isVisible;

  // Adicione outros campos conforme necessário

  PontoLubModel({
    required this.id,
    required this.componentName,
    required this.componentCodigo,
    required this.componentDescricao,
    this.isVisible = true,
    // Inicialize outros campos aqui
  });

  // Método para criar um PontoLubModel a partir de um Map.
  // Adapte os campos conforme necessário para corresponder à sua tabela 'pontos'
  factory PontoLubModel.fromMap(Map<String, dynamic> map) {
    return PontoLubModel(
      id: map['id'],
      componentName: map['component_name'],
      componentCodigo: map['component_codigo'],
      componentDescricao: map['atv_breve_name'],
      // Atribua outros campos aqui
    );
  }
}
