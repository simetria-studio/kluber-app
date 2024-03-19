import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/arvore.dart';

class EditLinha extends StatefulWidget {
  final int linhaId;
  final int id;
  const EditLinha({super.key, required this.linhaId, required this.id});

  @override
  State<EditLinha> createState() => _EditLinhaState();
}

class _EditLinhaState extends State<EditLinha> {
  final DatabaseHelper databaseHelper = DatabaseHelper();
  final TextEditingController _nomeController = TextEditingController();
  String cliente = '';
  String dataCadastro = '';
  String dataRevisao = '';
  String responsavelLubrificacao = '';
  String responsavelKluber = '';
  int planoid = 0;

  @override
  void initState() {
    super.initState();
    _carregarDadosSubArea();
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
    var plano = await databaseHelper.getLinhaById(widget.id);
    if (plano != null) {
      return plano;
    } else {
      // Trate o caso em que não há plano encontrado pelo ID
      // Por exemplo, você pode retornar um mapa vazio
      return {};
    }
  }

  Future<void> _carregarDadosSubArea() async {
    var areaData = await databaseHelper.getLinhaById(widget.linhaId);
    if (areaData != null) {
      setState(() {
        _nomeController.text = areaData['nome'];
        // Inicialize outros controladores para outros campos, se necessário
      });
    }
  }

  void _salvarAlteracoes() {
    final Map<String, dynamic> novosDados = {
      'id': widget.linhaId,
      'nome': _nomeController.text,
      // Adicione mais chaves para outros dados da área, se necessário
    };

    databaseHelper.editarLinha(novosDados);

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Arvore(idPlano: widget.id);
    }));
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
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
                  labelText: 'Linha: ',
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
}
