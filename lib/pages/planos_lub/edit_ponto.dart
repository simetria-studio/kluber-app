import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:kluber/class/api_config.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/arvore.dart';
import 'package:kluber/pages/planos_lub/ponto_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPonto extends StatefulWidget {
  final int pontoId;
  const EditPonto({super.key, required this.pontoId});

  @override
  State<EditPonto> createState() => _EditPontoState();
}

class _EditPontoState extends State<EditPonto> {
  bool userDataLoaded = false;
  Map<String, dynamic>? _selectedPeriodicidade;
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
  List<Map<String, dynamic>> _periodicidadeList = [];

  void carregarDadosPonto() async {
    var ponto = await _databaseHelper.getPontoById(widget.pontoId);
    print('dados carregados');
    if (ponto != null) {
      setState(() {
        _componentController.text = ponto['component_name'];
        _componentCodeController.text = ponto['component_codigo'];
        _qtyPontosController.text = ponto['qty_pontos'];
        _atvBreveController.text = ponto['atv_breve_name'];
        _atvBreveCodeController.text = ponto['atv_breve_codigo'];
        _materialController.text = ponto['lub_name'];
        _materialCodeController.text = ponto['lub_codigo'];
        _qtyMaterialController.text = ponto['qty_material'];
        _condOpController.text = ponto['cond_op_name'];
        _condOpCodeController.text = ponto['cond_op_codigo'];
        _periodicidadeController.text = ponto['period_name'];
        _periodicidadeCodeController.text = ponto['period_codigo'];
        _qtyPessoasController.text = ponto['qty_pessoas'];
        _tempoAtvController.text = ponto['tempo_atv'];
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchComponents(String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String cacheKey =
        'componentes_cache_${searchText.replaceAll(RegExp('[^A-Za-z0-9]'), '')}';
    var cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      var decodedData =
          List<Map<String, dynamic>>.from(json.decode(cachedData));

      return decodedData;
    }

    print("No cache found for $searchText. Fetching from API.");
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return _carregarComponentesOffline(searchText);
    } else {
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
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return _carregarAtvBreveOffline(searchText);
    } else {
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

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, json.encode(responseData));
        return List<Map<String, dynamic>>.from(responseData);
      } else {
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
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
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

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            cacheKey,
            json.encode(
                responseData)); // Salva a resposta usando a chave de cache específica
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        return _carregarMateriaisOffline(
            searchText); // Fallback para dados offline
      }
    } catch (e) {
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
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
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

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            cacheKey,
            json.encode(
                responseData)); // Salva a resposta usando a chave de cache específica
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        return _carregarCondOpOffline(
            searchText); // Fallback para dados offline
      }
    } catch (e) {
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

  Future<void> _loadPeriodicidade() async {
    List<Map<String, dynamic>> periodicidadeList =
        await _fetchPeriodicidade('');
    setState(() {
      _periodicidadeList = periodicidadeList;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPeriodicidade(
      String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String cacheKey =
        'periodicidade_${searchText.replaceAll(RegExp('[^A-Za-z0-9]'), '')}';
    var cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
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
        body:
            json.encode({"codigo_empresa": '0001', "search_text": searchText}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, json.encode(responseData));
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        return _carregarPeriodicidadeOffline(searchText);
      }
    } catch (e) {
      return _carregarPeriodicidadeOffline(searchText);
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
          final descricao = periodicity['descricao'] as String?;
          return descricao?.toLowerCase().contains(searchText.toLowerCase()) ??
              false;
        }).toList();
      }

      return allPeriodicity;
    } else {
      return [];
    }
  }

  Future<void> initializeData() async {
    setState(() {
      userDataLoaded = true;
    });
    await _fetchComponents('');
    await _fetchAtvBreve('');
    await _fetchMaterial('');
    await _fetchCondOp('');
    await _fetchPeriodicidade('');
  }

  @override
  void initState() {
    super.initState();
    carregarDadosPonto();
    initializeData();
  }

  salvarDados() {
    Map<String, dynamic> ponto = {
      'component_name': _componentController.text,
      'component_codigo': _componentCodeController.text,
      'qty_pontos': _qtyPontosController.text,
      'atv_breve_name': _atvBreveController.text,
      'atv_breve_codigo': _atvBreveCodeController.text,
      'lub_name': _materialController.text,
      'lub_codigo': _materialCodeController.text,
      'qty_material': _qtyMaterialController.text,
      'cond_op_name': _condOpController.text,
      'cond_op_codigo': _condOpCodeController.text,
      'period_name': _periodicidadeController.text,
      'period_codigo': _periodicidadeCodeController.text,
      'qty_pessoas': _qtyPessoasController.text,
      'tempo_atv': _tempoAtvController.text,
    };

    if (widget.pontoId != 0) {
      ponto['id'] = widget.pontoId;
      _databaseHelper.updatePonto(ponto);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Editado com sucesso!'),
          duration: Duration(
              seconds: 2), // Defina a duração desejada para exibir a mensagem
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PontoDetail(id: widget.pontoId),
        ),
      );
    } else {
      _databaseHelper.insertPontos(ponto);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PontoDetail(id: widget.pontoId),
        ),
      );
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
              child: DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedPeriodicidade,
                onChanged: userDataLoaded
                    ? (Map<String, dynamic>? newValue) {
                        setState(() {
                          _selectedPeriodicidade = newValue;
                          _periodicidadeController.text =
                              newValue?['descricao'] ?? '';
                          _periodicidadeCodeController.text =
                              newValue?['codigo'] ?? '';
                        });
                      }
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Periodicidade:',
                  border: OutlineInputBorder(),
                ),
                items: _periodicidadeList
                    .map<DropdownMenuItem<Map<String, dynamic>>>(
                        (Map<String, dynamic> value) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: value,
                    child: ListTile(
                      title: Text(value['descricao'] ?? ''),
                      subtitle: Row(
                        children: [
                          Text(value['codigo'] ?? ''),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
                        int ponto = await salvarDados();
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
