class Cliente {
  final int id;
  final String razaoSocial;
  final String codigoEmpresa;
  final String codigoCliente;
  final String nomeFantasia;
  final String email;

  Cliente({
    required this.id,
    required this.razaoSocial,
    required this.codigoEmpresa,
    required this.codigoCliente,
    required this.nomeFantasia,
    required this.email,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] ?? 0,
      razaoSocial: json['razao_social'] ?? '',
      codigoEmpresa: json['codigo_empresa'] ?? '',
      codigoCliente: json['codigo_cliente'] ?? '',
      nomeFantasia: json['nome_fantasia'] ?? json['nomeFantasia'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'razao_social': razaoSocial,
      'codigo_empresa': codigoEmpresa,
      'codigo_cliente': codigoCliente,
      'nome_fantasia': nomeFantasia,
      'email': email,
    };
  }
}
