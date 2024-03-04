import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/class/float_buttom.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/area.dart';

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
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: ColorConfig.amarelo,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Se houver mais widgets, eles podem ser adicionados aqui.
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _planosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Nenhum plano encontrado'));
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final plano = snapshot.data![index];
                      return Card(
                        elevation: 4,
                        margin:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text('Plano: ${plano['id']}'),
                              Text('Cadastro: ${plano['data_cadastro']}'),
                              Text('Revisão: ${plano['data_revisao']}'),
                              Text(
                                  'Responsável: ${plano['responsavel_lubrificacao']}'),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Ação ao pressionar 'Editar'
                                      },
                                      child: Text(
                                        'Editar',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        primary: ColorConfig.amarelo,
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
                                                Area(idPlano: plano['id']),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Terminar',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        primary: ColorConfig.amarelo,
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
      bottomNavigationBar:
          FloatBtn.bottomAppBar(), // Chama o BottomAppBar da classe FloatBtn
    );
  }
}
