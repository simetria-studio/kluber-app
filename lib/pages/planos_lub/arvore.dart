import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/cad_area.dart';
import 'package:kluber/pages/planos_lub/edit_area.dart';

class Arvore extends StatefulWidget {
  final int idPlano;

  const Arvore({Key? key, required this.idPlano}) : super(key: key);

  @override
  State<Arvore> createState() => _AreaState();
}

class _AreaState extends State<Arvore> {
  List<Map<String, dynamic>> areas = [];
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
    // Aqui buscamos as áreas associadas ao plano
    var areasResult = await databaseHelper.getAreasByPlanoId(widget.idPlano);
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
                  title: Container(
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
                          child: Text('Área: ${areas[index]['nome']}'),
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
                                  icon: const Icon(Icons.visibility_off),
                                  color: Colors
                                      .black, // Substitua com a cor do ícone desejada
                                  onPressed: () {
                                    // Adicione o que deve acontecer quando o ícone é clicado
                                    print('Ícone de visibilidade clicado!');
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
                                                  onPressed: () {},
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        ColorConfig.amarelo,
                                                  ),
                                                  child: const Text(
                                                    'Cadastrar Sub Area',
                                                    style: TextStyle(
                                                        color: Colors.black),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            EditArea(
                                                                areaData: areas[
                                                                    index]),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        ColorConfig.amarelo,
                                                  ),
                                                  child: const Text(
                                                    'Editar',
                                                    style: TextStyle(
                                                        color: Colors.black),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _excluirArea(areas[index][
                                                        'id']); // Chama o método de exclusão
                                                    Navigator.of(context)
                                                        .pop(); // Fecha o AlertDialog
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.black,
                                                  ),
                                                  child: const Text(
                                                    'Deletar',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Fechar',
                                                  style: TextStyle(
                                                      color:
                                                          ColorConfig.preto)),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
