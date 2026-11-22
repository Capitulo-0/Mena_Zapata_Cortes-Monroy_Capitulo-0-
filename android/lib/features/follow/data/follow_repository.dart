import '../../../core/network/api_client.dart';

/// Estados exactos que devuelve FollowController de Spring Boot.
enum FollowStatus {
  pending('PENDING'),
  accepted('ACCEPTED');

  const FollowStatus(this.apiValue);
  final String apiValue;

  static FollowStatus fromApi(String value) {
    for (final status in FollowStatus.values) {
      if (status.apiValue == value) return status;
    }
    throw const FormatException('Estado de seguimiento desconocido');
  }
}

/// Relación devuelta al seguir a alguien o aprobar una solicitud.
class FollowRelationship {
  const FollowRelationship({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.acceptedAt,
  });

  final int id;
  final FollowStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  factory FollowRelationship.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final status = json['status'];
    final createdAt = json['createdAt'];
    final acceptedAt = json['acceptedAt'];

    if (id is! int ||
        id <= 0 ||
        status is! String ||
        createdAt is! String ||
        (acceptedAt != null && acceptedAt is! String)) {
      throw const FormatException('Relación de seguimiento inválida');
    }

    final created = DateTime.tryParse(createdAt);
    final accepted = acceptedAt == null
        ? null
        : DateTime.tryParse(acceptedAt as String);
    if (created == null || (acceptedAt != null && accepted == null)) {
      throw const FormatException('Fecha de seguimiento inválida');
    }

    return FollowRelationship(
      id: id,
      status: FollowStatus.fromApi(status),
      createdAt: created.toUtc(),
      acceptedAt: accepted?.toUtc(),
    );
  }
}

/// Datos públicos mínimos de un lector en las listas sociales.
class FollowReader {
  const FollowReader({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
  });

  final int id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  factory FollowReader.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final username = json['username'];
    final name = json['displayName'];
    final avatar = json['avatarUrl'];
    if (id is! int ||
        id <= 0 ||
        username is! String ||
        username.trim().isEmpty ||
        (name != null && name is! String) ||
        (avatar != null && avatar is! String)) {
      throw const FormatException('Lector de seguimiento inválido');
    }
    return FollowReader(
      id: id,
      username: username,
      displayName: name as String?,
      avatarUrl: avatar as String?,
    );
  }
}

