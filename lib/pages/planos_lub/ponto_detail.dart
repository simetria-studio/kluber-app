import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/db/database.dart';
import 'package:sqflite/sqflite.dart';

class PontoDetail extends StatefulWidget {
  final int id;
  const PontoDetail({Key? key, required this.id}) : super(key: key);

  @override
  State<PontoDetail> createState() => _PontoDetailState();
}

class _PontoDetailState extends State<PontoDetail> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Map<String, dynamic>? _pontoDetails;

  @override
  void initState() {
    super.initState();
    _loadPonto();
  }

  void _loadPonto() async {
    var ponto = await _databaseHelper.getPontoById(widget.id);
    if (ponto != null) {
      setState(() {
        _pontoDetails = ponto;
      });
    } else {
      // Trate o caso em que não há ponto encontrado pelo ID
      // Por exemplo, você pode exibir um diálogo de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Ver Ponto'.toUpperCase(),
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
      body: _pontoDetails != null
          ? Card(
              margin: const EdgeInsets.all(20),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Ponto de Lubrificação',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('ID: ${_pontoDetails!['id']}'),
                  Text('Componente: ${_pontoDetails!['component_name']}'),
                  Text(
                      'Código do Componente: ${_pontoDetails!['component_codigo']}'),
                  Text('Atividade breve: ${_pontoDetails!['atv_breve_name']}'),
                  // Adicione mais Text() widgets conforme necessário para exibir outros detalhes do ponto
                ],
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
