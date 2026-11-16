import 'package:calibre_carte/models/books.dart';

bool matchesBookSearch(
  Books book, {
  required String? searchFilter,
  required String query,
  required Map<int, List<String>> tagsByBookId,
}) {
  final normalizedQuery = query.toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  switch (searchFilter) {
    case 'author':
      return (book.author_sort ?? '').toLowerCase().contains(normalizedQuery);
    case 'tags':
      return (tagsByBookId[book.id] ?? const <String>[])
          .any((tag) => tag.toLowerCase().contains(normalizedQuery));
    case 'title':
    default:
      return (book.title ?? '').toLowerCase().contains(normalizedQuery);
  }
}