/// Página del resultado de Spring Data (`Page<FollowUser>`).
class FollowReaderPage {
  const FollowReaderPage({
    required this.readers,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  final List<FollowReader> readers;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  factory FollowReaderPage.fromJson(Map<String, dynamic> json) {
    int requiredNonnegativeInt(String field) {
      final value = json[field];
      if (value is int && value >= 0) return value;
      throw FormatException('Paginación inválida: $field');
    }

    final content = json['content'];
    final last = json['last'];
    if (content is! List || last is! bool) {
      throw const FormatException('Página de seguidores inválida');
    }
    return FollowReaderPage(
      readers: List<FollowReader>.unmodifiable(
        content.map((element) {
          if (element is! Map<String, dynamic>) {
            throw const FormatException('Lector inválido');
          }
          return FollowReader.fromJson(element);
        }),
      ),
      page: requiredNonnegativeInt('number'),
      size: requiredNonnegativeInt('size'),
      totalElements: requiredNonnegativeInt('totalElements'),
      totalPages: requiredNonnegativeInt('totalPages'),
      isLast: last,
    );
  }
}

/// Contadores de relaciones ACCEPTED, nunca de solicitudes pendientes.
class FollowCounts {
  const FollowCounts({
    required this.followersCount,
    required this.followingCount,
  });

  final int followersCount;
  final int followingCount;

  factory FollowCounts.fromJson(Map<String, dynamic> json) {
    final followers = json['followersCount'];
    final following = json['followingCount'];
    if (followers is! int ||
        followers < 0 ||
        following is! int ||
        following < 0) {
      throw const FormatException('Contadores de seguimiento inválidos');
    }
    return FollowCounts(followersCount: followers, followingCount: following);
  }
}

abstract interface class FollowRepository {
  /// Seguidores aceptados visibles para el usuario autenticado.
  Future<FollowReaderPage> getFollowers(
    String username, {
    int page = 0,
    int size = 20,
  });

  /// Cuentas seguidas, excluyendo solicitudes pendientes.
  Future<FollowReaderPage> getFollowing(
    String username, {
    int page = 0,
    int size = 20,
  });

  /// Contadores visibles conforme a la política de privacidad del backend.
  Future<FollowCounts> getCounts(String username);

  /// Devuelve null si el usuario autenticado no sigue a ese perfil.
  Future<FollowStatus?> getStatus(String username);

  /// En cuentas públicas devuelve ACCEPTED; en privadas, PENDING.
  Future<FollowRelationship> follow(String username);

  /// Cancela una solicitud propia o deja de seguir a un perfil.
  Future<void> unfollow(String username);

  /// Solo el destinatario de la solicitud puede autorizarla.
  Future<FollowRelationship> acceptRequest(int followId);

  /// Solo el destinatario puede descartar una solicitud pendiente.
  Future<void> rejectRequest(int followId);
}

/// Todas las peticiones usan el token Firebase incorporado por ApiClient.
class ApiFollowRepository implements FollowRepository {
  const ApiFollowRepository(this.api);

  final ApiClient api;

  String _profilePath(String username) {
    final normalized = username.trim().replaceFirst(RegExp(r'^@'), '');
    if (normalized.isEmpty ||
        normalized.contains('/') ||
        normalized.contains('\\') ||
        normalized == '.' ||
        normalized == '..') {
      throw const ApiFailure(400, 'Nombre de usuario inválido.');
    }
    return '/api/follows/${Uri.encodeComponent(normalized)}';
  }

  String _requestPath(int followId) {
    if (followId <= 0) {
      throw const ApiFailure(400, 'Solicitud de seguimiento inválida.');
    }
    return '/api/follows/requests/$followId';
  }

  Map<String, dynamic> _requireMap(Object? response) {
    if (response is Map<String, dynamic>) return response;
    throw const ApiFailure(502, 'Respuesta de seguimiento inválida.');
  }

  FollowRelationship _relationship(Object? response) {
    try {
      return FollowRelationship.fromJson(_requireMap(response));
    } on FormatException {
      throw const ApiFailure(502, 'Respuesta de seguimiento inválida.');
    } on TypeError {
      throw const ApiFailure(502, 'Respuesta de seguimiento inválida.');
    }
  }

  void _validatePage(int page, int size) {
    if (page < 0 || size < 1 || size > 100) {
      throw const ApiFailure(400, 'Paginación de seguidores inválida.');
    }
  }

  Future<FollowReaderPage> _getReaders(
    String username,
    String list,
    int page,
    int size,
  ) async {
    _validatePage(page, size);
    final response = await api.requestJson(
      'GET',
      '${_profilePath(username)}/$list',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    try {
      return FollowReaderPage.fromJson(_requireMap(response));
    } on FormatException {
      throw const ApiFailure(
        502,
        'El backend devolvió una lista de lectores inválida.',
      );
    } on TypeError {
      throw const ApiFailure(
        502,
        'El backend devolvió una lista de lectores inválida.',
      );
    }
  }

  @override
  Future<FollowReaderPage> getFollowers(
    String username, {
    int page = 0,
    int size = 20,
  }) => _getReaders(username, 'followers', page, size);

  @override
  Future<FollowReaderPage> getFollowing(
    String username, {
    int page = 0,
    int size = 20,
  }) => _getReaders(username, 'following', page, size);

  @override
  Future<FollowCounts> getCounts(String username) async {
    final response = await api.requestJson(
      'GET',
      '${_profilePath(username)}/counts',
    );
    try {
      return FollowCounts.fromJson(_requireMap(response));
    } on FormatException {
      throw const ApiFailure(502, 'El backend devolvió contadores inválidos.');
    } on TypeError {
      throw const ApiFailure(502, 'El backend devolvió contadores inválidos.');
    }
  }

  @override
  Future<FollowStatus?> getStatus(String username) async {
    final response = await api.requestJson(
      'GET',
      '${_profilePath(username)}/status',
    );
    final value = _requireMap(response)['status'];
    if (value == null) return null;
    if (value is! String) {
      throw const ApiFailure(502, 'Estado de seguimiento inválido.');
    }
    try {
      return FollowStatus.fromApi(value);
    } on FormatException {
      throw const ApiFailure(502, 'Estado de seguimiento inválido.');
    }
  }

  @override
  Future<FollowRelationship> follow(String username) async {
    final response = await api.requestJson('POST', _profilePath(username));
    return _relationship(response);
  }

  @override
  Future<void> unfollow(String username) async {
    await api.requestJson('DELETE', _profilePath(username));
    // Spring Boot responde 204 No Content.
  }

  @override
  Future<FollowRelationship> acceptRequest(int followId) async {
    final response = await api.requestJson(
      'PATCH',
      '${_requestPath(followId)}/accept',
    );
    return _relationship(response);
  }

  @override
  Future<void> rejectRequest(int followId) async {
    await api.requestJson('DELETE', _requestPath(followId));
    // Spring Boot responde 204 No Content.
  }
}
