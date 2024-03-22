import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:kluber/class/api_config.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/db/database.dart';
import 'package:http/http.dart' as http;
import 'package:kluber/pages/planos_lub/arvore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CadPontos extends StatefulWidget {
  final int conjuntoId;
  final int idPlano;
  const CadPontos({super.key, required this.conjuntoId, required this.idPlano});

  @override
  State<CadPontos> createState() => _CadPontosState();
}

class _CadPontosState extends State<CadPontos> {
  bool userDataLoaded = false;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _componentController = TextEditingController();
  final TextEditingController _componentCodeController =
      TextEditingController();
  final TextEditingController _qtyPontosController = TextEditingController();
  final TextEditingController _atvBreveController = TextEditingController();
  final TextEditingController _atvBreveCodeController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _materialCodeController = TextEditingController();
  final TextEditingController _qtyMaterialController = TextEditingController();
  final TextEditingController _condOpController = TextEditingController();
  final TextEditingController _condOpCodeController = TextEditingController();
  final TextEditingController _periodicidadeController =
      TextEditingController();
  final TextEditingController _periodicidadeCodeController =
      TextEditingController();
  final TextEditingController _qtyPessoasController = TextEditingController();
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
    var plano = await _databaseHelper.getPlanoLubById(widget.idPlano);
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
    initializeData();
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

  Future<void> initializeData() async {
    setState(() {
      userDataLoaded = true;
    });
    await _fetchComponets('');
    await _fetchAtvBreve('');
    await _fetchMaterial('');
    await _fetchCondOp('');
    await _fetchPeriodicidade('');
  }

  Future<int> salvarDados() async {
    try {
      String componentName = _componentController.text;
      String componentCodigo = _componentCodeController.text;
      String qtyPontos = _qtyPontosController.text;
      String atvBreveName = _atvBreveController.text;
      String atvBreveCodigo = _atvBreveCodeController.text;
      String lubName = _materialController.text;
      String lubCodigo = _materialCodeController.text;
      String qtyMaterial = _qtyMaterialController.text;
      String condOpName = _condOpController.text;
      String condOpCodigo = _condOpCodeController.text;
      String periodName = _periodicidadeController.text;
      String periodCodigo = _periodicidadeCodeController.text;
      String qtyPessoas = _qtyPessoasController.text;
      int conjuntoEquipId = widget.conjuntoId;

      // Organiza os dados em um mapa
      Map<String, dynamic> subAreaCad = {
        'component_name': componentName,
        'component_codigo': componentCodigo,
        'qty_pontos': qtyPontos,
        'atv_breve_name': atvBreveName,
        'atv_breve_codigo': atvBreveCodigo,
        'lub_name': lubName,
        'lub_codigo': lubCodigo,
        'qty_material': qtyMaterial,
        'cond_op_name': condOpName,
        'cond_op_codigo': condOpCodigo,
        'period_name': periodName,
        'period_codigo': periodCodigo,
        'qty_pessoas': qtyPessoas,
        'conjunto_equip_id': conjuntoEquipId,
        'plano_id': widget.idPlano,
      };

      // Insere os dados na base de dados e retorna o ID do plano inserido
      int id = await _databaseHelper.insertPontos(subAreaCad);
      return id;
    } catch (e) {
      return -1; // Retorna -1 em caso de falha
    }
  }

