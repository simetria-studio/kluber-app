import 'package:kluber/pages/models/equip_model.dart';

class TagMaquina {
  final String tagNome;
  final String maquinaNome;
  bool isVisible;
  final int id;
  final List<ConjuntoEquipModel> conjuntosEquip;

  TagMaquina({
    required this.tagNome,
    required this.maquinaNome,
    required this.conjuntosEquip,
    this.isVisible = false,
    required this.id,
  });
}
