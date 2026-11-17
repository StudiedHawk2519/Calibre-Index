import 'package:calibre_carte/models/books.dart';

class BookDisplayGroup {
  final String? seriesName;
  final String? author;
  final List<Books> books;

  const BookDisplayGroup({
    required this.seriesName,
    required this.author,
    required this.books,
  });

  bool get isSeries => seriesName != null;
}

List<BookDisplayGroup> groupBooksBySeries(List<Books> books) {
  final groups = <BookDisplayGroup>[];
  final seriesGroups = <String, BookDisplayGroup>{};

  for (final book in books) {
    final seriesName = book.series?.trim();
    final author = book.author_sort?.trim();
    if (seriesName == null || seriesName.isEmpty) {
      groups.add(
        BookDisplayGroup(
          seriesName: null,
          author: author,
          books: [book],
        ),
      );
      continue;
    }

    final key = '${author?.toLowerCase() ?? ''}\u0000${seriesName.toLowerCase()}';
    final group = seriesGroups.putIfAbsent(
      key,
      () {
        final newGroup = BookDisplayGroup(
        seriesName: seriesName,
        author: author,
        books: [],
      );
        groups.add(newGroup);
        return newGroup;
      },
    );
    group.books.add(book);
  }
  return groups;
}
