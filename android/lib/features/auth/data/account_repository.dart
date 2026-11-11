import '../../../core/network/api_client.dart';
import '../domain/domain_user.dart';

abstract interface class AccountRepository {
  Future<DomainUser> provisionAndLoad();
}

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this.api);
  final ApiClient api;
  @override
  Future<DomainUser> provisionAndLoad() async {
    final provision = await api.request('POST', '/api/me/provision');
    final me = await api.request('GET', '/api/me');
    try {
      final created = DomainUser.fromJson(provision);
      final current = DomainUser.fromJson(me);
      if (created.id != current.id) {
        throw const FormatException('Account changed');
      }
      return current;
    } on FormatException {
      throw const ApiFailure(502, 'No pudimos confirmar el usuario interno.');
    }
  }
}
