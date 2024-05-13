import 'package:kluber/pages/models/ponto_model.dart';

class ConjuntoEquipModel {
  final int id;
  final String conjNome;
  final String equiNome;
  bool isVisible;
  List<PontoLubModel> pontosLub;

  ConjuntoEquipModel({
    required this.id,
    required this.conjNome,
    required this.equiNome,
    this.isVisible = false,
    this.pontosLub = const [],
  });
}
