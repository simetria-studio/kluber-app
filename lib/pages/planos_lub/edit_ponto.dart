import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:kluber/class/api_config.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/db/database.dart';
import 'package:http/http.dart' as http;
import 'package:kluber/pages/planos_lub/ponto_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPonto extends StatefulWidget {
  final int pontoId;
  final int planoId;
  const EditPonto({super.key, required this.pontoId, required this.planoId});

  @override
  State<EditPonto> createState() => _EditPontoState();
}

class _EditPontoState extends State<EditPonto> {
  bool userDataLoaded = false;
  bool _isComponentSelected = false;
  bool _isAtvBreveSelected = false;
  bool _isMaterialSelected = false;
  bool _isCondOpSelected = false;
  bool _isPeriodicidadeSelected = false;
  bool _isUnidadeMedidaSelected = false;
  Map<String, dynamic>? _selectedPeriodicidade = {};
  Map<String, dynamic>? _selectedAtvBreve = {};
  Map<String, dynamic>? _selectedCondOp = {};
  Map<String, dynamic>? _selectedUnidadeMedida = {};

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
  final TextEditingController _unidadeMedidaController =
      TextEditingController();
  final TextEditingController _unidadeMedidaCodeController =
      TextEditingController();
  late List<Map<String, dynamic>> _clientes;
  List<Map<String, dynamic>> _periodicidadeList = [];
  List<Map<String, dynamic>> _atvBreveList = [];
  List<Map<String, dynamic>> _condOpList = [];
  List<Map<String, dynamic>> _unidadeMedidaList = [];
  String cliente = '';
  String dataCadastro = '';
  String dataRevisao = '';
  String responsavelLubrificacao = '';
  String responsavelKluber = '';
  int id = 0;
  final databaseHelper = DatabaseHelper();

