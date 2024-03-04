import 'package:flutter/material.dart';
import 'package:kluber/class/color_config.dart';
import 'package:kluber/pages/planos_lub/cad_plano.dart';
// Importe a tela CadPlanoLub aqui

class FloatBtn {
  static Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => CadPlanoLub(),
        ));
      },
      child: Icon(Icons.add),
      backgroundColor: ColorConfig.amarelo,
      shape: CircleBorder(),
    );
  }

  static Widget bottomAppBar() {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 4.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {},
            color: ColorConfig.preto,
          ),
          IconButton(
            icon: Icon(Icons.bar_chart_sharp),
            onPressed: () {},
            color: ColorConfig.preto,
          ),
          SizedBox(width: 48), // O espaço para o FloatingActionButton
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
            color: ColorConfig.preto,
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {},
            color: ColorConfig.preto,
          ),
        ],
      ),
      color: ColorConfig.amarelo,
    );
  }
}
