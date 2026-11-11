import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/domain/auth_repository.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.statusCode, this.message);
  final int statusCode;
  final String message;
  factory ApiFailure.forStatus(int code) => ApiFailure(code, switch (code) {
    401 => 'La sesión no es válida o expiró. Vuelve a iniciar sesión.',
    403 => 'Tu cuenta no tiene permiso para esta operación.',
    404 => 'No se encontró el usuario o recurso solicitado.',
    409 => 'El correo ya está asociado a una cuenta interna. Se necesita una vinculación segura.',
    400 || 422 => 'Los datos enviados no son válidos. Revisa los campos e inténtalo de nuevo.',
    503 => 'El backend o su servicio de identidad no está disponible. Tu sesión Firebase se conserva.',
    _ => 'No pudimos completar la operación con el backend.',
  });
}

class ApiClient {
  ApiClient({
    required this.auth,
    this.baseUrl = const String.fromEnvironment('API_BASE_URL'),
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    bool allowInsecureHttp = kDebugMode,
  }) : _http = client ?? http.Client(),
       _allowHttp = allowInsecureHttp;
  final AuthRepository auth;
  final String baseUrl;
  final http.Client _http;
  final Duration timeout;
  final bool _allowHttp;

  Uri _uri(String path) {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.scheme != 'https' && !(_allowHttp && base.scheme == 'http'))) {
      throw const ApiFailure(
        0,
        'Falta una API_BASE_URL válida sin credenciales. Configura HTTPS para la API.',
      );
    }
    if (!path.startsWith('/api/') ||
        path.contains('..') ||
        path.contains('?') ||
        path.contains('#')) {
      throw const ApiFailure(0, 'La ruta de la API no es válida.');
    }
    return base.replace(
      path: '${base.path.replaceFirst(RegExp(r"/+$"), "")}$path',
    );
  }

  Future<Object?> requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? expectedUid,
  }) async {
    final uri = _uri(path);
    final uid = auth.currentUser?.uid;
    if (uid == null || (expectedUid != null && uid != expectedUid)) {
      throw ApiFailure.forStatus(401);
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await auth.getIdToken(forceRefresh: attempt == 1);
      if (auth.currentUser?.uid != uid || token == null || token.isEmpty) {
        throw ApiFailure.forStatus(401);
      }
      http.Response response;
      try {
        final request = http.Request(method, uri)
          ..followRedirects = false
          ..headers['Accept'] = 'application/json'
          ..headers['Authorization'] = 'Bearer $token';
        if (body != null) {
          request.headers['Content-Type'] = 'application/json';
          request.body = jsonEncode(body);
        }
        response = await _http
            .send(request)
            .then(http.Response.fromStream)
            .timeout(timeout);
      } on TimeoutException {
        throw const ApiFailure(
          503,
          'El backend tardó demasiado en responder. Puedes reintentar.',
        );
      } on http.ClientException {
        throw const ApiFailure(
          503,
          'No pudimos conectar con el backend. Revisa tu conexión y la dirección configurada.',
        );
      }
      if (auth.currentUser?.uid != uid) throw ApiFailure.forStatus(401);
      if (response.statusCode == 401 && attempt == 0) continue;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiFailure.forStatus(response.statusCode);
      }
      if (response.statusCode == 204) return null;
      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> || data is List<dynamic>) return data;
      } on FormatException {
        /* No response body or exception details are exposed. */
      }
      throw const ApiFailure(
        502,
        'El backend devolvió una respuesta no válida.',
      );
    }
    throw ApiFailure.forStatus(401);
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? expectedUid,
  }) async {
    final result = await requestJson(
      method,
      path,
      body: body,
      expectedUid: expectedUid,
    );
    if (result is Map<String, dynamic>) return result;
    throw const ApiFailure(502, 'El backend devolvió una respuesta no válida.');
  }

  void close() => _http.close();
}
