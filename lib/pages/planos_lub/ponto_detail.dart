import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/class/float_buttom.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/homepage.dart';
import 'package:kluber/pages/planos_lub/arvore.dart';
import 'package:kluber/pages/planos_lub/edit_ponto.dart';
// import 'package:flutter_icons/flutter_icons.dart'; // Certifique-se de adicionar este pacote ao seu pubspec.yaml

class PontoDetail extends StatefulWidget {
  final int id;
  final int planoId;

  const PontoDetail({Key? key, required this.id, required this.planoId})
      : super(key: key);

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
    }
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: ColorConfig.amarelo),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Arvore(idPlano: widget.planoId),
              )),
        ),
        title: Text(
          'Ver Ponto'.toUpperCase(),
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: ColorConfig.amarelo,
        centerTitle: true,
      ),
      body: _pontoDetails != null
          ? SingleChildScrollView(
              child: Card(
                margin: const EdgeInsets.all(20),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'Ponto de Lubrificação',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EditPonto(
                                          pontoId: _pontoDetails!['id'],
                                          planoId: widget.planoId,
                                        ) // Alteração aqu),
                                    ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: ColorConfig.amarelo),
                            child: const Text('Editar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Deletar Ponto'),
                                    content: const Text(
                                        'Tem certeza que deseja deletar este ponto?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _databaseHelper.excluirPonto(
                                              _pontoDetails!['id']);
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomePage(),
                                            ),
                                          );
                                        },
                                        child: const Text('Deletar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                foregroundColor: ColorConfig.amarelo,
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 0, 0)),
                            child: const Text('Deletar'),
                          ),
                        ],
                      ),

                      const Divider(),
                      _buildDetailItem(
                          'ID', _pontoDetails!['id'].toString(), Icons.vpn_key),
                      _buildDetailItem('Componente',
                          _pontoDetails!['component_name'], Icons.build_circle),
                      _buildDetailItem('Código do Componente',
                          _pontoDetails!['component_codigo'], Icons.code),
                      _buildDetailItem(
                          'Quantidade de pontos',
                          _pontoDetails!['qty_pontos'].toString(),
                          Icons.numbers),
                      _buildDetailItem('Atividade breve',
                          _pontoDetails!['atv_breve_name'], Icons.short_text),
                      _buildDetailItem('Código da atividade breve',
                          _pontoDetails!['atv_breve_codigo'], Icons.code_off),
                      _buildDetailItem(
                          'Material', _pontoDetails!['lub_name'], Icons.layers),
                      _buildDetailItem('Tempo de atividade',
                          _pontoDetails!['tempo_atv'], Icons.lock_clock),
                      _buildDetailItem(
                          'Quantidade de material',
                          _pontoDetails!['qty_material'].toString(),
                          Icons.format_list_numbered),
                      _buildDetailItem(
                          'Condição operacional',
                          _pontoDetails!['cond_op_name'],
                          Icons.settings_suggest),
                      _buildDetailItem('Código da condição operacional',
                          _pontoDetails!['cond_op_codigo'], Icons.code),
                      _buildDetailItem('Frequência',
                          _pontoDetails!['period_name'], Icons.repeat),
                      _buildDetailItem('Código da frequência',
                          _pontoDetails!['period_codigo'], Icons.code),
                      _buildDetailItem(
                          'Quantidade de pessoas',
                          _pontoDetails!['qty_pessoas'].toString(),
                          Icons.group),

                      // Adicione mais itens aqui
                      const Divider(),
                      // Continue adicionando itens...
                    ],
                  ),
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatBtn.build(
          context), // Chama o FloatingActionButton da classe FloatBtn
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatBtn.bottomAppBar(
          context), // Chama o BottomAppBar da classe FloatBtn
    );
  }
}
