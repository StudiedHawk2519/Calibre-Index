import 'package:calibre_carte/helpers/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class SeriesProvider {
  static Future<Map<int, String>> getNamesByBookIds(
    Iterable<int> bookIds,
  ) async {
    final ids = bookIds.toSet().toList(growable: false);
    if (ids.isEmpty) return {};

    final Database database = (await DatabaseHelper.instance.db)!;
    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name IN ('books_series_link', 'series')",
    );
    if (tables.length < 2) return {};

    final result = <int, String>{};
    const batchSize = 900;
    for (var start = 0; start < ids.length; start += batchSize) {
      final end =
          (start + batchSize < ids.length) ? start + batchSize : ids.length;
      final batch = ids.sublist(start, end);
      final placeholders = List.filled(batch.length, '?').join(', ');
      final rows = await database.rawQuery(
        'SELECT books_series_link.book AS book_id, series.name AS series_name '
        'FROM books_series_link '
        'INNER JOIN series ON series.id = books_series_link.series '
        'WHERE books_series_link.book IN ($placeholders)',
        batch,
      );
      for (final row in rows) {
        final bookId = (row['book_id'] as num).toInt();
        final name = row['series_name'] as String?;
        if (name != null && name.isNotEmpty) result[bookId] = name;
      }
    }

    return result;
  }
}
