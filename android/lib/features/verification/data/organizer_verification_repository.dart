import '../../../core/network/api_client.dart';

enum OrganizerVerificationStatus { pending, approved, rejected }

class OrganizerVerification {
  const OrganizerVerification({
    required this.id,
    required this.organizationName,
    required this.status,
    required this.createdAt,
    this.reviewReason,
    this.reviewedAt,
  });

  final int id;
  final String organizationName;
  final OrganizerVerificationStatus status;
  final String? reviewReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  factory OrganizerVerification.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'PENDING' => OrganizerVerificationStatus.pending,
      'APPROVED' => OrganizerVerificationStatus.approved,
      'REJECTED' => OrganizerVerificationStatus.rejected,
      _ => throw const FormatException('Estado de verificación inválido'),
    };

    return OrganizerVerification(
      id: (json['id'] as num).toInt(),
      organizationName: json['organizationName'] as String,
      status: status,
      reviewReason: json['reviewReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
    );
  }
}

class OrganizerVerificationForm {
  const OrganizerVerificationForm({
    required this.representativeName,
    required this.organizationName,
    required this.city,
    required this.contactEmail,
    required this.contactPhone,
    required this.organizationDescription,
    this.organizationRut,
    this.publicAddress,
    this.socialUrl,
  });

  final String representativeName;
  final String organizationName;
  final String? organizationRut;
  final String city;
  final String? publicAddress;
  final String contactEmail;
  final String contactPhone;
  final String? socialUrl;
  final String organizationDescription;

  Map<String, dynamic> toJson() => {
    'representativeName': representativeName,
    'organizationName': organizationName,
    'organizationRut': organizationRut,
    'city': city,
    'publicAddress': publicAddress,
    'contactEmail': contactEmail,
    'contactPhone': contactPhone,
    'socialUrl': socialUrl,
    'organizationDescription': organizationDescription,
  };
}

abstract class OrganizerVerificationRepository {
  Future<OrganizerVerification?> myStatus();

  Future<OrganizerVerification> submit(OrganizerVerificationForm form);
}

class ApiOrganizerVerificationRepository
    implements OrganizerVerificationRepository {
  const ApiOrganizerVerificationRepository(this.api);

  final ApiClient api;

  @override
  Future<OrganizerVerification?> myStatus() async {
    final result = await api.requestJson(
      'GET',
      '/api/organizer-verification/me',
    );

    if (result == null) {
      return null;
    }

    if (result is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de verificación inválida');
    }

    return OrganizerVerification.fromJson(result);
  }

  @override
  Future<OrganizerVerification> submit(OrganizerVerificationForm form) async {
    final result = await api.request(
      'POST',
      '/api/organizer-verification',
      body: form.toJson(),
    );

    return OrganizerVerification.fromJson(result);
  }
}
