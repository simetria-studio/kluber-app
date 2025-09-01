import 'api_config.dart';

class UrlHelper {
  static const String _baseUrl = ApiConfig.apiUrl;

  // URLs para solicitação de acesso
  static String get newUserUrl => '$_baseUrl/solicitacao-acesso';
  static String get clientesUrl => '$_baseUrl/get-clientes';
  static String get usuariosKluberUrl => '$_baseUrl/get-users-kluber';
  // URLs para planos de lubrificação
  static String get planosUrl => '$_baseUrl/planos';
  static String get syncPlanUrl => '$_baseUrl/sync-plan';
}