  Future<List<Map<String, dynamic>>> _fetchComponets(String searchText) async {
    // Checando a conectividade primeiro
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Se estiver offline, tente carregar os dados salvos
      return _carregarComponentesOffline();
    } else {
      // Se estiver online, faça a requisição HTTP
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-components'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          // Salva os componentes no SharedPreferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('componentes', json.encode(responseData));

          return List<Map<String, dynamic>>.from(responseData);
        } else {
          print('Falha na requisição: ${response.statusCode}');
          return _carregarComponentesOffline(); // Fallback para dados offline
        }
      } catch (e) {
        print('Erro ao fazer a requisição: $e');
        return _carregarComponentesOffline(); // Fallback para erro na requisição
      }
    }
  }

  Future<List<Map<String, dynamic>>> _carregarComponentesOffline() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? componentesString = prefs.getString('componentes');

    if (componentesString != null) {
      final List<dynamic> componentesJson = json.decode(componentesString);
      return componentesJson.cast<Map<String, dynamic>>();
    } else {
      return []; // Lista vazia se não houver dados salvos
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAtvBreve(String searchText) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Carrega dados offline
      return _carregarAtvBreveOffline();
    } else {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-atividade-breve'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          // Salva a resposta no SharedPreferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('atividadeBreve', json.encode(responseData));

          return List<Map<String, dynamic>>.from(responseData);
        } else {
          print('Falha na requisição: ${response.statusCode}');
          return _carregarAtvBreveOffline(); // Fallback para dados offline
        }
      } catch (e) {
        print('Erro ao fazer a requisição: $e');
        return _carregarAtvBreveOffline(); // Fallback para erro na requisição
      }
    }
  }

  Future<List<Map<String, dynamic>>> _carregarAtvBreveOffline() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? atividadeBreveString = prefs.getString('atividadeBreve');

    if (atividadeBreveString != null) {
      final List<dynamic> atividadeBreveJson =
          json.decode(atividadeBreveString);
      return atividadeBreveJson.cast<Map<String, dynamic>>();
    } else {
      return []; // Lista vazia se não houver dados salvos
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMaterial(String searchText) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Carrega dados offline
      return _carregarMateriaisOffline();
    } else {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-material'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          // Salva a resposta no SharedPreferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('materiais', json.encode(responseData));

          return List<Map<String, dynamic>>.from(responseData);
        } else {
          print('Falha na requisição: ${response.statusCode}');
          return _carregarMateriaisOffline(); // Fallback para dados offline
        }
      } catch (e) {
        print('Erro ao fazer a requisição: $e');
        return _carregarMateriaisOffline(); // Fallback para erro na requisição
      }
    }
  }

  Future<List<Map<String, dynamic>>> _carregarMateriaisOffline() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? materiaisString = prefs.getString('materiais');

    if (materiaisString != null) {
      final List<dynamic> materiaisJson = json.decode(materiaisString);
      return materiaisJson.cast<Map<String, dynamic>>();
    } else {
      return []; // Retorna uma lista vazia se não houver dados salvos
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCondOp(String searchText) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Carrega dados offline
      return _carregarCondOpOffline();
    } else {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-cond-op'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          // Salva a resposta no SharedPreferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('condOp', json.encode(responseData));

          return List<Map<String, dynamic>>.from(responseData);
        } else {
          print('Falha na requisição: ${response.statusCode}');
          return _carregarCondOpOffline(); // Fallback para dados offline
        }
      } catch (e) {
        print('Erro ao fazer a requisição: $e');
        return _carregarCondOpOffline(); // Fallback para erro na requisição
      }
    }
  }

  Future<List<Map<String, dynamic>>> _carregarCondOpOffline() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? condOpString = prefs.getString('condOp');

    if (condOpString != null) {
      final List<dynamic> condOpJson = json.decode(condOpString);
      return condOpJson.cast<Map<String, dynamic>>();
    } else {
      return []; // Retorna uma lista vazia se não houver dados salvos
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPeriodicidade(
      String searchText) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Carrega dados offline
      return _carregarPeriodicidadeOffline();
    } else {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-frequencia'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          // Salva a resposta no SharedPreferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('periodicidade', json.encode(responseData));

          return List<Map<String, dynamic>>.from(responseData);
        } else {
          print('Falha na requisição: ${response.statusCode}');
          return _carregarPeriodicidadeOffline(); // Fallback para dados offline
        }
      } catch (e) {
        print('Erro ao fazer a requisição: $e');
        return _carregarPeriodicidadeOffline(); // Fallback para erro na requisição
      }
    }
  }

  Future<List<Map<String, dynamic>>> _carregarPeriodicidadeOffline() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? periodicidadeString = prefs.getString('periodicidade');

    if (periodicidadeString != null) {
      final List<dynamic> periodicidadeJson = json.decode(periodicidadeString);
      return periodicidadeJson.cast<Map<String, dynamic>>();
    } else {
      return []; // Retorna uma lista vazia se não houver dados salvos
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
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TypeAheadField<Map<String, dynamic>>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _componentController,
                  enabled: userDataLoaded,
                  decoration: const InputDecoration(
                    labelText: 'Componente:',
                    border: OutlineInputBorder(),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  final suggestions = await _fetchComponets(
                      pattern); // Faz a chamada à API com o texto de pesquisa
                  return suggestions;
                },
                onSuggestionSelected: (suggestion) {
                  setState(() {
                    _componentController.text = suggestion['codigo'];
                    _componentCodeController.text = suggestion['descricao'];
                  });
                },
                itemBuilder: (context, Map<String, dynamic> suggestion) {
                  // Renderize a sugestão aqui
                  return ListTile(
                    title: Text(suggestion['descricao'] ?? ''),
                    subtitle: Row(
                      children: [
                        Text(suggestion['codigo'] ?? ''),
                        const SizedBox(width: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _qtyPontosController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Quantidade de pontos: ',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TypeAheadField<Map<String, dynamic>>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _atvBreveController,
                  enabled: userDataLoaded,
                  decoration: const InputDecoration(
                    labelText: 'Atividade Breve:',
                    border: OutlineInputBorder(),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  final suggestions = await _fetchAtvBreve(
                      pattern); // Faz a chamada à API com o texto de pesquisa
                  return suggestions;
                },
                onSuggestionSelected: (suggestion) {
                  setState(() {
                    _atvBreveController.text = suggestion['descricao'];
                    _atvBreveCodeController.text = suggestion['codigo'];
                  });
                },
                itemBuilder: (context, Map<String, dynamic> suggestion) {
                  // Renderize a sugestão aqui
                  return ListTile(
                    title: Text(suggestion['descricao'] ?? ''),
                    subtitle: Row(
                      children: [
                        Text(suggestion['codigo'] ?? ''),
                        const SizedBox(width: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TypeAheadField<Map<String, dynamic>>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _materialController,
                  enabled: userDataLoaded,
                  decoration: const InputDecoration(
                    labelText: 'Nome do lubrificante (material):',
                    border: OutlineInputBorder(),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  final suggestions = await _fetchMaterial(
                      pattern); // Faz a chamada à API com o texto de pesquisa
                  return suggestions;
                },
                onSuggestionSelected: (suggestion) {
                  setState(() {
                    _materialController.text = suggestion['descricao_produto'];
                    _materialCodeController.text = suggestion['codigo_produto'];
                  });
                },
                itemBuilder: (context, Map<String, dynamic> suggestion) {
                  // Renderize a sugestão aqui
                  return ListTile(
                    title: Text(suggestion['descricao_produto'] ?? ''),
                    subtitle: Row(
                      children: [
                        Text(suggestion['codigo_produto'] ?? ''),
                        const SizedBox(width: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _qtyMaterialController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Quantidade de material: ',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TypeAheadField<Map<String, dynamic>>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _condOpController,
                  enabled: userDataLoaded,
                  decoration: const InputDecoration(
                    labelText: 'Condição de operação:',
                    border: OutlineInputBorder(),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  final suggestions = await _fetchCondOp(
                      pattern); // Faz a chamada à API com o texto de pesquisa
                  return suggestions;
                },
                onSuggestionSelected: (suggestion) {
                  setState(() {
                    _condOpController.text = suggestion['descricao'];
                    _condOpCodeController.text = suggestion['codigo'];
                  });
                },
                itemBuilder: (context, Map<String, dynamic> suggestion) {
                  // Renderize a sugestão aqui
                  return ListTile(
                    title: Text(suggestion['descricao'] ?? ''),
                    subtitle: Row(
                      children: [
                        Text(suggestion['codigo'] ?? ''),
                        const SizedBox(width: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TypeAheadField<Map<String, dynamic>>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _periodicidadeController,
                  enabled: userDataLoaded,
                  decoration: const InputDecoration(
                    labelText: 'Periodicidade:',
                    border: OutlineInputBorder(),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  final suggestions = await _fetchPeriodicidade(
                      pattern); // Faz a chamada à API com o texto de pesquisa
                  return suggestions;
                },
                onSuggestionSelected: (suggestion) {
                  setState(() {
                    _periodicidadeController.text = suggestion['descricao'];
                    _periodicidadeCodeController.text = suggestion['codigo'];
                  });
                },
                itemBuilder: (context, Map<String, dynamic> suggestion) {
                  // Renderize a sugestão aqui
                  return ListTile(
                    title: Text(suggestion['descricao'] ?? ''),
                    subtitle: Row(
                      children: [
                        Text(suggestion['codigo'] ?? ''),
                        const SizedBox(width: 10),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _qtyPessoasController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Quantidade de pessoas: ',
                ),
              ),
            ),
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
                      onPressed: () {
                         Navigator.of(context).pop();
                      },
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
                        int idPlano = await salvarDados();
                        if (idPlano != -1) {
                          print(id);
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
            )
          ]),
        ),
      ),
    );
  }
}
