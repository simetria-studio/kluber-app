import 'package:kluber/pages/models/linha_model.dart';

class SubareaModel {
  final int id;
  final String nome;
  List<LinhaModel> linhas;
  bool isVisible;

  SubareaModel({
    required this.id,
    required this.nome,
    required this.linhas,
    this.isVisible = false,
  });

  factory SubareaModel.fromMap(Map<String, dynamic> map) {
    return SubareaModel(
      id: map['id'],
      nome: map['nome'],
      linhas: [], // Você precisará adaptar isso se linhas vierem do mapa
      isVisible: map['isVisible'] ?? true,
    );
  }
}