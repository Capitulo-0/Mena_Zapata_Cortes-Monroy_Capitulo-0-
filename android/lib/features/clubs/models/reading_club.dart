class ReadingClub {
  const ReadingClub({
    required this.id,
    required this.name,
    required this.members,
    required this.book,
    required this.date,
    required this.description,
    required this.modality,
    this.organizerUserId,
    this.organizerUsername,
    this.meetingDate,
    this.meetingTime,
    this.meetingPlace,
    this.instagram,
    this.facebook,
    this.xHandle,
    this.joined = false,
    this.status = 'ACTIVE',
  });

  // Campos originales: se conservan para no romper Home y Perfil.
  final int id;
  final String name;
  final int members;
  final String book;
  final String date;
  final String description;
  final String modality;

  // Información real del backend.
  final int? organizerUserId;
  final String? organizerUsername;
  final String? meetingDate;
  final String? meetingTime;
  final String? meetingPlace;

  // Redes sociales opcionales.
  final String? instagram;
  final String? facebook;
  final String? xHandle;

  // Estado real de membresía y del club.
  final bool joined;
  final String status;

  factory ReadingClub.fromJson(Map<String, dynamic> json) {
    final meetingDate = json['meetingDate'] as String;
    final meetingTime = json['meetingTime'] as String;

    return ReadingClub(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      members: (json['membersCount'] as num).toInt(),
      book: '',
      date: '$meetingDate · $meetingTime',
      description: json['description'] as String,
      modality: json['modality'] as String,
      organizerUserId: (json['organizerUserId'] as num).toInt(),
      organizerUsername: json['organizerUsername'] as String,
      meetingDate: meetingDate,
      meetingTime: meetingTime,
      meetingPlace: json['meetingPlace'] as String?,
      instagram: json['instagram'] as String?,
      facebook: json['facebook'] as String?,
      xHandle: json['xHandle'] as String?,
      joined: json['joined'] as bool,
      status: json['status'] as String,
    );
  }
}
