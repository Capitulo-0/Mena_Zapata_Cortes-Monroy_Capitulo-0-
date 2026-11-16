import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/gutendex/models/gutendex_models.dart';

import 'support/gutendex_fakes.dart';

void main() {
  test('preserves multiple authors, translators and bibliographic metadata', () {
    final book = fixtureBook(1);
    expect(book.authors.map((p) => p.name), ['Autor Uno', 'Autor Dos']);
    expect(book.authors.first.birthYear, 1800);
    expect(book.authors.first.deathYear, isNull);
    expect(book.translators.single.name, 'Traductor fixture');
    expect(book.languages, ['es']);
    expect(book.subjects, ['Literatura']);
    expect(book.summaries, ['Sinopsis fixture.']);
    expect(book.copyright, false);
    expect(book.downloadCount, 12);
    expect(book.readingFormats.map((f) => f.label), ['EPUB', 'HTML', 'Texto plano']);
  });

  test('missing and null fields do not invent metadata', () {
    final book = GutendexBook.fromJson({
      'id': 1, 'title': null, 'authors': null, 'formats': null,
      'languages': [], 'summaries': null, 'copyright': null,
    });
    expect(book.title, isNull);
    expect(book.authors, isEmpty);
    expect(book.cover, isNull);
    expect(book.summaries, isEmpty);
    expect(book.readingFormats, isEmpty);
    expect(book.copyright, isNull);
    expect(book.downloadCount, isNull);
  });

  test('incomplete formats, unsupported MIME and unsafe URLs are excluded', () {
    final book = GutendexBook.fromJson({'id': 1, 'formats': {
      'application/epub+zip': null,
      'text/html': 'https://evil.test/book.html',
      'text/plain': 'javascript:alert(1)',
      'application/octet-stream': 'https://www.gutenberg.org/book.bin',
      'image/jpeg': 'http://www.gutenberg.org/cover.jpg',
    }});
    expect(book.readingFormats, isEmpty);
    expect(book.cover, isNull);
  });

  for (final url in [
    'http://www.gutenberg.org/a', 'javascript:alert(1)', 'data:text/plain,abc',
    '//www.gutenberg.org/a', 'https://www.gutenberg.org.evil.test/a',
    'https://user:pass@www.gutenberg.org/a', 'https://www.gutenberg.org:444/a',
    'https://evil.test/a', 'https://www.gutenberg.org/a b',
    r'https://www.gutenberg.org\@evil.test/a',
  ]) {
    test('rejects unsafe resource URL: $url', () {
      expect(gutenbergResource(url), isNull);
    });
  }

  test('safe cover and MIME parameters retain original values', () {
    final json = bookJson(2);
    (json['formats'] as Map)['image/jpeg'] =
        'https://www.gutenberg.org/cache/epub/2/pg2.cover.medium.jpg';
    final book = GutendexBook.fromJson(json);
    expect(book.cover!.host, 'www.gutenberg.org');
    expect(book.readingFormats[1].mimeType, 'text/html; charset=utf-8');
    expect(book.source.toString(), 'https://www.gutenberg.org/ebooks/2');
  });

  test('missing identity is malformed, not a fabricated book', () {
    expect(() => GutendexBook.fromJson({}), throwsFormatException);
  });
}
