import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/cliente_model.dart';
import 'models/usuario_kluber_model.dart';
import 'services/cliente_service.dart';
import '../class/url_helper.dart';

class SolicitacaoAcessoScreen extends StatefulWidget {
  const SolicitacaoAcessoScreen({Key? key}) : super(key: key);

  @override
  State<SolicitacaoAcessoScreen> createState() => _SolicitacaoAcessoScreenState();
}

class _SolicitacaoAcessoScreenState extends State<SolicitacaoAcessoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cargoController = TextEditingController();
  
  // Controladores para nova empresa
  final _nomeCompanhiaController = TextEditingController();
  final _informeCompanhiaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cepController = TextEditingController();

  List<Cliente> _clientes = [];
  List<UsuarioKluber> _representantes = [];
  Cliente? _clienteSelecionado;
  UsuarioKluber? _representanteSelecionado;
  bool _isLoading = false;
  bool _mostrarFormularioNovaEmpresa = false;
  
  String? _paisSelecionado;
  String? _estadoSelecionado;
  String? _cidadeSelecionada;

  // Listas para os dropdowns
  final List<String> _paises = ['Brasil', 'Argentina', 'Chile', 'Uruguai', 'Paraguai'];
  final List<String> _estados = ['AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'];
  final List<String> _cidades = ['São Paulo', 'Rio de Janeiro', 'Belo Horizonte', 'Salvador', 'Brasília', 'Fortaleza', 'Curitiba', 'Recife', 'Porto Alegre', 'Manaus'];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clientes = await ClienteService().getClientes();
      final representantes = await ClienteService().getUsuariosKluber();
      
      setState(() {
        _clientes = clientes;
        _representantes = representantes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmarSolicitacao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validações específicas
    if (!_mostrarFormularioNovaEmpresa && _clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma companhia')),
      );
      return;
    }

    if (_representanteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um representante')),
      );
      return;
    }

    // Validações para nova empresa
    if (_mostrarFormularioNovaEmpresa) {
      if (_nomeCompanhiaController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome da companhia é obrigatório')),
        );
        return;
      }
      if (_cnpjController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CNPJ é obrigatório')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar dados para envio
      Map<String, dynamic> dadosSolicitacao = {
        // Dados pessoais
        'nome_completo': _nomeController.text,
        'email': _emailController.text,
        'cargo_ocupacao': _cargoController.text,
        
        // Representante
        'representante_id': _representanteSelecionado!.id,
        'representante_nome': _representanteSelecionado!.nomeUsuarioCompleto,
        
        // Dados da empresa
        'nova_empresa': _mostrarFormularioNovaEmpresa,
      };

      if (_mostrarFormularioNovaEmpresa) {
        // Dados da nova empresa
        dadosSolicitacao.addAll({
          'nome_companhia': _nomeCompanhiaController.text,
          'informe_companhia': _informeCompanhiaController.text,
          'cnpj': _cnpjController.text,
          'endereco': _enderecoController.text,
          'numero': _numeroController.text,
          'pais': _paisSelecionado ?? '',
          'estado': _estadoSelecionado ?? '',
          'cidade': _cidadeSelecionada ?? '',
          'bairro': _bairroController.text,
          'cep': _cepController.text,
        });
      } else {
        // Empresa existente
        dadosSolicitacao.addAll({
          'cliente_id': _clienteSelecionado!.id,
          'razao_social': _clienteSelecionado!.razaoSocial,
          'codigo_empresa': _clienteSelecionado!.codigoEmpresa,
          'codigo_cliente': _clienteSelecionado!.codigoCliente,
        });
      }

      // Enviar para API
      final response = await http.post(
        Uri.parse(UrlHelper.newUserUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(dadosSolicitacao),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Solicitação enviada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Erro na API
        String errorMessage = 'Erro ao enviar solicitação';
        
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          errorMessage = 'Erro no servidor (${response.statusCode})';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _adicionarNovaCompanhia() {
    setState(() {
      _mostrarFormularioNovaEmpresa = !_mostrarFormularioNovaEmpresa;
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cargoController.dispose();
    _nomeCompanhiaController.dispose();
    _informeCompanhiaController.dispose();
    _cnpjController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cepController.dispose();
    super.dispose();
  }

  Widget _buildFormularioNovaEmpresa() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF2D3748),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nova Empresa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _mostrarFormularioNovaEmpresa = false;
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: const Color(0xFF4A5568),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF718096)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFABA00), width: 2),
                  ),
                  labelStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              child: Column(
                children: [
                  // Nome da Companhia
                  TextFormField(
                    controller: _nomeCompanhiaController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome da Companhia',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Informe a Companhia
                  TextFormField(
                    controller: _informeCompanhiaController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Informe a Companhia',
                      hintText: 'Ex: NOME COMPANHIA - CIDADE - UF',
                      hintStyle: TextStyle(color: Color(0xFF718096)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // CNPJ
                  TextFormField(
                    controller: _cnpjController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Informe o CNPJ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Endereço
                  TextFormField(
                    controller: _enderecoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Informe o Endereço',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Número
                  TextFormField(
                    controller: _numeroController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Informe o Número',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // País
                  DropdownButtonFormField<String>(
                    value: _paisSelecionado,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF4A5568),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Informe o País',
                    ),
                    items: _paises.map((pais) {
                      return DropdownMenuItem(
                        value: pais,
                        child: Text(pais, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _paisSelecionado = value;
                      });
                    },
                    hint: const Text('- País -', style: TextStyle(color: Color(0xFFA0AEC0))),
                  ),
                  const SizedBox(height: 16),
                  // Estado
                  DropdownButtonFormField<String>(
                    value: _estadoSelecionado,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF4A5568),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Informe o Estado',
                    ),
                    items: _estados.map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text(estado, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _estadoSelecionado = value;
                      });
                    },
                    hint: const Text('- Estado / UF -', style: TextStyle(color: Color(0xFFA0AEC0))),
                  ),
                  const SizedBox(height: 16),
                  // Cidade
                  DropdownButtonFormField<String>(
                    value: _cidadeSelecionada,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF4A5568),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Informe a Cidade',
                    ),
                    items: _cidades.map((cidade) {
                      return DropdownMenuItem(
                        value: cidade,
                        child: Text(cidade, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _cidadeSelecionada = value;
                      });
                    },
                    hint: const Text('- Cidade -', style: TextStyle(color: Color(0xFFA0AEC0))),
                  ),
                  const SizedBox(height: 16),
                  // Bairro
                  TextFormField(
                    controller: _bairroController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Informe o Bairro',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // CEP
                  TextFormField(
                    controller: _cepController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Informe o CEP',
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

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header com logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Solicitação de Acesso',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preencha os dados abaixo para solicitar acesso',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFA0AEC0),
                    ),
                  ),
                ],
              ),
            ),
            // Formulário
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: width > 500 ? 450 : width * 0.95,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Dados Pessoais
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: const Color(0xFF2D3748),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dados Pessoais',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme: InputDecorationTheme(
                                  filled: true,
                                  fillColor: const Color(0xFF4A5568),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF718096)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFFABA00), width: 2),
                                  ),
                                  labelStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nomeController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Nome Completo',
                                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFFFABA00)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nome completo é obrigatório';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'E-mail',
                                      prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFFABA00)),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'E-mail é obrigatório';
                                      }
                                      if (!value.contains('@')) {
                                        return 'E-mail inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _cargoController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Cargo/Ocupação',
                                      prefixIcon: Icon(Icons.work_outline, color: Color(0xFFFABA00)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Cargo/Ocupação é obrigatório';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Card Informações da Empresa
                    if (!_mostrarFormularioNovaEmpresa) ...[
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: const Color(0xFF2D3748),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informações da Empresa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme: InputDecorationTheme(
                                    filled: true,
                                    fillColor: const Color(0xFF4A5568),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF718096)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFFABA00), width: 2),
                                    ),
                                    labelStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    DropdownButtonFormField<Cliente>(
                                      value: _clienteSelecionado,
                                      isExpanded: true,
                                      dropdownColor: const Color(0xFF4A5568),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Nome da Companhia',
                                        prefixIcon: Icon(Icons.business_outlined, color: Color(0xFFFABA00)),
                                      ),
                                      items: _clientes.map((cliente) {
                                        return DropdownMenuItem(
                                          value: cliente,
                                          child: Text(
                                            '${cliente.codigoEmpresa} - ${cliente.razaoSocial}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _clienteSelecionado = value;
                                        });
                                      },
                                      hint: const Text('Selecione uma companhia...', style: TextStyle(color: Color(0xFFA0AEC0))),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const SizedBox(),
                                        ElevatedButton(
                                          onPressed: _adicionarNovaCompanhia,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFABA00),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Não Encontrei'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<UsuarioKluber>(
                                      value: _representanteSelecionado,
                                      isExpanded: true,
                                      dropdownColor: const Color(0xFF4A5568),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Representante Klüber Lubrication',
                                        prefixIcon: Icon(Icons.support_agent_outlined, color: Color(0xFFFABA00)),
                                      ),
                                      items: _representantes.map((representante) {
                                        return DropdownMenuItem(
                                          value: representante,
                                          child: Text(representante.nomeUsuarioCompleto, style: const TextStyle(color: Colors.white)),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _representanteSelecionado = value;
                                        });
                                      },
                                      hint: const Text('Selecione um representante...', style: TextStyle(color: Color(0xFFA0AEC0))),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // Formulário de Nova Empresa
                    if (_mostrarFormularioNovaEmpresa) ...[
                      _buildFormularioNovaEmpresa(),
                      const SizedBox(height: 20),
                      // Card Representante (separado quando nova empresa)
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: const Color(0xFF2D3748),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Representante',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme: InputDecorationTheme(
                                    filled: true,
                                    fillColor: const Color(0xFF4A5568),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF718096)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFFABA00), width: 2),
                                    ),
                                    labelStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                                child: DropdownButtonFormField<UsuarioKluber>(
                                  value: _representanteSelecionado,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF4A5568),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Representante Klüber Lubrication',
                                    prefixIcon: Icon(Icons.support_agent_outlined, color: Color(0xFFFABA00)),
                                  ),
                                  items: _representantes.map((representante) {
                                    return DropdownMenuItem(
                                      value: representante,
                                      child: Text(representante.nomeUsuarioCompleto, style: const TextStyle(color: Colors.white)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _representanteSelecionado = value;
                                    });
                                  },
                                  hint: const Text('Selecione um representante...', style: TextStyle(color: Color(0xFFA0AEC0))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFA0AEC0),
                              side: const BorderSide(color: Color(0xFF4A5568)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _confirmarSolicitacao,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFABA00),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Enviar Solicitação',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
} 