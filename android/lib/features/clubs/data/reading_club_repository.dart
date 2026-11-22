import '../../../core/network/api_client.dart';
import '../models/reading_club.dart';

class CreateReadingClubForm {
  const CreateReadingClubForm({
    required this.name,
    required this.description,
    required this.meetingDate,
    required this.meetingTime,
    required this.modality,
    this.meetingPlace,
    this.instagram,
    this.facebook,
    this.xHandle,
  });

  final String name;
  final String description;
  final DateTime meetingDate;
  final String meetingTime;
  final String modality;
  final String? meetingPlace;
  final String? instagram;
  final String? facebook;
  final String? xHandle;

  Map<String, dynamic> toJson() {
    final date =
        '${meetingDate.year.toString().padLeft(4, '0')}-'
        '${meetingDate.month.toString().padLeft(2, '0')}-'
        '${meetingDate.day.toString().padLeft(2, '0')}';

    return {
      'name': name.trim(),
      'description': description.trim(),
      'meetingDate': date,
      'meetingTime': meetingTime,
      'modality': modality,
      'meetingPlace': _optional(meetingPlace),
      'instagram': _optional(instagram),
      'facebook': _optional(facebook),
      'xHandle': _optional(xHandle),
    };
  }

  String? _optional(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class ReadingClubPage {
  const ReadingClubPage({
    required this.clubs,
    required this.page,
    required this.totalPages,
    required this.totalElements,
    required this.last,
  });

  final List<ReadingClub> clubs;
  final int page;
  final int totalPages;
  final int totalElements;
  final bool last;

  factory ReadingClubPage.fromJson(Map<String, dynamic> json) {
    final content = json['content'];

    if (content is! List) {
      throw const FormatException('Listado de clubes inválido');
    }

    return ReadingClubPage(
      clubs: content.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Club inválido');
        }
        return ReadingClub.fromJson(item);
      }).toList(),
      page: (json['number'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      totalElements: (json['totalElements'] as num).toInt(),
      last: json['last'] as bool,
    );
  }
}

class ReadingClubRepository {
  const ReadingClubRepository(this.api);

  final ApiClient api;

  // Tres clubes más recientes para Home.
  Future<List<ReadingClub>> homeClubs() async {
    final result = await api.requestJson(
      'GET',
      '/api/clubs/home',
      publicRead: true,
    );

    return _parseClubs(result);
  }

  // Listado paginado para "Ver todos".
  Future<ReadingClubPage> allClubs({int page = 0, int size = 12}) async {
    final result = await api.requestJson(
      'GET',
      '/api/clubs',
      publicRead: true,
      queryParameters: {'page': '$page', 'size': '$size'},
    );

    if (result is! Map<String, dynamic>) {
      throw const FormatException('Paginación de clubes inválida');
    }

    return ReadingClubPage.fromJson(result);
  }

  // Detalle público de un club.
  Future<ReadingClub> clubDetail(int clubId) async {
    final result = await api.requestJson(
      'GET',
      '/api/clubs/$clubId',
      publicRead: true,
    );

    return _parseClub(result);
  }

  // Clubes del usuario autenticado.
  Future<List<ReadingClub>> myClubs() async {
    final result = await api.requestJson('GET', '/api/clubs/mine');

    return _parseClubs(result);
  }

  // Solo organizadores aprobados pueden crear clubes.
  Future<ReadingClub> createClub(CreateReadingClubForm form) async {
    final result = await api.request('POST', '/api/clubs', body: form.toJson());

    return ReadingClub.fromJson(result);
  }

  // Unirse a un club.
  Future<ReadingClub> joinClub(int clubId) async {
    final result = await api.request('POST', '/api/clubs/$clubId/join');

    return ReadingClub.fromJson(result);
  }

  // Abandonar un club.
  Future<ReadingClub> leaveClub(int clubId) async {
    final result = await api.request('DELETE', '/api/clubs/$clubId/membership');

    return ReadingClub.fromJson(result);
  }

  ReadingClub _parseClub(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de club inválida');
    }
    return ReadingClub.fromJson(value);
  }

  List<ReadingClub> _parseClubs(Object? value) {
    if (value is! List) {
      throw const FormatException('Listado de clubes inválido');
    }

    return value.map((item) => _parseClub(item)).toList();
  }
}
