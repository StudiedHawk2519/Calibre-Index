import 'package:calibre_carte/helpers/book_sort.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('author sort groups series and keeps series order ascending', () {
    final books = [
      Books(
        title: 'Book Two',
        author_sort: 'Same Author',
        series: 'Example',
        series_index: 2,
      ),
      Books(
        title: 'Another Series',
        author_sort: 'Same Author',
        series: 'Other',
        series_index: 1,
      ),
      Books(
        title: 'Book One',
        author_sort: 'Same Author',
        series: 'Example',
        series_index: 1,
      ),
    ];

    books.sort(
      (a, b) => compareBooks(
        a,
        b,
        sortOption: 'author',
        sortDirection: 'desc',
      ),
    );

    expect(books.map((book) => book.title), [
      'Book One',
      'Book Two',
      'Another Series',
    ]);
  });
}
