import '../../../core/network/api_client.dart';

enum AdminVerificationStatus { pending, approved, rejected }

class AdminVerification {
  const AdminVerification({
    required this.id,
    required this.userId,
    required this.representativeName,
    required this.organizationName,
    required this.city,
    required this.contactEmail,
    required this.contactPhone,
    required this.organizationDescription,
    required this.status,
    required this.createdAt,
    this.organizationRut,
    this.publicAddress,
    this.socialUrl,
    this.reviewedBy,
    this.reviewReason,
    this.reviewedAt,
  });

  final int id;
  final int userId;
  final String representativeName;
  final String organizationName;
  final String? organizationRut;
  final String city;
  final String? publicAddress;
  final String contactEmail;
  final String contactPhone;
  final String? socialUrl;
  final String organizationDescription;
  final AdminVerificationStatus status;
  final int? reviewedBy;
  final String? reviewReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  factory AdminVerification.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'PENDING' => AdminVerificationStatus.pending,
      'APPROVED' => AdminVerificationStatus.approved,
      'REJECTED' => AdminVerificationStatus.rejected,
      _ => throw const FormatException(
        'Estado de verificación administrativa inválido',
      ),
    };

    return AdminVerification(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      representativeName: json['representativeName'] as String,
      organizationName: json['organizationName'] as String,
      organizationRut: json['organizationRut'] as String?,
      city: json['city'] as String,
      publicAddress: json['publicAddress'] as String?,
      contactEmail: json['contactEmail'] as String,
      contactPhone: json['contactPhone'] as String,
      socialUrl: json['socialUrl'] as String?,
      organizationDescription: json['organizationDescription'] as String,
      status: status,
      reviewedBy: (json['reviewedBy'] as num?)?.toInt(),
      reviewReason: json['reviewReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
    );
  }
}

abstract class AdminVerificationRepository {
  Future<bool> isAdmin();

  Future<List<AdminVerification>> pendingRequests();

  Future<AdminVerification> approve(int requestId);

  Future<AdminVerification> reject(int requestId, {required String reason});
}

class ApiAdminVerificationRepository implements AdminVerificationRepository {
  const ApiAdminVerificationRepository(this.api);

  final ApiClient api;

  @override
  Future<bool> isAdmin() async {
    try {
      final result = await api.requestJson('GET', '/api/admin/me');

      if (result is! Map<String, dynamic>) {
        throw const FormatException(
          'Respuesta de autorización administrativa inválida',
        );
      }

      return result['role'] == 'ADMIN';
    } on ApiFailure catch (error) {
      if (error.statusCode == 403) {
        return false;
      }

      rethrow;
    }
  }

  @override
  Future<List<AdminVerification>> pendingRequests() async {
    final result = await api.requestJson('GET', '/api/admin/verifications');

    if (result is! List) {
      throw const FormatException('La lista de solicitudes es inválida');
    }

    return result.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Una solicitud administrativa es inválida');
      }

      return AdminVerification.fromJson(item);
    }).toList();
  }

  @override
  Future<AdminVerification> approve(int requestId) async {
    final result = await api.request(
      'POST',
      '/api/admin/verifications/$requestId/approve',
    );

    return AdminVerification.fromJson(result);
  }

  @override
  Future<AdminVerification> reject(
    int requestId, {
    required String reason,
  }) async {
    final cleanReason = reason.trim();

    if (cleanReason.isEmpty || cleanReason.length > 1000) {
      throw ArgumentError('El motivo debe tener entre 1 y 1000 caracteres');
    }

    final result = await api.request(
      'POST',
      '/api/admin/verifications/$requestId/reject',
      body: {'reason': cleanReason},
    );

    return AdminVerification.fromJson(result);
  }
}
