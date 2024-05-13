class PontoLubModel {
  final int id;
  final String componentName;
  final String componentCodigo;
  final String componentDescricao;
  bool isVisible;

  // Adicione outros campos conforme necessário

  PontoLubModel({
    required this.id,
    required this.componentName,
    required this.componentCodigo,
    required this.componentDescricao,
    this.isVisible = false,
    // Inicialize outros campos aqui
  });

  // Método para criar um PontoLubModel a partir de um Map.
  // Adapte os campos conforme necessário para corresponder à sua tabela 'pontos'
  factory PontoLubModel.fromMap(Map<String, dynamic> map) {
    return PontoLubModel(
      id: map['id'],
      componentName: map['component_name'],
      componentCodigo: map['component_codigo'],
      componentDescricao: map['atv_breve_name'],
      // Atribua outros campos aqui
    );
  }
}