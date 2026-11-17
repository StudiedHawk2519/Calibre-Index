import 'package:calibre_carte/models/books.dart';

bool matchesBookSearch(
  Books book, {
  required String query,
  required Map<int, List<String>> tagsByBookId,
}) {
  final normalizedQuery = query.toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  return (book.title ?? '').toLowerCase().contains(normalizedQuery) ||
      (book.author_sort ?? '').toLowerCase().contains(normalizedQuery) ||
      (tagsByBookId[book.id] ?? const <String>[])
          .any((tag) => tag.toLowerCase().contains(normalizedQuery));
}
