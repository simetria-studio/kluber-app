import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/class/float_buttom.dart';
// import 'package:kluber/pages/planos_lub/cad_plano.dart';
import 'package:kluber/pages/planos_lub/planos.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          SizedBox(
            width: 180,
            height: 180,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: ColorConfig.amarelo, // Cor do ícone e do texto
                elevation: 2, // Elevação do botão
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10), // Cantos arredondados
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10), // Espaçamento interno do botão
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const Planos(),
                ));
              },
              child: const Column(
                mainAxisSize:
                    MainAxisSize.min, // Use min para evitar esticar a coluna
                children: <Widget>[
                  Image(image: AssetImage('assets/oil.png')),
                  Text(
                    'PLANOS DE LUBRIFICAÇÃO', // O texto que você quer exibir
                    textAlign: TextAlign.center, // Centraliza o texto
                    style: TextStyle(
                      fontSize: 16, // O tamanho da fonte do texto
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 180,
            height: 180,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: ColorConfig.amarelo, // Cor do ícone e do texto
                elevation: 2, // Elevação do botão
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10), // Cantos arredondados
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10), // Espaçamento interno do botão
              ),
              onPressed: () {
                // Ação quando o botão é pressionado
              },
              child: const Column(
                mainAxisSize:
                    MainAxisSize.min, // Use min para evitar esticar a coluna
                children: <Widget>[
                  Image(image: AssetImage('assets/oil.png')),
                  Text(
                    'MAQUINAS PESADAS', // O texto que você quer exibir
                    textAlign: TextAlign.center, // Centraliza o texto
                    style: TextStyle(
                      fontSize: 16, // O tamanho da fonte do texto
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatBtn.build(
          context), // Chama o FloatingActionButton da classe FloatBtn
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatBtn.bottomAppBar(),
    );
  }
}
