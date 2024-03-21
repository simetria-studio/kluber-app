import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:kluber/class/api_config.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/class/float_buttom.dart';
import 'package:http/http.dart' as http;
import 'package:kluber/db/database.dart';
import 'package:kluber/pages/planos_lub/planos.dart';
import 'package:uuid/uuid.dart';

class EditPlano extends StatefulWidget {
  final int idPlano;
  const EditPlano({super.key, required this.idPlano});

  @override
  State<EditPlano> createState() => _EditPlanoState();
}

class _EditPlanoState extends State<EditPlano> {
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

  // Método para carregar os dados do plano existente
  Future<void> _loadPlanoData() async {
    // Recuperar os dados do plano do banco de dados usando o id
    // Suponha que a função `getPlanoLubById` recupere os dados do plano pelo ID
    Map<String, dynamic>? planoData =
        await _databaseHelper.getPlanoById(widget.idPlano);

    // Preencher os controllers com os dados do plano
    setState(() {
      _clienteController.text = planoData?['cliente'];
      _dataCadController.text = planoData?['data_cadastro'];
      _dataRevController.text = planoData?['data_revisao'];
      _resAreaController.text = planoData?['responsavel_lubrificacao'];
      _resKluberController.text = planoData?['responsavel_kluber'];
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPlanoData();
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

  Future<void> salvarPlano() async {
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
        'data_cadastro': _reformatarData(dataCadastro), // '2022-01-01'
        'data_revisao': _reformatarData(dataRevisao),
        'responsavel_lubrificacao': responsavelLubrificacao,
        'responsavel_kluber': responsavelKluber,
        // Você precisará do ID do plano para atualizar os dados no banco de dados
      };

      // Atualize os dados do plano na base de dados usando o ID do plano existente
      await _databaseHelper.updatePlanoLub(widget.idPlano, planoLubData);

      // Exibir uma mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados atualizados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao atualizar os dados.'),
          backgroundColor: Colors.red,
        ),
      );
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
                  await salvarPlano();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Planos()));
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: ColorConfig.preto,
                  backgroundColor: ColorConfig.amarelo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Salvar'),
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
