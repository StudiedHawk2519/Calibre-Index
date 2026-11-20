import 'package:calibre_carte/models/books_authors_link.dart';
import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

class BooksAuthorsLinksProvider {
  static String tableName = 'books_authors_link';

  static Future<Map<int, List<String>>> getAuthorNamesByBookIds(
    Iterable<int> bookIds,
  ) async {
    final ids = bookIds.toSet().toList(growable: false);
    if (ids.isEmpty) return {};

    final Database database = (await DatabaseHelper.instance.db)!;
    final result = <int, List<String>>{};
    const batchSize = 900;
    for (var start = 0; start < ids.length; start += batchSize) {
      final end =
          (start + batchSize < ids.length) ? start + batchSize : ids.length;
      final batch = ids.sublist(start, end);
      final placeholders = List.filled(batch.length, '?').join(', ');
      final rows = await database.rawQuery(
        'SELECT books_authors_link.book AS book_id, Authors.name AS author_name '
        'FROM books_authors_link '
        'INNER JOIN Authors ON Authors.id = books_authors_link.author '
        'WHERE books_authors_link.book IN ($placeholders) '
        'ORDER BY books_authors_link.book, books_authors_link.rowid',
        batch,
      );
      for (final row in rows) {
        final bookId = (row['book_id'] as num).toInt();
        final authorName = row['author_name'] as String?;
        if (authorName == null || authorName.isEmpty) continue;
        result.putIfAbsent(bookId, () => []).add(authorName);
      }
    }
    return result;
  }

  static Future<BooksAuthorsLink> getFirstBookAuthorProvider() async {
    Database db = (await DatabaseHelper.instance.db)!;
    List<Map> maps = await db.query(tableName);
    return BooksAuthorsLink.fromMapObject(maps.first as Map<String, dynamic>);
  }

  static Future<List<BooksAuthorsLink>> getAuthorsByBookID(int? id) async {
    Database db = (await DatabaseHelper.instance.db)!;
    List<Map> maps = await db.query(tableName,
        where: '${BooksAuthorsLink.columns[1]} = ?', whereArgs: [id]);

    List<BooksAuthorsLink> bals = [];
    maps.forEach((mapObject) {
      BooksAuthorsLink x =
          BooksAuthorsLink.fromMapObject(mapObject as Map<String, dynamic>);
      bals.add(x);
    });

    return bals;
  }
}
