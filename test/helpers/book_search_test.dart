import 'package:calibre_carte/helpers/book_search.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tags = <int, List<String>>{
    1: ['Science Fiction', 'Space Opera'],
  };
  final book = Books(
    id: 1,
    title: 'The Long Way to a Small, Angry Planet',
    author_sort: 'Becky Chambers',
  );

  test('matches title and author case-insensitively', () {
    expect(
      matchesBookSearch(
        book,
        query: 'ANGRY PLANET',
        tagsByBookId: tags,
      ),
      isTrue,
    );
    expect(
      matchesBookSearch(
        book,
        query: 'becky',
        tagsByBookId: tags,
      ),
      isTrue,
    );
  });

  test("matches any of a book's tags and rejects unrelated queries", () {
    expect(
      matchesBookSearch(
        book,
        query: 'space',
        tagsByBookId: tags,
      ),
      isTrue,
    );
    expect(
      matchesBookSearch(
        book,
        query: 'history',
        tagsByBookId: tags,
      ),
      isFalse,
    );
  });
}
