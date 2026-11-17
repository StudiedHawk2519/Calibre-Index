import 'package:calibre_carte/models/books.dart';

int compareBooks(
  Books first,
  Books second, {
  required String sortOption,
  required String sortDirection,
}) {
  final authorComparison = (first.author_sort ?? '')
      .toLowerCase()
      .compareTo((second.author_sort ?? '').toLowerCase());
  final titleComparison = (first.title ?? '')
      .toLowerCase()
      .compareTo((second.title ?? '').toLowerCase());
  final primaryComparison =
      sortOption == 'author' ? authorComparison : titleComparison;
  if (primaryComparison != 0) {
    return sortDirection == 'desc' ? -primaryComparison : primaryComparison;
  }

  if (sortOption == 'author') {
    final seriesComparison =
        (first.series ?? '').toLowerCase().compareTo((second.series ?? '').toLowerCase());
    if (seriesComparison != 0) return seriesComparison;

    final seriesIndexComparison =
        (first.series_index ?? 0).compareTo(second.series_index ?? 0);
    if (seriesIndexComparison != 0) return seriesIndexComparison;
  }

  return titleComparison;
}
