import 'package:flutter/material.dart';
import 'package:kluber/class/api_config.dart';
import 'package:kluber/class/color_config.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:kluber/class/float_buttom.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/arvore.dart';

class CadPlanoLub extends StatefulWidget {
  const CadPlanoLub({super.key});

  @override
  State<CadPlanoLub> createState() => _CadPlanoLubState();
}

class _CadPlanoLubState extends State<CadPlanoLub> {
  bool userDataLoaded = false;
  late DateTime? entryDate;
  late DateTime? revDate;
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _clienteCodigoController =
      TextEditingController();
  final TextEditingController _dataCadController = TextEditingController();
  final TextEditingController _resKluberController = TextEditingController();
  final TextEditingController _resAreaController = TextEditingController();
  final TextEditingController _dataRevController = TextEditingController();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

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
        'data_cadastro': dataCadastro,
        'data_revisao': dataRevisao,
        'responsavel_lubrificacao': responsavelLubrificacao,
        'responsavel_kluber': responsavelKluber
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
    await _fetchClientes('');
    await _fetchUsers('');
  }

  @override
  void initState() {
    super.initState();
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
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchClientes(String searchText) async {
    final response = await http.post(
      Uri.parse(
          '${ApiConfig.apiUrl}/get-clientes'), // Remova o parâmetro 'page' da URL
      body: json.encode({"codigo_empresa": '0001', "search_text": searchText}),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final dynamic responseData = json.decode(response.body);
      if (responseData is List<dynamic>) {
        final List<Map<String, dynamic>> clientes =
            List<Map<String, dynamic>>.from(responseData);
        // print(clientes);
        return clientes; // Retorne a lista de sugestões
      } else {
        throw Exception(
            "Falha ao carregar os clientes: dados não são uma lista");
      }
    } else {
      throw Exception("Falha ao carregar os clientes");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUsers(String searchText) async {
    final response = await http.post(
      Uri.parse(
          '${ApiConfig.apiUrl}/get-users-kluber'), // Remova o parâmetro 'page' da URL
      body: json.encode({"codigo_empresa": '0001', "search_text": searchText}),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final dynamic responseData = json.decode(response.body);
      if (responseData is List<dynamic>) {
        final List<Map<String, dynamic>> usuarios =
            List<Map<String, dynamic>>.from(responseData);
        // print(clientes);
        return usuarios; // Retorne a lista de sugestões
      } else {
        throw Exception(
            "Falha ao carregar os clientes: dados não são uma lista");
      }
    } else {
      throw Exception("Falha ao carregar os clientes");
    }
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
                  int idPlano = await salvarDados();
                  if (idPlano != -1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Arvore(idPlano: idPlano),
                      ),
                    );
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
      bottomNavigationBar: FloatBtn.bottomAppBar(),
    );
  }
}
