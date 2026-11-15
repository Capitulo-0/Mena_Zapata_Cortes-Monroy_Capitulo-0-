import '../../../core/network/api_client.dart';
import '../domain/reader_notification.dart';

/// One page of notifications returned by Spring Data's Page JSON response.
class ReaderNotificationPage {
  const ReaderNotificationPage({
    required this.notifications,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  final List<ReaderNotification> notifications;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  factory ReaderNotificationPage.fromJson(Map<String, dynamic> json) {
    int requiredInt(String key) {
      final value = json[key];
      if (value is int && value >= 0) return value;
      throw FormatException('Campo de paginación inválido: $key');
    }

    final rawContent = json['content'];
    if (rawContent is! List) {
      throw const FormatException('Contenido del buzón inválido');
    }

    final last = json['last'];
    if (last is! bool) {
      throw const FormatException('Indicador de última página inválido');
    }

    return ReaderNotificationPage(
      notifications: List<ReaderNotification>.unmodifiable(
        rawContent.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Notificación inválida');
          }
          return ReaderNotification.fromJson(item);
        }),
      ),
      page: requiredInt('number'),
      size: requiredInt('size'),
      totalElements: requiredInt('totalElements'),
      totalPages: requiredInt('totalPages'),
      isLast: last,
    );
  }
}

/// Contract for reading the authenticated user's notification inbox.
abstract interface class NotificationRepository {
  Future<ReaderNotificationPage> getInbox({int page = 0, int size = 20});

  Future<int> getUnreadCount();

  Future<ReaderNotification> markRead(int notificationId);
}

/// Uses ApiClient, which automatically sends the current Firebase ID token.
class ApiNotificationRepository implements NotificationRepository {
  const ApiNotificationRepository(this.api);

  final ApiClient api;

  @override
  Future<ReaderNotificationPage> getInbox({int page = 0, int size = 20}) async {
    if (page < 0 || size < 1 || size > 100) {
      throw const ApiFailure(400, 'Paginación de notificaciones inválida.');
    }

    final response = await api.requestJson(
      'GET',
      '/api/notifications',
      queryParameters: {'page': '$page', 'size': '$size'},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiFailure(502, 'El backend devolvió un buzón inválido.');
    }

    try {
      return ReaderNotificationPage.fromJson(response);
    } on FormatException {
      throw const ApiFailure(502, 'El backend devolvió un buzón inválido.');
    } on TypeError {
      throw const ApiFailure(502, 'El backend devolvió un buzón inválido.');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await api.requestJson(
      'GET',
      '/api/notifications/unread-count',
    );

    if (response is Map<String, dynamic>) {
      final count = response['count'];
      if (count is int && count >= 0) return count;
    }

    throw const ApiFailure(
      502,
      'El backend devolvió un contador de notificaciones inválido.',
    );
  }

  @override
  Future<ReaderNotification> markRead(int notificationId) async {
    if (notificationId <= 0) {
      throw const ApiFailure(400, 'Notificación inválida.');
    }

    final response = await api.requestJson(
      'PATCH',
      '/api/notifications/$notificationId/read',
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiFailure(
        502,
        'El backend devolvió una notificación inválida.',
      );
    }

    try {
      return ReaderNotification.fromJson(response);
    } on FormatException {
      throw const ApiFailure(
        502,
        'El backend devolvió una notificación inválida.',
      );
    } on TypeError {
      throw const ApiFailure(
        502,
        'El backend devolvió una notificación inválida.',
      );
    }
  }
}
