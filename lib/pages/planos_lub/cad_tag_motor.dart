import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/arvore.dart';

class CadTagMotor extends StatefulWidget {
  final int linhaId;
  final int planoId;
  const CadTagMotor({super.key, required this.linhaId, required this.planoId});

  @override
  State<CadTagMotor> createState() => _CadTagMotorState();
}

class _CadTagMotorState extends State<CadTagMotor> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _motorController = TextEditingController();
  String cliente = '';
  String dataCadastro = '';
  String dataRevisao = '';
  String responsavelLubrificacao = '';
  String responsavelKluber = '';
  int id = 0;
  final databaseHelper = DatabaseHelper();

  Future<Map<String, dynamic>> _carregarDadosDoPlano() async {
    // Aqui você deve buscar os dados do plano de lubrificação pelo ID
    // Utilize o widget.idPlano para acessar o ID passado como parâmetro
    var plano = await _databaseHelper.getPlanoLubById(widget.planoId);
    if (plano != null) {
      return plano;
    } else {
      // Trate o caso em que não há plano encontrado pelo ID
      // Por exemplo, você pode retornar um mapa vazio
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarDadosDoPlano().then((plano) {
      setState(() {
        id = plano['id'];
        cliente = plano['cliente'];
        dataCadastro = plano['data_cadastro'];
        dataRevisao = plano['data_revisao'];
        responsavelLubrificacao = plano['responsavel_lubrificacao'];
        responsavelKluber = plano['responsavel_kluber'];
      });
    });
  }

  Future<int> salvarTag() async {
    try {
      String tag = _tagController.text;
      String motor = _motorController.text;
      print(motor);
      // Organiza os dados em um mapa
      Map<String, dynamic> tagCad = {
        'tag_nome': tag,
        'maquina_nome': motor,
        'linha_id': widget.linhaId,
        'plano_id': widget.planoId,
      };

      // Insere os dados na base de dados e retorna o ID do plano inserido
      int id = await _databaseHelper.insertTag(tagCad);
      return id;
    } catch (e) {
      return -1; // Retorna -1 em caso de falha
    }
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
      body: Column(
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Tag: ',
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _motorController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Motor: ',
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text('Cancelar'),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: ColorConfig.amarelo,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      int idPlano = await salvarTag();
                      if (idPlano != -1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Arvore(idPlano: id),
                          ),
                        );
                      }
                    },
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
