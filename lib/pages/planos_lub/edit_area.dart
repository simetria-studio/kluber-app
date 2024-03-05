import 'package:flutter/material.dart';

class EditArea extends StatefulWidget {
  final Map<String, dynamic> areaData;

  const EditArea({Key? key, required this.areaData}) : super(key: key);

  @override
  State<EditArea> createState() => _EditAreaState();
}

class _EditAreaState extends State<EditArea> {
  late TextEditingController _nomeController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.areaData['nome']);
    // Adicione mais controllers para outros campos, se necessário
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
      'id': widget.areaData['id'],
      'nome': _nomeController.text,
      // Adicione mais chaves para outros dados da área
    };

    // Chame a função para editar a área no banco de dados
    // Passando o mapa contendo os novos dados
    // Por exemplo: databaseHelper.editarArea(novosDados);

    // Depois de salvar as alterações, você pode navegar para outra tela
    // Ou exibir uma mensagem de sucesso, etc.
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }
}
