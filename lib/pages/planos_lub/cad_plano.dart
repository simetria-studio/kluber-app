import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kluber/class/api_config.dart';
import 'package:kluber/class/color_config.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:kluber/class/float_buttom.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/arvore.dart';

class CadPlanoLub extends StatefulWidget {
  const CadPlanoLub({super.key});

  @override
  State<CadPlanoLub> createState() => _CadPlanoLubState();
}

class _CadPlanoLubState extends State<CadPlanoLub> {
  bool userDataLoaded = false;
  bool _isClienteSelected = false;
  bool _isResponsavelSelected = false;

  late DateTime? entryDate;
  late DateTime? revDate;
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _clienteCodigoController =
      TextEditingController();
  final TextEditingController _dataCadController = TextEditingController();
  final TextEditingController _resKluberController = TextEditingController();
  final TextEditingController _resAreaController = TextEditingController();
  final TextEditingController _dataRevController = TextEditingController();
  late List<Map<String, dynamic>> _clientes;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String gerarCodigoMobile() {
    // Obter parte do timestamp atual (por exemplo, os últimos 6 dígitos)
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String parteTimestamp = timestamp.substring(timestamp.length - 6);

    // Gerar um UUID curto
    String uuid = const Uuid().v4().split('-').first;

    // Combinar parte do timestamp com parte do UUID
    String codigoMobile = parteTimestamp + uuid;

    return codigoMobile;
  }

  Future<int> salvarDados() async {
    try {
      // Captura os valores dos controllers
      String cliente = _clienteController.text;
      String dataCadastro = _dataCadController.text;
      String dataRevisao = _dataRevController.text;
      String responsavelLubrificacao = _resAreaController.text;
      String responsavelKluber = _resKluberController.text;

      // Organiza os dados em um mapa
      Map<String, dynamic> planoLubData = {
        'cliente': cliente,
        'data_cadastro': _reformatarData(dataCadastro),
        'data_revisao': _reformatarData(dataRevisao),
        'responsavel_lubrificacao': responsavelLubrificacao,
        'responsavel_kluber': responsavelKluber,
        'codigo_mobile': gerarCodigoMobile(),
      };

      // Insere os dados na base de dados e retorna o ID do plano inserido
      int id = await _databaseHelper.insertPlanoLub(planoLubData);
      return id;
    } catch (e) {
      return -1; // Retorna -1 em caso de falha
    }
  }

  void _initializeDatabase() async {
    await _databaseHelper
        .database; // Chama o método para inicializar o banco de dados
  }

  Future<void> initializeData() async {
    setState(() {
      userDataLoaded = true;
    });
    // await _fetchClientes('');
    await _fetchUsers('');
  }

  @override
  void initState() {
    super.initState();
    _clienteController.addListener(() {
      if (_clienteController.text !=
          _clientes.firstWhere(
              (client) => client['razao_social'] == _clienteController.text,
              orElse: () => {})['razao_social']) {
        _isClienteSelected = false;
      }
    });

    _resKluberController.addListener(() {
      if (_resKluberController.text !=
          _clientes.firstWhere(
              (client) => client['nome_usuario'] == _resKluberController.text,
              orElse: () => {})['nome_usuario']) {
        _isResponsavelSelected = false;
      }
    });
    _carregarClientesOffline('').then((clientesLocais) {
      if (clientesLocais.isNotEmpty) {
        // Atualizar a UI com os dados locais
        setState(() {
          _clientes = clientesLocais;
        });
      } else {
        // Buscar dados online, já que não há dados locais disponíveis
        _fetchClientes('');
      }
    });

    initializeData();
    _initializeDatabase();
    entryDate = DateTime.now();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _dataCadController.text = pickedDate.toString().split(" ")[0];
        _dataCadController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _selectRecDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dataRevController.text = picked.toString().split(" ")[0];
        _dataRevController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<List<Map<String, dynamic>>> _carregarClientesOffline(
      String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? clientesString = prefs.getString('clientes');
    List<Map<String, dynamic>> allClients = [];

    if (clientesString != null) {
      final List<dynamic> clientesJson = json.decode(clientesString);
      List<Map<String, dynamic>> filteredClients =
          clientesJson.cast<Map<String, dynamic>>();

      if (searchText.isNotEmpty) {
        filteredClients = filteredClients.where((client) {
          // Adding null checks before calling toLowerCase
          final razaoSocial = client['razao_social'] as String?;
          final cidade = client['cidade'] as String?;
          return (razaoSocial
                      ?.toLowerCase()
                      .contains(searchText.toLowerCase()) ??
                  false) ||
              (cidade?.toLowerCase().contains(searchText.toLowerCase()) ??
                  false);
        }).toList();
      }

      allClients = filteredClients;
    }

    return allClients;
  }

  Future<List<Map<String, dynamic>>> _fetchClientes(String searchText) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return _carregarClientesOffline(searchText);
    } else {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-clientes'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"},
        ).timeout(const Duration(seconds: 5)); // Timeout de 5 segundos

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('clientes', json.encode(responseData));

