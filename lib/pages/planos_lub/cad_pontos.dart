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
  final TextEditingController _tempoAtvController = TextEditingController();
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
    // await _fetchComponets('');
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
      String tempoAtv = _tempoAtvController.text;
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
        'tempo_atv': tempoAtv,
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

  Future<List<Map<String, dynamic>>> _fetchComponents(String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String cacheKey =
        'componentes_cache_${searchText.replaceAll(RegExp('[^A-Za-z0-9]'), '')}';
    var cachedData = prefs.getString(cacheKey);

    print("Cache Key: $cacheKey");
    if (cachedData != null) {
      print("Using cached data for $searchText");
      var decodedData =
          List<Map<String, dynamic>>.from(json.decode(cachedData));
      print("Decoded Data: $decodedData");
      return decodedData;
    }

    print("No cache found for $searchText. Fetching from API.");
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print("Offline mode: Fetching data from local fallback");
      return _carregarComponentesOffline(searchText);
    } else {
      print("Online mode: Fetching data from API");
      return _fetchComponentsFromApi(searchText);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchComponentsFromApi(
      String searchText) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-components'),
        body:
            json.encode({"codigo_empresa": '0001', "search_text": searchText}),
        headers: {"Content-Type": "application/json"},
      );

      print("API Response for $searchText: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'componentes_cache_$searchText', json.encode(responseData));
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        print('Falha na requisição: ${response.statusCode}');
        return _carregarComponentesOffline(
            searchText); // Fallback para dados offline
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      return _carregarComponentesOffline(
          searchText); // Fallback para erro na requisição
    }
  }

  Future<List<Map<String, dynamic>>> _carregarComponentesOffline(
      String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var allComponentsString = prefs
        .getString('componentes'); // Cache genérico de todos os componentes
    if (allComponentsString != null) {
      List<Map<String, dynamic>> allComponents =
          List<Map<String, dynamic>>.from(json.decode(allComponentsString));
      return allComponents.where((component) {
        final nomeComponente = component['descricao'] as String?;
        return nomeComponente
                ?.toLowerCase()
                .contains(searchText.toLowerCase()) ??
            false;
      }).toList();
    }
    return []; // Lista vazia se não houver dados salvos
  }

  Future<List<Map<String, dynamic>>> _fetchAtvBreve(String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Cria uma chave de cache específica para a pesquisa
    String cacheKey =
        'atividadeBreve_${searchText.replaceAll(RegExp('[^A-Za-z0-9]'), '')}';
    var cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      print("Using cached data for $searchText");
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    print("No cache found for $searchText. Checking connectivity.");
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print("Offline mode: No cached data available.");
      return _carregarAtvBreveOffline(searchText);
    } else {
      print("Online mode: Fetching data from API");
      return _fetchAtvBreveFromApi(searchText, cacheKey);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAtvBreveFromApi(
      String searchText, String cacheKey) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-atividade-breve'),
        body:
            json.encode({"codigo_empresa": '0001', "search_text": searchText}),
        headers: {"Content-Type": "application/json"},
      );

      print("API Response for $searchText: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, json.encode(responseData));
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        print('Falha na requisição: ${response.statusCode}');
        return _carregarAtvBreveOffline(
            searchText); // Fallback para dados offline
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      return _carregarAtvBreveOffline(
          searchText); // Fallback para erro na requisição
    }
  }

  Future<List<Map<String, dynamic>>> _carregarAtvBreveOffline(
      String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? atividadeBreveString = prefs.getString('atividadeBreve');

    if (atividadeBreveString != null) {
      final List<dynamic> atividadeBreveJson =
          json.decode(atividadeBreveString);
      List<Map<String, dynamic>> allActivities =
          atividadeBreveJson.cast<Map<String, dynamic>>();

      if (searchText.isNotEmpty) {
        allActivities = allActivities.where((activity) {
          // Add null safety check before calling toLowerCase
          final descricao = activity['descricao'] as String?;
          return descricao?.toLowerCase().contains(searchText.toLowerCase()) ??
              false;
        }).toList();
      }

      return allActivities;
    } else {
      return []; // Returns an empty list if there are no saved data
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMaterial(String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Cria uma chave de cache específica para a pesquisa
    String cacheKey =
        'materiais_${searchText.replaceAll(RegExp('[^A-Za-z0-9]'), '')}';
    var cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      print("Using cached data for $searchText");
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    print("No cache found for $searchText. Checking connectivity.");
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print("Offline mode: No cached data available.");
      return _carregarMateriaisOffline(searchText);
    } else {
      return _fetchMaterialFromApi(searchText, cacheKey);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMaterialFromApi(
      String searchText, String cacheKey) async {
    try {
      final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-material'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"});

      print("API Response for $searchText: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            cacheKey,
            json.encode(
                responseData)); // Salva a resposta usando a chave de cache específica
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        print('Falha na requisição: ${response.statusCode}');
        return _carregarMateriaisOffline(
            searchText); // Fallback para dados offline
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      return _carregarMateriaisOffline(
          searchText); // Fallback para erro na requisição
    }
  }

  Future<List<Map<String, dynamic>>> _carregarMateriaisOffline(
      String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? materiaisString = prefs.getString('materiais');

    if (materiaisString != null) {
      final List<dynamic> materiaisJson = json.decode(materiaisString);
      List<Map<String, dynamic>> allMaterials =
          materiaisJson.cast<Map<String, dynamic>>();

      if (searchText.isNotEmpty) {
        allMaterials = allMaterials.where((material) {
          // Add null safety check before calling toLowerCase
          final nomeMaterial = material['descricao_produto'] as String?;
          return nomeMaterial
                  ?.toLowerCase()
                  .contains(searchText.toLowerCase()) ??
              false;
        }).toList();
      }

      return allMaterials;
    } else {
      return []; // Returns an empty list if there are no saved data
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCondOp(String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Cria uma chave de cache específica para a pesquisa
    String cacheKey =
        'condOp_${searchText.replaceAll(RegExp('[^A-Za-z0-9]'), '')}';
    var cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      print("Using cached data for $searchText");
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    print("No cache found for $searchText. Checking connectivity.");
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print("Offline mode: No cached data available.");
      return _carregarCondOpOffline(searchText);
    } else {
      return _fetchCondOpFromApi(searchText, cacheKey);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCondOpFromApi(
      String searchText, String cacheKey) async {
    try {
      final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-cond-op'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"});

      print("API Response for $searchText: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            cacheKey,
            json.encode(
                responseData)); // Salva a resposta usando a chave de cache específica
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        print('Falha na requisição: ${response.statusCode}');
        return _carregarCondOpOffline(
            searchText); // Fallback para dados offline
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      return _carregarCondOpOffline(
          searchText); // Fallback para erro na requisição
    }
  }

  Future<List<Map<String, dynamic>>> _carregarCondOpOffline(
      String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? condOpString = prefs.getString('condOp');

    if (condOpString != null) {
      final List<dynamic> condOpJson = json.decode(condOpString);
      List<Map<String, dynamic>> allConditions =
          condOpJson.cast<Map<String, dynamic>>();

      if (searchText.isNotEmpty) {
        allConditions = allConditions.where((condition) {
          // Add null safety check before calling toLowerCase
          final descricao = condition['descricao'] as String?;
          return descricao?.toLowerCase().contains(searchText.toLowerCase()) ??
              false;
        }).toList();
      }

      return allConditions;
    } else {
      return []; // Returns an empty list if there are no saved data
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPeriodicidade(
      String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Create a cache key that includes the searchText to differentiate caches
    String cacheKey =
        'periodicidade_${searchText.replaceAll(RegExp('[^A-Za-z0-9]'), '')}';
    var cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      print("Using cached data for $searchText");
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    print("No cache found for $searchText. Checking connectivity.");
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print("Offline mode: No cached data available.");
      return _carregarPeriodicidadeOffline(searchText);
    } else {
      return _fetchPeriodicidadeFromApi(searchText, cacheKey);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPeriodicidadeFromApi(
      String searchText, String cacheKey) async {
    try {
      final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-frequencia'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"});

      print("API Response for $searchText: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            cacheKey,
            json.encode(
                responseData)); // Save the response in SharedPreferences under the specific cache key
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        print('Failed request: ${response.statusCode}');
        return _carregarPeriodicidadeOffline(
            searchText); // Fallback to offline data
      }
    } catch (e) {
      print('Error making the request: $e');
      return _carregarPeriodicidadeOffline(
          searchText); // Fallback to offline data on error
    }
  }

  Future<List<Map<String, dynamic>>> _carregarPeriodicidadeOffline(
      String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? periodicidadeString = prefs.getString('periodicidade');

    if (periodicidadeString != null) {
      final List<dynamic> periodicidadeJson = json.decode(periodicidadeString);
      List<Map<String, dynamic>> allPeriodicity =
          periodicidadeJson.cast<Map<String, dynamic>>();

      if (searchText.isNotEmpty) {
        allPeriodicity = allPeriodicity.where((periodicity) {
          // Add null safety check before calling toLowerCase
          final descricao = periodicity['descricao'] as String?;
          return descricao?.toLowerCase().contains(searchText.toLowerCase()) ??
              false;
        }).toList();
      }

      return allPeriodicity;
    } else {
      return []; // Returns an empty list if there are no saved data
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
                    // Aqui faz a chamada ao método que possivelmente utiliza cache
                    final suggestions = await _fetchComponents(pattern);
                    return suggestions;
                  },
                  onSuggestionSelected: (suggestion) {
                    setState(() {
                      _componentController.text = suggestion['codigo'];
                      _componentCodeController.text = suggestion['descricao'];
                    });
                  },
                  itemBuilder: (context, Map<String, dynamic> suggestion) {
                    // Renderiza a sugestão aqui
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
                )),
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
                controller: _tempoAtvController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Tempo da atividade: ',
                ),
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
