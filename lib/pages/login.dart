import 'package:flutter/material.dart';
import 'package:kluber/class/api_config.dart';
import 'package:kluber/pages/homepage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isObscure = true;

  Future<void> _login() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? existingToken = prefs.getString('token');
    if (existingToken != null) {
      // Já existe um token salvo, redirecione para a tela Home ou faça qualquer ação necessária

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      return; // Encerra a função para evitar a execução do login novamente
    }
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final String usuario = _usuarioController.text;
    final String password = _senhaController.text;

    // Aqui você fará a chamada para a sua API com os dados do login
    final response = await http.post(
      Uri.parse('${ApiConfig.apiUrl}/login-app'),
      body: {
        'usuario': usuario,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      // O login foi bem-sucedido
      // Você pode redirecionar o usuário para a próxima tela ou fazer qualquer ação necessária

      final responseData = json.decode(response.body);
      final String token = responseData['access_token'];

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      print('Login bem-sucedido!');
      print('Token: $token');
    } else {
      // O login falhou
      // Você pode exibir uma mensagem de erro para o usuário ou fazer quaslquer tratamento necessário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha no login. Tente novamente.'),
        ),
      );
      print('Falha no login. Tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color(0xFFFABA00),
              width: double.infinity,
              height: 100,
              child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      child: Text(
                        'Seja bem vindo(a)',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(
                      child: Text(
                        'Faça login para acessar sua conta',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ]),
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset('assets/logo.png'),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.only(
                        top: 35.0, left: 16.0, right: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        // ignore: prefer_const_literals_to_create_immutables
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              controller: _usuarioController,
                              keyboardType: TextInputType.text,
                              style: const TextStyle(
                                // Definindo o estilo do texto
                                color: Colors.white, // Cor do texto
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                                labelText: 'Usuário',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              style: const TextStyle(
                                // Definindo o estilo do texto
                                color: Colors.white, // Cor do texto
                              ),
                              controller: _senhaController,
                              keyboardType: TextInputType.text,
                              validator: (senha) {
                                if (senha == null || senha.isEmpty) {
                                  return 'Por favor, digite sua senha!';
                                } else if (senha.length < 5) {
                                  return 'Por favor, senha maior que 5 caracteres';
                                }
                                return null;
                              },
                              obscureText:
                                  _isObscure, // Define se a senha é oculta ou não
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                                labelStyle: const TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                                labelText: 'Senha',
                                suffixIcon: IconButton(
                                  // Adiciona o IconButton para alternar a visibilidade da senha
                                  icon: Icon(_isObscure
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () {
                                    setState(() {
                                      _isObscure = !_isObscure;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin:
                                  const EdgeInsets.only(top: 10.0, right: 22.0),
                              child: GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  'Esqueceu sua senha?',
                                  style: TextStyle(
                                    color: Color(0xFFFABA00),
                                    fontSize: 14,
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                        top: 20.0, left: 12.0, right: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFABA00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _login();
                            }
                          },
                          child: const Text(
                            'Entrar',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Container(
                    margin: const EdgeInsets.only(top: 40.0),
                    child: Image.asset('assets/logo_rentatec.png'),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
