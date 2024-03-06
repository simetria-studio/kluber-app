import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/cad_area.dart';
import 'package:kluber/pages/planos_lub/cad_linha.dart';
import 'package:kluber/pages/planos_lub/cad_subarea.dart';
import 'package:kluber/pages/planos_lub/edit_area.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

class Arvore extends StatefulWidget {
  final int idPlano;

  const Arvore({Key? key, required this.idPlano}) : super(key: key);

  @override
  State<Arvore> createState() => _AreaState();
}

class _AreaState extends State<Arvore> {
  List<AreaModel> areas = []; // Alteração aqui
  final TreeViewController _controller = TreeViewController(children: []);
  String cliente = '';
  String dataCadastro = '';
  String dataRevisao = '';
  String responsavelLubrificacao = '';
  String responsavelKluber = '';
  int id = 0;
  final databaseHelper = DatabaseHelper();

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
  }

  Future<void> _excluirArea(int areaId) async {
    // Chama o método para excluir a área do banco de dados
    await databaseHelper.excluirArea(areaId);
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
        List<LinhaModel> linhasModels = linhasMaps
            .map((linhaMap) =>
                LinhaModel(id: linhaMap['id'], nome: linhaMap['nome']))
            .toList();

        subareasModels.add(SubareaModel(
          id: subareaMap['id'],
          nome: subareaMap['nome'],
          linhas: linhasModels,
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
                                                              areaId: areas[
                                                                      index]
                                                                  .id, // Alteração aqui
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
                                                        _excluirArea(areas[
                                                                index]
                                                            .id); // Chama o método de exclusão
                                                        Navigator.of(context)
                                                            .pop(); // Fecha o AlertDialog
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
                                    padding: const EdgeInsets.only(left: 20),
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
                                                                              // Substitua `context` e `suaAreaId` pelos valores apropriados
                                                                              final novosDados = await Navigator.push(
                                                                                context,
                                                                                MaterialPageRoute(
                                                                                  builder: (context) => EditArea(
                                                                                    areaId: areas[index].id, // Alteração aqui
                                                                                  ),
                                                                                ),
                                                                              );

                                                                              // Verifica se novosDados não é nulo
                                                                              if (novosDados != null) {
                                                                                // Aqui você chama o método para atualizar os dados no banco
                                                                                await databaseHelper.editarArea(novosDados);
                                                                                // Atualiza a lista de áreas
                                                                                _atualizarArea(novosDados);
                                                                              }
                                                                            },
                                                                            child:
                                                                                const Text('Editar Área', style: TextStyle(color: Colors.black)),
                                                                          ),
                                                                          ElevatedButton(
                                                                            onPressed:
                                                                                () {
                                                                              _excluirArea(areas[index].id); // Chama o método de exclusão
                                                                              Navigator.of(context).pop(); // Fecha o AlertDialog
                                                                            },
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              backgroundColor: Colors.black,
                                                                            ),
                                                                            child:
                                                                                const Text(
                                                                              'Deletar',
                                                                              style: TextStyle(color: Colors.white),
                                                                            ),
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
                                                                onPressed:
                                                                    () {},
                                                                icon: const Icon(
                                                                    Icons
                                                                        .visibility_off),
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
                                                                                      builder: (context) => CadLinha(
                                                                                          subAreaId: subarea.id, // Alteração aqui
                                                                                          idPlano: id),
                                                                                    ),
                                                                                  );
                                                                                },
                                                                                style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: ColorConfig.amarelo,
                                                                                ),
                                                                                child: const Text(
                                                                                  'Cadastrar Linha',
                                                                                  style: TextStyle(color: Colors.black),
                                                                                ),
                                                                              ),
                                                                              ElevatedButton(
                                                                                onPressed: () async {
                                                                                  // Substitua `context` e `suaAreaId` pelos valores apropriados
                                                                                  final novosDados = await Navigator.push(
                                                                                    context,
                                                                                    MaterialPageRoute(
                                                                                      builder: (context) => EditArea(
                                                                                        areaId: areas[index].id, // Alteração aqui
                                                                                      ),
                                                                                    ),
                                                                                  );

                                                                                  // Verifica se novosDados não é nulo
                                                                                  if (novosDados != null) {
                                                                                    // Aqui você chama o método para atualizar os dados no banco
                                                                                    await databaseHelper.editarArea(novosDados);
                                                                                    // Atualiza a lista de áreas
                                                                                    _atualizarArea(novosDados);
                                                                                  }
                                                                                },
                                                                                child: const Text('Editar Área', style: TextStyle(color: Colors.black)),
                                                                              ),
                                                                              ElevatedButton(
                                                                                onPressed: () {
                                                                                  _excluirArea(areas[index].id); // Chama o método de exclusão
                                                                                  Navigator.of(context).pop(); // Fecha o AlertDialog
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
                                              ), // Aqui você acessa `nome` diretamente
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
    );
  }
}

class AreaModel {
  final int id;
  final String nome;
  List<SubareaModel> subareas; // Alterado para usar o modelo SubareaModel
  bool isVisible;

  AreaModel({
    required this.id,
    required this.nome,
    required this.subareas,
    this.isVisible = false,
  });
}

class SubareaModel {
  final int id;
  final String nome;
  List<LinhaModel> linhas;
  bool isVisible; // Adicionado para controlar a visibilidade das linhas

  SubareaModel({
    required this.id,
    required this.nome,
    required this.linhas,
    this.isVisible = true, // As linhas são visíveis por padrão
  });
}

class LinhaModel {
  final int id;
  final String nome;

  LinhaModel({
    required this.id,
    required this.nome,
  });
}
