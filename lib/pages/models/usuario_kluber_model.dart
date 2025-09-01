class UsuarioKluber {
  final int id;
  final String nomeUsuarioCompleto;
  final String email;
  final String? telefone;

  UsuarioKluber({
    required this.id,
    required this.nomeUsuarioCompleto,
    required this.email,
    this.telefone,
  });

  factory UsuarioKluber.fromJson(Map<String, dynamic> json) {
    return UsuarioKluber(
      id: json['id'] ?? 0,
      nomeUsuarioCompleto: json['nome_usuario_completo'] ?? json['nome'] ?? '',
      email: json['email'] ?? '',
      telefone: json['telefone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_usuario_completo': nomeUsuarioCompleto,
      'email': email,
      'telefone': telefone,
    };
  }
}
