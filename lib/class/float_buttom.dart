import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/pages/planos_lub/cad_plano.dart';
// Importe a tela CadPlanoLub aqui

class FloatBtn {
  static Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const CadPlanoLub(),
        ));
      },
      backgroundColor: ColorConfig.amarelo,
      shape: const CircleBorder(),
      child: const Icon(Icons.add),
    );
  }

  static Widget bottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 4.0,
      color: ColorConfig.amarelo,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {},
            color: ColorConfig.preto,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_sharp),
            onPressed: () {},
            color: ColorConfig.preto,
          ),
          const SizedBox(width: 48), // O espaço para o FloatingActionButton
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
            color: ColorConfig.preto,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
            color: ColorConfig.preto,
          ),
        ],
      ),
    );
  }
}
