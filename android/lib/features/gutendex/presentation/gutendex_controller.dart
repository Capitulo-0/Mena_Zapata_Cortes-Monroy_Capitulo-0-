import 'package:flutter/foundation.dart';

import '../data/gutendex_repository.dart';
import '../models/gutendex_models.dart';

class GutendexController extends ChangeNotifier {
  GutendexController(this.repository, {
    this.language = GutendexLanguage.spanish,
  });
  final GutendexRepository repository;
  GutendexLanguage language;
  String query = '';
  List<GutendexBook> items = const [];
  int? count;
  Uri? next;
  bool loading = false;
  bool loadingMore = false;
  bool hasSearched = false;
  String? error;
  String? moreError;
  int _generation = 0;
  bool _closed = false;
  final Set<Uri> _visited = {};

  /// Invalidates pending results immediately, before the UI debounce expires.
  void prepare({String? query, GutendexLanguage? language}) {
    if (_closed) return;
    _generation++;
    this.query = (query ?? this.query).trim();
    this.language = language ?? this.language;
    items = const [];
    count = null;
    next = null;
    _visited.clear();
    loading = false;
    loadingMore = false;
    hasSearched = false;
    error = null;
    moreError = null;
    notifyListeners();
  }

  Future<void> search({String? query, GutendexLanguage? language}) async {
    if (_closed) return;
    prepare(query: query, language: language);
    final generation = _generation;
    loading = true;
    notifyListeners();
    try {
      final page = await repository.list(query: this.query, language: this.language);
      if (_closed || generation != _generation) return;
      items = _deduplicate(page.results);
      count = page.count;
      next = page.next;
      hasSearched = true;
    } catch (e) {
      if (_closed || generation != _generation) return;
      error = _message(e);
    } finally {
      if (!_closed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> more() async {
    final target = next;
    if (_closed || loading || loadingMore || target == null) return;
    if (_visited.contains(target)) {
      next = null;
      moreError = 'Gutendex repitió una página. No se solicitarán más resultados.';
      notifyListeners();
      return;
    }
    final generation = _generation;
    loadingMore = true;
    moreError = null;
    notifyListeners();
    try {
      final page = await repository.list(query: query, language: language, next: target);
      if (_closed || generation != _generation) return;
      _visited.add(target);
      items = _deduplicate([...items, ...page.results]);
      count = page.count ?? count;
      next = page.next;
      if (next != null && _visited.contains(next)) {
        next = null;
        moreError = 'Gutendex repitió una página. No se solicitarán más resultados.';
      }
    } catch (e) {
      if (_closed || generation != _generation) return;
      moreError = _message(e);
    } finally {
      if (!_closed && generation == _generation) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  List<GutendexBook> _deduplicate(List<GutendexBook> books) {
    final ids = <int>{};
    return List.unmodifiable(books.where((book) => ids.add(book.id)));
  }

  String _message(Object e) => e is GutendexFailure ? e.message
      : 'No pudimos consultar Gutendex. Inténtalo nuevamente.';

  @override
  void dispose() {
    _closed = true;
    _generation++;
    super.dispose();
  }
}
