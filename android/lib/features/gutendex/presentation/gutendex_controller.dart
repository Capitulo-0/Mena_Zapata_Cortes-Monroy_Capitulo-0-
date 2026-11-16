import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/gutendex_repository.dart';
import '../models/gutendex_models.dart';
import 'gutendex_page_cache.dart';

class GutendexController extends ChangeNotifier {
  GutendexController(this.repository, {
    this.language = GutendexLanguage.spanish,
    GutendexPageCache? cache,
  }) : _cache = cache ?? GutendexPageCache();
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
  final GutendexPageCache _cache;
  final _pending = <GutendexPageKey, Future<GutendexPage>>{};
  Future<void>? _searchTask;
  GutendexPageKey? _searchKey;
  bool fromSessionCache = false;

  /// Invalidates pending results immediately, before the UI debounce expires.
  void prepare({String? query, GutendexLanguage? language}) {
    if (_closed) return;
    final nextQuery = (query ?? this.query).trim();
    final nextLanguage = language ?? this.language;
    if (nextQuery == this.query && nextLanguage == this.language) return;
    _generation++;
    this.query = nextQuery;
    this.language = nextLanguage;
    _searchTask = null;
    _searchKey = null;
    fromSessionCache = false;
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

  Future<void> search({String? query, GutendexLanguage? language,
    bool refresh = false}) {
    if (_closed) return Future<void>.value();
    prepare(query: query, language: language);
    final key = (query: this.query, language: this.language, page: null as Uri?);
    if (loading && _searchKey == key && _searchTask != null) return _searchTask!;
    final cached = refresh ? null : _cache.read(key);
    if (cached != null && hasSearched && error == null) return Future<void>.value();
    final generation = ++_generation;
    loadingMore = false;
    moreError = null;
    error = null;
    if (cached != null) {
      _applyFirst(cached);
      fromSessionCache = true;
      loading = false;
      notifyListeners();
      return Future<void>.value();
    }
    // A first-page refresh invalidates pending additional pages of this query.
    // Their callers still settle, but their generations cannot change the UI.
    _pending.removeWhere((page, _) => page.query == key.query &&
      page.language == key.language && page.page != null);
    loading = true;
    final completion = Completer<void>();
    _searchTask = completion.future;
    _searchKey = key;
    notifyListeners();
    unawaited(_search(key, generation, completion));
    return completion.future;
  }

  Future<GutendexPage> _request(GutendexPageKey key) {
    final pending = _pending[key];
    if (pending != null) return pending;
    late final Future<GutendexPage> task;
    task = Future.sync(() => repository.list(
      query: key.query, language: key.language, next: key.page)).whenComplete(() {
        if (identical(_pending[key], task)) _pending.remove(key);
      });
    _pending[key] = task;
    return task;
  }

  void _applyFirst(GutendexPage page) {
    items = _deduplicate(page.results);
    count = page.count;
    next = page.next;
    hasSearched = true;
    _visited.clear();
  }

  Future<void> _search(GutendexPageKey key, int generation, Completer<void> completion) async {
    try {
      final page = await _request(key);
      if (_closed || generation != _generation) return;
      // Never combine cached additional pages with a newly fetched first page.
      _cache.invalidate(key.query, key.language);
      _cache.put(key, page);
      _applyFirst(page);
      fromSessionCache = false;
    } catch (e) {
      if (_closed || generation != _generation) return;
      error = _message(e);
    } finally {
      if (!_closed && generation == _generation) {
        loading = false;
        _searchTask = null;
        _searchKey = null;
        notifyListeners();
      }
      completion.complete();
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
      final key = (query: query, language: language, page: target as Uri?);
      final cached = _cache.read(key);
      final page = cached ?? await _request(key);
      if (_closed || generation != _generation) return;
      if (cached == null) _cache.put(key, page);
      if (cached != null) fromSessionCache = true;
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
    _cache.clear();
    _pending.clear();
    super.dispose();
  }
}
