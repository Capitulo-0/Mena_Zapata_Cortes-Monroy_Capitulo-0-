import 'dart:async';

import 'package:android/features/gutendex/data/gutendex_repository.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';

Map<String, dynamic> bookJson(int id, {String language = 'es'}) => {
  'id': id,
  'title': 'Obra fixture $id',
  'authors': [
    {'name': 'Autor Uno', 'birth_year': 1800, 'death_year': null},
    {'name': 'Autor Dos', 'birth_year': null, 'death_year': 1900},
  ],
  'translators': [{'name': 'Traductor fixture'}],
  'languages': [language],
  'subjects': ['Literatura'],
  'summaries': ['Sinopsis fixture.'],
  'copyright': false,
  'download_count': 12,
  'formats': {
    'application/epub+zip': 'https://www.gutenberg.org/ebooks/$id.epub.images',
    'text/html; charset=utf-8': 'https://www.gutenberg.org/files/$id/$id-h.htm',
    'text/plain; charset=utf-8': 'https://www.gutenberg.org/files/$id/$id.txt',
  },
};

GutendexBook fixtureBook(int id, {String language = 'es'}) =>
    GutendexBook.fromJson(bookJson(id, language: language));

Map<String, dynamic> pageJson({List<Map<String, dynamic>>? books,
  String? next, String? previous}) => {
  'count': books?.length ?? 1,
  'next': next,
  'previous': previous,
  'results': books ?? [bookJson(1)],
};

class FakeGutendexRepository implements GutendexRepository {
  final calls = <({String query, GutendexLanguage language, Uri? next,
    Completer<GutendexPage> result})>[];
  final details = <({int id, Completer<GutendexBook> result})>[];

  @override
  Future<GutendexPage> list({required String query,
    required GutendexLanguage language, Uri? next}) {
    final result = Completer<GutendexPage>();
    calls.add((query: query, language: language, next: next, result: result));
    return result.future;
  }

  @override
  Future<GutendexBook> detail(int id) {
    final result = Completer<GutendexBook>();
    details.add((id: id, result: result));
    return result.future;
  }
}
