import 'package:flutter/material.dart';
import 'package:kluber/pages/homepage.dart';
import 'package:kluber/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(), // Verifica se o usuário está logado
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Se a verificação estiver em andamento, exiba um indicador de carregamento
          return const CircularProgressIndicator();
        } else {
          if (snapshot.hasData && snapshot.data!) {
            // Se o usuário estiver logado, redirecione para a tela Home
            return MaterialApp(
              title: 'X-ERP',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              home: const HomePage(),
            );
          } else {
            // Se o usuário não estiver logado, exiba a tela de login
            return MaterialApp(
              title: 'XERP',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              home: const LoginPage(),
              routes: {
                // '/': (context) => const HomePage(),
                '/orcamento': (context) => const HomePage(),
              },
            );
          }
        }
      },
    );
  }

  Future<bool> _isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    return token != null;
  }
}