          return List<Map<String, dynamic>>.from(responseData);
        } else {
          print('Falha na requisição: ${response.statusCode}');
          return _carregarClientesOffline(
              searchText); // Fallback para dados offline
        }
      } on TimeoutException catch (_) {
        print('A requisição excedeu o tempo limite');
        return _carregarClientesOffline(
            searchText); // Fallback para dados offline
      } catch (e) {
        print('Erro ao fazer a requisição: $e');
        return _carregarClientesOffline(
            searchText); // Outro erro, use o fallback
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUsers(String searchText) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Não há conexão com a internet
      return _carregarUsuariosOffline(searchText);
    } else {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/get-users-kluber'),
          body: json
              .encode({"codigo_empresa": '0001', "search_text": searchText}),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          // Salva os usuários no SharedPreferences
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('usuarios', json.encode(responseData));

          return List<Map<String, dynamic>>.from(responseData);
        } else {
          print('Falha na requisição: ${response.statusCode}');
          return _carregarUsuariosOffline(
              searchText); // Fallback para dados offline
        }
      } catch (e) {
        print('Erro ao fazer a requisição: $e');
        return _carregarUsuariosOffline(
            searchText); // Fallback para erro na requisição
      }
    }
  }

  Future<List<Map<String, dynamic>>> _carregarUsuariosOffline(
      String searchText) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? usuariosString = prefs.getString('usuarios');

    if (usuariosString != null) {
      final List<dynamic> usuariosJson = json.decode(usuariosString);
      List<Map<String, dynamic>> allUsers =
          usuariosJson.cast<Map<String, dynamic>>();

      // Filtra os usuários com base no searchText, assumindo que 'nome_usuario' é o campo relevante
      if (searchText.isNotEmpty) {
        allUsers = allUsers.where((user) {
          return (user['nome_usuario']
                  .toLowerCase()
                  .contains(searchText.toLowerCase()) ||
              user['nome_usuario_completo']
                  .toLowerCase()
                  .contains(searchText.toLowerCase()));
        }).toList();
      }

      return allUsers;
    } else {
      return []; // Lista vazia se não houver dados salvos
    }
  }

  String _reformatarData(String data) {
    // Converte a data no formato 'dd/MM/yyyy' para 'yyyy-MM-dd'
    List<String> dataSplit = data.split('/');
    return '${dataSplit[2]}-${dataSplit[1]}-${dataSplit[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Novo de Plano de Lubrificação'.toUpperCase(),
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
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TypeAheadField<Map<String, dynamic>>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _clienteController,
                  enabled: userDataLoaded,
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    border: OutlineInputBorder(),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  final suggestions = await _fetchClientes(
                      pattern); // Faz a chamada à API com o texto de pesquisa
                  return suggestions;
                },
                onSuggestionSelected: (suggestion) {
                  setState(() {
                    _clienteController.text = suggestion['razao_social'];
                    _clienteCodigoController.text =
                        suggestion['codigo_cliente'];
                    _isClienteSelected = true;
                  });
                },
                itemBuilder: (context, Map<String, dynamic> suggestion) {
                  // Renderize a sugestão aqui
                  return ListTile(
                    title: Text(suggestion['razao_social'] ?? ''),
                    subtitle: Row(
                      children: [
                        Text(suggestion['cnpj_cpf'] ?? ''),
                        const SizedBox(width: 10),
                        Text(suggestion['cidade'] ?? ''),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _dataCadController,
                decoration: const InputDecoration(
                  labelText: 'Data de cadastro',
                  border: OutlineInputBorder(),
                ),
                onTap: () {
                  _selectDate(context);
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _dataRevController,
                decoration: const InputDecoration(
                  labelText: 'Data de revisão',
                  border: OutlineInputBorder(),
                ),
                onTap: () {
                  _selectRecDate(context);
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _resAreaController,
                decoration: const InputDecoration(
                  labelText: 'Responsável pela lubrificação da área',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TypeAheadField<Map<String, dynamic>>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _resKluberController,
                  enabled: userDataLoaded,
                  decoration: const InputDecoration(
                    labelText: 'Responsável Klüber',
                    border: OutlineInputBorder(),
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  final suggestions = await _fetchUsers(
                      pattern); // Faz a chamada à API com o texto de pesquisa
                  return suggestions;
                },
                onSuggestionSelected: (suggestion) {
                  setState(() {
                    _resKluberController.text = suggestion['nome_usuario'];
                    _isResponsavelSelected = true;
                  });
                },
                itemBuilder: (context, Map<String, dynamic> suggestion) {
                  // Renderize a sugestão aqui
                  return ListTile(
                    title: Text(suggestion['nome_usuario'] ?? ''),
                    subtitle: Row(
                      children: [
                        Text(suggestion['nome_usuario_completo'] ?? ''),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (!_isClienteSelected || !_isResponsavelSelected) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Erro"),
                        content: const Text(
                            "Por favor, selecione um cliente e um responsável Klüber das sugestões."),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
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
                          builder: (context) => Arvore(idPlano: idPlano),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: ColorConfig.preto,
                  backgroundColor: ColorConfig.amarelo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Próximo'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatBtn.build(
          context), // Chama o FloatingActionButton da classe FloatBtn
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatBtn.bottomAppBar(context),
    );
  }
}
