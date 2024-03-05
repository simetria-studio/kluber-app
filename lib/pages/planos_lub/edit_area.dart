import 'package:flutter/material.dart';
import 'package:kluber/db/database.dart';

class EditArea extends StatefulWidget {
  final int areaId;

  const EditArea({Key? key, required this.areaId}) : super(key: key);

  @override
  State<EditArea> createState() => _EditAreaState();
}

class _EditAreaState extends State<EditArea> {
  final DatabaseHelper databaseHelper = DatabaseHelper();
  late TextEditingController _nomeController;

  @override
  void initState() {
    super.initState();
    _carregarDadosArea();
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
        title: const Text('Editar Área'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
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
    Navigator.of(context).pop(novosDados);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }
}
