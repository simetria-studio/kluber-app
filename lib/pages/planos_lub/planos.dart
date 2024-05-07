import 'package:flutter/material.dart';
import 'package:kluber/class/api_config.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/class/float_buttom.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/db/sync_db.dart';
import 'package:kluber/pages/planos_lub/arvore.dart';
import 'package:kluber/pages/planos_lub/edit_plano.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Planos extends StatefulWidget {
  const Planos({super.key});

  @override
  State<Planos> createState() => _PlanosState();
}

class _PlanosState extends State<Planos> {
  late Future<List<Map<String, dynamic>>> _planosFuture;
  List<Map<String, dynamic>> planos = [];
  @override
  void initState() {
    super.initState();
    _loadPlanos();
    _loadPlanosFromAPI();
  }

  String formatarData(String dataString) {
    DateTime data = DateTime.parse(dataString);
    DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(data);
  }

  Future<void> _loadPlanosFromAPI() async {
    final databaseHelper = DatabaseHelper();

    final url = Uri.parse('${ApiConfig.apiUrl}/get-plan');
    final response = await http.post(url);

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      List<Map<String, dynamic>> planosAPI =
          responseData.map((data) => Map<String, dynamic>.from(data)).toList();

      // Obtém planos do SQLite
      List<Map<String, dynamic>> planosSQLite =
          await databaseHelper.getPlanosLub();

      // Conjunto para manter o controle dos códigos mobile dos planos já inseridos
      Set<String> codigosInseridos = {};

      for (var planoSQLite in planosSQLite) {
        bool foundMatch =
            false; // Flag para verificar se o planoSQLite tem correspondência com algum planoAPI
        for (var planoAPI in planosAPI) {
          if (planoSQLite['codigo_mobile'] == planoAPI['codigo_mobile']) {
            foundMatch = true;
            break; // Se encontrou uma correspondência, não é necessário continuar a busca
          }
        }

        // Adiciona o planoSQLite à lista de planos, sem duplicações
        if (!codigosInseridos.contains(planoSQLite['codigo_mobile'])) {
          Map<String, dynamic> plano = {
            'cliente': planoSQLite['cliente'],
            'id': planoSQLite['id'],
            'data_cadastro': planoSQLite['data_cadastro'],
            'data_revisao': planoSQLite['data_revisao'],
            'responsavel_lubrificacao': planoSQLite['responsavel_kluber'],
            'codigo_mobile': planoSQLite['codigo_mobile'],
            'hasLocalPlan': foundMatch
                ? 1
                : 0, // Adiciona a tag apenas se houver correspondência
          };
          planos.add(plano);
          codigosInseridos.add(planoSQLite['codigo_mobile']);
        }
      }
      setState(() {
        _planosFuture = Future.value(planos);
      });
    } else {
      throw Exception('Failed to load planos');
    }
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
              try {
                final result = await sincronizador.sincronizarDados();

                if (result) {
                  await Future.delayed(
                      const Duration(seconds: 2)); // Atraso de 2 segundos
                  setState(() {
                    _loadPlanos();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados sincronizados com sucesso!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao sincronizar dados: $e'),
                    duration: const Duration(seconds: 2),
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
                      print(plano);
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
                                'Cliente: ${plano['cliente']}',
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
                                  if (plano['hasLocalPlan'] == 0)
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
                                              fontSize: 14,
                                              color: Colors.black),
                                        ),
                                      ),
                                    )
                                  else
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.black,
                                        size: 24.0,
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
      floatingActionButton: FloatBtn.build(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatBtn.bottomAppBar(context),
    );
  }
}
