
import 'package:kluber/pages/models/subarea_model.dart';

class AreaModel {
  final int id;
  final String nome;
  List<SubareaModel> subareas;
  bool isVisible;

  AreaModel({
    required this.id,
    required this.nome,
    required this.subareas,
    this.isVisible = false,
  });

  factory AreaModel.fromMap(Map<String, dynamic> map) {
    var subareasList = map['subareas'] as List<dynamic>? ?? [];
    List<SubareaModel> subareas = subareasList.map((subareaMap) => SubareaModel.fromMap(subareaMap)).toList();

    return AreaModel(
      id: map['id'] as int,
      nome: map['nome'] as String,
      subareas: subareas,
      isVisible: map.containsKey('isVisible') ? map['isVisible'] as bool : false,
    );
  }

  // Map<String, dynamic> toMap() {
  //   return {
  //     'id': id,
  //     'nome': nome,
  //     'subareas': subareas.map((subarea) => subarea.toMap()).toList(),
  //     'isVisible': isVisible,
  //   };
  // }
}