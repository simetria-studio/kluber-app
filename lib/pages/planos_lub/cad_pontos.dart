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
  final int idArea;

  const CadPontos(
      {super.key,
      required this.conjuntoId,
      required this.idPlano,
      required this.idArea});

  @override
  State<CadPontos> createState() => _CadPontosState();
}

class _CadPontosState extends State<CadPontos> {
  bool userDataLoaded = false;
  bool _isComponentSelected = false;
  bool _isAtvBreveSelected = false;
  bool _isMaterialSelected = false;
  bool _isCondOpSelected = false;
  bool _isPeriodicidadeSelected = false;
  Map<String, dynamic>? _selectedPeriodicidade;
  Map<String, dynamic>? _selectedAtvBreve;
  Map<String, dynamic>? _selectedCondOp;

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
  late List<Map<String, dynamic>> _clientes;
  List<Map<String, dynamic>> _periodicidadeList = [];
  List<Map<String, dynamic>> _atvBreveList = [];
  List<Map<String, dynamic>> _condOpList = [];
  String cliente = '';
  String dataCadastro = '';
  String dataRevisao = '';
  String responsavelLubrificacao = '';
  String responsavelKluber = '';
  int id = 0;
  final databaseHelper = DatabaseHelper();

  Future<Map<String, dynamic>> _carregarDadosDoPlano() async {
    var plano = await _databaseHelper.getPlanoLubById(widget.idPlano);
    if (plano != null) {
      return plano;
    } else {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    initializeData();
    _componentController.addListener(() {
      if (_componentController.text != _componentCodeController.text) {
        setState(() {
          _isComponentSelected = false;
        });
      }
    });
    _materialController.addListener(() {
      if (_materialController.text != _materialCodeController.text) {
        setState(() {
          _isMaterialSelected = false;
        });
      }
    });

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
    await _fetchPeriodicidade();
    await _fetchAtvBreve();
    await _fetchCondOp();
    setState(() {
      userDataLoaded = true;
    });
  }

  Future<void> _fetchPeriodicidade() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      await _loadPeriodicidadeFromPrefs();
    } else {
      await _fetchPeriodicidadeFromApi();
    }
  }

  Future<void> _fetchAtvBreve() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      await _loadAtvBreveFromPrefs();
    } else {
      await _fetchAtvBreveFromApi();
    }
  }

  Future<void> _fetchCondOp() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      await _loadCondOpFromPrefs();
    } else {
      await _fetchCondOpFromApi();
    }
  }

  Future<void> _fetchPeriodicidadeFromApi() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-frequencia'),
          body: json.encode({"codigo_empresa": '0001'}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'periodicidade_cache', json.encode(responseData));
          setState(() {
            _periodicidadeList = List<Map<String, dynamic>>.from(responseData);
          });
        } else {
          print('Falha na requisição: ${response.statusCode}');
        }
      } else {
        await _loadPeriodicidadeFromPrefs();
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      await _loadPeriodicidadeFromPrefs();
    }
  }

  Future<void> _fetchAtvBreveFromApi() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-atividade-breve'),
          body: json.encode({"codigo_empresa": '0001'}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('atvBreve_cache', json.encode(responseData));
          setState(() {
            _atvBreveList = List<Map<String, dynamic>>.from(responseData);
          });
        } else {
          print('Falha na requisição: ${response.statusCode}');
        }
      } else {
        await _loadAtvBreveFromPrefs();
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      await _loadAtvBreveFromPrefs();
    }
  }

  Future<void> _fetchCondOpFromApi() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-cond-op'),
          body: json.encode({"codigo_empresa": '0001'}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('condOp_cache', json.encode(responseData));
          setState(() {
            _condOpList = List<Map<String, dynamic>>.from(responseData);
          });
        } else {
          print('Falha na requisição: ${response.statusCode}');
        }
      } else {
        await _loadCondOpFromPrefs();
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      await _loadCondOpFromPrefs();
    }
  }

  Future<void> _loadPeriodicidadeFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var cachedData = prefs.getString('periodicidade_cache');

    if (cachedData != null) {
      setState(() {
        _periodicidadeList =
            List<Map<String, dynamic>>.from(json.decode(cachedData));
      });
    } else {
      print('Nenhum dado em cache encontrado');
    }
  }

  Future<void> _loadAtvBreveFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var cachedData = prefs.getString('atvBreve_cache');

    if (cachedData != null) {
      setState(() {
        _atvBreveList =
            List<Map<String, dynamic>>.from(json.decode(cachedData));
      });
    } else {
      print('Nenhum dado em cache encontrado');
    }
  }

  Future<void> _loadCondOpFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var cachedData = prefs.getString('condOp_cache');

    if (cachedData != null) {
      setState(() {
        _condOpList = List<Map<String, dynamic>>.from(json.decode(cachedData));
      });
    } else {
      print('Nenhum dado em cache encontrado');
    }
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

      int id = await _databaseHelper.insertPontos(subAreaCad);
      return id;
    } catch (e) {
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchData(String endpoint,
      String searchText, String cacheKey, String offlineKey) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return _fetchOfflineData(searchText, offlineKey);
    } else {
      return _fetchDataFromApi(endpoint, searchText, cacheKey, offlineKey);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDataFromApi(String endpoint,
      String searchText, String cacheKey, String offlineKey) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult != ConnectivityResult.none) {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/$endpoint'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, json.encode(responseData));
          return List<Map<String, dynamic>>.from(responseData);
        } else {
          print('Falha na requisição: ${response.statusCode}');
          return _fetchOfflineData(searchText, offlineKey);
        }
      } else {
        return _fetchOfflineData(searchText, offlineKey);
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      return _fetchOfflineData(searchText, offlineKey);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOfflineData(
      String searchText, String offlineKey) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString(offlineKey);

    if (dataString != null) {
      final List<dynamic> dataJson = json.decode(dataString);
      return List<Map<String, dynamic>>.from(dataJson).where((item) {
        final descricao = item['descricao'] as String?;
        return descricao?.toLowerCase().contains(searchText.toLowerCase()) ??
            false;
      }).toList();
    } else {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchComponents(String searchText) async {
    return _fetchData('get-components', searchText,
        'componentes_cache_$searchText', 'componentes');
  }

  Future<List<Map<String, dynamic>>> _fetchMaterial(String searchText) async {
    return _fetchData(
        'get-material', searchText, 'materiais_cache_$searchText', 'materiais');
  }

  // Future<List<Map<String, dynamic>>> _fetchCondOp(String searchText) async {
  //   return _fetchData(
  //       'get-cond-op', searchText, 'condOp_cache_$searchText', 'condOp');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'PLANO #$id'.toUpperCase(),
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
          child: Column(
            children: [
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
                  suggestionsCallback: _fetchComponents,
                  onSuggestionSelected: (suggestion) {
                    setState(() {
                      _componentController.text = suggestion['descricao'];
                      _componentCodeController.text = suggestion['codigo'];
                      _isComponentSelected = true;
                    });
                  },
                  itemBuilder: (context, Map<String, dynamic> suggestion) {
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
                child: DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedAtvBreve,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedAtvBreve = newValue;
                      _atvBreveController.text = newValue!['descricao'];
                      _atvBreveCodeController.text = newValue['codigo'];
                      _isAtvBreveSelected = true;
                    });
                  },
                  items: _atvBreveList.map((suggestion) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: suggestion,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 300,
                            child: Text(
                              suggestion['descricao'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Atividade Breve:',
                    border: OutlineInputBorder(),
                  ),
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
                  suggestionsCallback: _fetchMaterial,
                  onSuggestionSelected: (suggestion) {
                    setState(() {
                      _materialController.text =
                          suggestion['descricao_produto'];
                      _materialCodeController.text =
                          suggestion['codigo_produto'];
                      _isMaterialSelected = true;
                    });
                  },
                  itemBuilder: (context, Map<String, dynamic> suggestion) {
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
                child: DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedCondOp,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCondOp = newValue;
                      _condOpController.text = newValue!['descricao'];
                      _condOpCodeController.text = newValue['codigo'];
                      _isCondOpSelected = true;
                    });
                  },
                  items: _condOpList.map((suggestion) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: suggestion,
                      child: Row(
                        children: [
                          Text(
                            suggestion['descricao'] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Condição de operação:',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedPeriodicidade,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedPeriodicidade = newValue;
                      _periodicidadeController.text = newValue!['descricao'];
                      _periodicidadeCodeController.text = newValue['codigo'];
                      _isPeriodicidadeSelected = true;
                    });
                  },
                  items: _periodicidadeList.map((suggestion) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: suggestion,
                      child: Row(
                        children: [
                          Text(suggestion['descricao'] ?? ''),
                          const SizedBox(width: 10),
                          Text(suggestion['codigo'] ?? ''),
                        ],
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Periodicidade:',
                    border: OutlineInputBorder(),
                  ),
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
                          if (!_isComponentSelected ||
                              !_isAtvBreveSelected ||
                              !_isMaterialSelected ||
                              !_isCondOpSelected ||
                              !_isPeriodicidadeSelected) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Erro"),
                                content: const Text(
                                    "Por favor, selecione todos os valores."),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            int idPlano = await salvarDados();
                            if (idPlano != -1) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Arvore(
                                      idPlano: widget.idPlano,
                                      idArea: widget.idArea),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
