import 'package:calibre_carte/models/book_display_group.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('books without a series remain separate and in input order', () {
    final books = [
      Books(title: 'First', author_sort: 'Author'),
      Books(title: 'Second', author_sort: 'Author'),
    ];

    final groups = groupBooksBySeries(books);

    expect(
        groups.map((group) => group.books.single.title), ['First', 'Second']);
    expect(groups.every((group) => !group.isSeries), isTrue);
  });
}
