import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/class/float_buttom.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/db/sync_db.dart';
import 'package:kluber/pages/planos_lub/arvore.dart';
import 'package:kluber/pages/planos_lub/edit_plano.dart';
import 'package:intl/intl.dart';

class Planos extends StatefulWidget {
  const Planos({super.key});

  @override
  State<Planos> createState() => _PlanosState();
}

class _PlanosState extends State<Planos> {
  late Future<List<Map<String, dynamic>>> _planosFuture;

  @override
  void initState() {
    super.initState();
    _loadPlanos();
  }

  String formatarData(String dataString) {
    DateTime data = DateTime.parse(dataString);
    DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(data);
  }

  Future<void> _loadPlanos() async {
    final databaseHelper = DatabaseHelper();
    _planosFuture = databaseHelper.getPlanosLub();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Planos'.toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: ColorConfig.amarelo,
        actions: <Widget>[
          TextButton(
            child: const Text(
              'Sincronizar',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              final sincronizador = Sincronizador();
              final result = await sincronizador.sincronizarDados();
              if (result) {
                _loadPlanos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dados sincronizados com sucesso!'),
                    duration: Duration(seconds: 2), // Duração da SnackBar
                  ),
                );
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Se houver mais widgets, eles podem ser adicionados aqui.
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _planosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum plano encontrado'));
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final plano = snapshot.data![index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                plano['cliente'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text('Plano: ${plano['id']}'),
                              Text(
                                  'Cadastro: ${formatarData(plano['data_cadastro'])}'),
                              Text(
                                  'Revisão: ${formatarData(plano['data_revisao'])}'),
                              Text(
                                  'Responsável: ${plano['responsavel_lubrificacao']}'),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditPlano(
                                              idPlano: plano['id'],
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ColorConfig.amarelo,
                                      ),
                                      child: const Text(
                                        'Editar',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                Arvore(idPlano: plano['id']),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ColorConfig.amarelo,
                                      ),
                                      child: const Text(
                                        'Terminar',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
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
