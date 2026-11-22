import '../../../core/network/api_client.dart';
import 'pending_legal_consent_store.dart';
import '../domain/domain_user.dart';

abstract interface class AccountRepository {
  Future<DomainUser> provisionAndLoad({String? username, bool legalAccepted = false});

  Future<DomainUser> updateProfile({
    required String displayName,
    required String username,
    required String biography,
    required int annualReadingGoal,
  });

  Future<DomainUser> updatePrivacy({
    required bool isPrivate,
  });
}

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this.api);

  final ApiClient api;

  @override
  Future<DomainUser> provisionAndLoad({String? username, bool legalAccepted = false}) async {
    final provision = await api.request(
      'POST',
      '/api/me/provision',
      body: {
        'username': ?username,
        if (legalAccepted) ...{
          'termsAccepted': true,
          'privacyAccepted': true,
          'termsVersion': PendingLegalConsentStore.version,
          'privacyVersion': PendingLegalConsentStore.version,
        },
      },
    );

    final me = await api.request('GET', '/api/me');

    try {
      final created = DomainUser.fromJson(provision);
      final current = DomainUser.fromJson(me);

      if (created.id != current.id) {
        throw const FormatException('Account changed');
      }

      return current;
    } on FormatException {
      throw const ApiFailure(
        502,
        'No pudimos confirmar el usuario interno.',
      );
    }
  }

  @override
  Future<DomainUser> updateProfile({
    required String displayName,
    required String username,
    required String biography,
    required int annualReadingGoal,
  }) async {
    final response = await api.request(
      'PATCH',
      '/api/me',
      body: {
        'displayName': displayName,
        'username': username,
        'biography': biography,
        'annualReadingGoal': annualReadingGoal,
      },
    );

    try {
      return DomainUser.fromJson(response);
    } on FormatException {
      throw const ApiFailure(
        502,
        'No pudimos confirmar los cambios del perfil.',
      );
    }
  }

  @override
  Future<DomainUser> updatePrivacy({
    required bool isPrivate,
  }) async {
    final response = await api.request(
      'PATCH',
      '/api/me/privacy',
      body: {
        'isPrivate': isPrivate,
      },
    );

    try {
      final updated = DomainUser.fromJson(response);

      // El backend debe confirmar el estado solicitado.
      if (updated.isPrivate != isPrivate) {
        throw const FormatException('Privacy state mismatch');
      }

      return updated;
    } on FormatException {
      throw const ApiFailure(
        502,
        'No pudimos confirmar el cambio de privacidad.',
      );
    }
  }
}