  late Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _initializeFuture = initializeData();
  }

  Future<void> initializeData() async {
    try {
      await _fetchPeriodicidade();
      await _fetchAtvBreve();
      await _fetchCondOp();
      await _fetchUnidadeMedida();
      await carregarDadosPonto();
      setState(() {
        userDataLoaded = true;
      });
      print("Data loaded successfully");
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  Future<void> carregarDadosPonto() async {
    var ponto = await _databaseHelper.getPontoById(widget.pontoId);
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

        _selectedAtvBreve = _atvBreveList.firstWhere(
          (element) => element['codigo'] == ponto['atv_breve_codigo'],
          orElse: () => <String, dynamic>{},
        );
        _selectedCondOp = _condOpList.firstWhere(
          (element) => element['codigo'] == ponto['cond_op_codigo'],
          orElse: () => <String, dynamic>{},
        );
        _selectedPeriodicidade = _periodicidadeList.firstWhere(
          (element) => element['codigo'] == ponto['period_codigo'],
          orElse: () => <String, dynamic>{},
        );
        _selectedUnidadeMedida = _unidadeMedidaList.firstWhere(
          (element) =>
              element['codigo_unidade_medida'] ==
              ponto['unidade_medida_codigo'],
          orElse: () => <String, dynamic>{},
        );
      });
    }
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

  Future<void> _fetchUnidadeMedida() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      await _loadUnidadeMedidaFromPrefs();
    } else {
      await _fetchUnidadeMedidaFromApi();
    }
  }

  Future<void> _fetchPeriodicidadeFromApi() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-frequencia'),
        body: json.encode({"codigo_empresa": '0001'}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('periodicidade_cache', json.encode(responseData));
        setState(() {
          _periodicidadeList = List<Map<String, dynamic>>.from(responseData);
        });
        print("Periodicidade fetched from API");
      } else {
        await _loadPeriodicidadeFromPrefs();
      }
    } catch (e) {
      await _loadPeriodicidadeFromPrefs();
    }
  }

  Future<void> _fetchAtvBreveFromApi() async {
    try {
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
        print("AtvBreve fetched from API");
      } else {
        await _loadAtvBreveFromPrefs();
      }
    } catch (e) {
      await _loadAtvBreveFromPrefs();
    }
  }

  Future<void> _fetchCondOpFromApi() async {
    try {
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
        print("CondOp fetched from API");
      } else {
        await _loadCondOpFromPrefs();
      }
    } catch (e) {
      await _loadCondOpFromPrefs();
    }
  }

  Future<void> _fetchUnidadeMedidaFromApi() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-unidade-med'),
        body: json.encode({"codigo_empresa": '0001'}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('unidade_cache', json.encode(responseData));
        setState(() {
          _unidadeMedidaList = List<Map<String, dynamic>>.from(responseData);
        });
        print("UnidadeMedida fetched from API");
      } else {
        await _loadUnidadeMedidaFromPrefs();
      }
    } catch (e) {
      await _loadUnidadeMedidaFromPrefs();
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
      print("Periodicidade loaded from cache");
    }
  }

  Future<void> _loadUnidadeMedidaFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var cachedData = prefs.getString('unidade_cache');

    if (cachedData != null) {
      setState(() {
        _unidadeMedidaList =
            List<Map<String, dynamic>>.from(json.decode(cachedData));
      });
      print("UnidadeMedida loaded from cache");
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
      print("AtvBreve loaded from cache");
    }
  }

  Future<void> _loadCondOpFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var cachedData = prefs.getString('condOp_cache');

    if (cachedData != null) {
      setState(() {
        _condOpList = List<Map<String, dynamic>>.from(json.decode(cachedData));
      });
      print("CondOp loaded from cache");
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
      String unidadeMedidaName = _unidadeMedidaController.text;
      String unidadeMedidaCodigo = _unidadeMedidaCodeController.text;

      Map<String, dynamic> ponto = {
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
        'unidade_medida_name': unidadeMedidaName,
        'unidade_medida_codigo': unidadeMedidaCodigo,
        'plano_id': widget.planoId,
      };

      if (widget.pontoId != 0) {
        ponto['id'] = widget.pontoId;
        await _databaseHelper.updatePonto(ponto);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Editado com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PontoDetail(id: widget.pontoId, planoId: widget.planoId),
          ),
        );
      } else {
        await _databaseHelper.insertPontos(ponto);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PontoDetail(id: widget.pontoId, planoId: widget.planoId),
          ),
        );
      }
      return widget.pontoId;
    } catch (e) {
      print("Error saving data: $e");
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
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/$endpoint'),
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
        return _fetchOfflineData(searchText, offlineKey);
      }
    } catch (e) {
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

  void _ensureUniqueValues(List<Map<String, dynamic>> list) {
    final uniqueSet = <Map<String, dynamic>>{};
    list.retainWhere((element) => uniqueSet.add(element));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'PLANO #${widget.planoId}'.toUpperCase(),
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
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Erro ao carregar dados: ${snapshot.error}'));
          } else {
            return _buildForm();
          }
        },
      ),
    );
  }

  Widget _buildForm() {
    _ensureUniqueValues(_periodicidadeList);
    _ensureUniqueValues(_atvBreveList);
    _ensureUniqueValues(_condOpList);
    _ensureUniqueValues(_unidadeMedidaList);

    return SingleChildScrollView(
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
                value:
                    _selectedAtvBreve != null && _selectedAtvBreve!.isNotEmpty
                        ? _selectedAtvBreve
                        : null,
                onChanged: (newValue) {
                  setState(() {
                    _selectedAtvBreve = newValue!;
                    _atvBreveController.text = newValue['descricao'];
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
                    _materialController.text = suggestion['descricao_produto'];
                    _materialCodeController.text = suggestion['codigo_produto'];
                    _isMaterialSelected = true;

                    _selectedUnidadeMedida = _unidadeMedidaList.firstWhere(
                      (element) =>
                          element['descricao_unidade_medida'] ==
                          suggestion['unidade_medida'],
                      orElse: () => {
                        'descricao_unidade_medida':
                            suggestion['unidade_medida'],
                        'codigo_unidade_medida': ''
                      },
                    );

                    if (!_unidadeMedidaList.contains(_selectedUnidadeMedida)) {
                      _unidadeMedidaList.add(_selectedUnidadeMedida!);
                    }
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
                value: _selectedCondOp != null && _selectedCondOp!.isNotEmpty
                    ? _selectedCondOp
                    : null,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCondOp = newValue!;
                    _condOpController.text = newValue['descricao'];
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
                value: _selectedPeriodicidade != null &&
                        _selectedPeriodicidade!.isNotEmpty
                    ? _selectedPeriodicidade
                    : null,
                onChanged: (newValue) {
                  setState(() {
                    _selectedPeriodicidade = newValue!;
                    _periodicidadeController.text = newValue['descricao'];
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
              child: DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedUnidadeMedida != null &&
                        _selectedUnidadeMedida!.isNotEmpty
                    ? _selectedUnidadeMedida
                    : null,
                onChanged: (newValue) {
                  setState(() {
                    _selectedUnidadeMedida = newValue!;
                    _unidadeMedidaController.text =
                        newValue['descricao_unidade_medida'];
                    _unidadeMedidaCodeController.text =
                        newValue['codigo_unidade_medida'];
                    _isUnidadeMedidaSelected = true;
                  });
                },
                items: _unidadeMedidaList.map((suggestion) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: suggestion,
                    child: Row(
                      children: [
                        Text(suggestion['descricao_unidade_medida'] ?? ''),
                        const SizedBox(width: 10),
                        Text(suggestion['codigo_unidade_medida'] ?? ''),
                      ],
                    ),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Unidade de Medida:',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecione uma unidade de medida';
                  }
                  return null;
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
                        int idPonto = await salvarDados();
                        if (idPonto != -1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PontoDetail(
                                  id: widget.pontoId, planoId: widget.planoId),
                            ),
                          );
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
    );
  }
}
