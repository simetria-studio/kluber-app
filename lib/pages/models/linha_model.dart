import 'package:kluber/pages/models/equip_model.dart';
import 'package:kluber/pages/models/tag_model.dart';

class LinhaModel {
  final int id;
  final String nome;
  bool isVisible;
  final List<TagMaquina> tagsMaquinas;
  final List<ConjuntoEquipModel> conjuntosEquip; // Adicione esta linha

  LinhaModel({
    required this.id,
    required this.nome,
    required this.tagsMaquinas,
    this.isVisible = false,
    this.conjuntosEquip = const [], // Adicione esta linha
  });

  factory LinhaModel.fromMap(Map<String, dynamic> map) {
    return LinhaModel(
      id: map['id'],
      nome: map['nome'],
      isVisible: map['isVisible'] ?? true,
      tagsMaquinas: [], // Você precisará adaptar isso se tagsMaquinas vierem do mapa
      conjuntosEquip: [], // Adicione esta linha
    );
  }
}
