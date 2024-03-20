import 'package:http/http.dart' as http;
import 'dart:convert';
import 'database.dart'; // Assumindo que getPlanolubCompleto está em DatabaseHelper dentro de database.dart
import 'package:kluber/class/api_config.dart';

class Sincronizador {
  Future<bool> sincronizarDados() async {
    var dbHelper = DatabaseHelper();
    var dadosParaSincronizar = await dbHelper.getPlanolubCompleto();
    String url = '${ApiConfig.apiUrl}/sync-plan';
    print(dadosParaSincronizar);
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
          dadosParaSincronizar,
        ),
      );

      if (response.statusCode == 200) {
        print("Dados sincronizados com sucesso.");
        return true;
      } else {
        print("Falha na sincronização: ${response.body}");
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }
}
