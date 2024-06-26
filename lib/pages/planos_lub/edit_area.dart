import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/arvore.dart';

class EditArea extends StatefulWidget {
  final int areaId;
  final int id;
  final int index;

  const EditArea(
      {Key? key, required this.areaId, required this.id, required this.index})
      : super(key: key);

  @override
  State<EditArea> createState() => _EditAreaState();
}

class _EditAreaState extends State<EditArea> {
  final DatabaseHelper databaseHelper = DatabaseHelper();
  late TextEditingController _nomeController;

  String cliente = '';
  String dataCadastro = '';
  String dataRevisao = '';
  String responsavelLubrificacao = '';
  String responsavelKluber = '';
  int planoid = 0;

  @override
  void initState() {
    super.initState();
    _carregarDadosArea();
    _carregarDadosDoPlano().then((plano) {
      setState(() {
        planoid = plano['id'];
        cliente = plano['cliente'];
        dataCadastro = plano['data_cadastro'];
        dataRevisao = plano['data_revisao'];
        responsavelLubrificacao = plano['responsavel_lubrificacao'];
        responsavelKluber = plano['responsavel_kluber'];
      });
    });
  }

  Future<Map<String, dynamic>> _carregarDadosDoPlano() async {
    // Aqui você deve buscar os dados do plano de lubrificação pelo ID
    // Utilize o widget.idPlano para acessar o ID passado como parâmetro
    var plano = await databaseHelper.getPlanoLubById(widget.id);
    if (plano != null) {
      return plano;
    } else {
      // Trate o caso em que não há plano encontrado pelo ID
      // Por exemplo, você pode retornar um mapa vazio
      return {};
    }
  }

  Future<void> _carregarDadosArea() async {
    var areaData = await databaseHelper.getAreaById(widget.areaId);
    if (areaData != null) {
      setState(() {
        _nomeController = TextEditingController(text: areaData['nome']);
        // Inicialize outros controladores para outros campos, se necessário
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'plano #$planoid'.toUpperCase(),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Area: ',
                ),
              ),
            ),
            // Adicione mais campos de entrada para outros dados da área
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _salvarAlteracoes();
              },
              child: const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }

  void _salvarAlteracoes() {
    final Map<String, dynamic> novosDados = {
      'id': widget.areaId,
      'nome': _nomeController.text,
      // Adicione mais chaves para outros dados da área, se necessário
    };

    databaseHelper.editarArea(novosDados);

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Arvore(
        idPlano: widget.id,
        idArea: widget.index,
      );
    }));
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }
}
