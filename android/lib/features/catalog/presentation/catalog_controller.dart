import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/catalog_repository.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this.repository);
  final CatalogRepository repository;
  List<Map<String, dynamic>> items = [];
  bool loading = false;
  String? error;
  int? next;
  int _generation = 0;
  bool _closed = false;
  String _query = '', _mode = 'all';
  Future<void> search(
    String query, {
    String mode = 'all',
    bool more = false,
  }) async {
    if (_closed || (more && (loading || next == null))) return;
    if (query.trim().isEmpty) {
      clear();
      return;
    }
    final generation = ++_generation;
    _query = query;
    _mode = mode;
    final start = more ? next! : 0;
    loading = true;
    error = null;
    if (!more) {
      items = [];
      next = null;
    }
    notifyListeners();
    try {
      final page = await repository.search(query, mode: mode, start: start);
      if (_closed || generation != _generation) return;
      final seen = <String>{};
      items = [
        ...(more ? items : <Map<String, dynamic>>[]),
        ...page.items,
      ].where((book) => seen.add(book['googleVolumeId'] as String)).toList();
      next = page.nextStartIndex;
    } catch (e) {
      if (_closed || generation != _generation) return;
      error = e is ApiFailure
          ? e.message
          : 'No se pudo consultar Google Books. Reintenta.';
    } finally {
      if (!_closed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() => search(_query, mode: _mode);
  Future<void> more() => search(_query, mode: _mode, more: true);
  void clear() {
    ++_generation;
    items = [];
    next = null;
    error = null;
    loading = false;
    if (!_closed) notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    ++_generation;
    super.dispose();
  }
}
