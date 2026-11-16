import 'package:calibre_carte/models/tags.dart';
import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

class TagsProvider {
  static String tableName = 'Tags';

  static Future<Map<int, List<String>>> getTagNamesByBookIds(
    Iterable<int> bookIds,
  ) async {
    final ids = bookIds.toSet().toList();
    if (ids.isEmpty) return {};

    final Database db = (await DatabaseHelper.instance.db)!;
    final result = <int, List<String>>{};
    const batchSize = 900;

    for (var start = 0; start < ids.length; start += batchSize) {
      final end =
          (start + batchSize < ids.length) ? start + batchSize : ids.length;
      final batch = ids.sublist(start, end);
      final placeholders = List.filled(batch.length, '?').join(', ');
      final rows = await db.rawQuery(
        'SELECT books_tags_link.book AS book_id, Tags.name AS tag_name '
        'FROM books_tags_link '
        'INNER JOIN Tags ON Tags.id = books_tags_link.tag '
        'WHERE books_tags_link.book IN ($placeholders)',
        batch,
      );

      for (final row in rows) {
        final bookId = (row['book_id'] as num).toInt();
        final tagName = row['tag_name'] as String?;
        if (tagName == null || tagName.isEmpty) continue;
        result.putIfAbsent(bookId, () => []).add(tagName);
      }
    }

    return result;
  }

  static Future<Tags> getFirstTag() async {
    Database db = (await DatabaseHelper.instance.db)!;
    List<Map> maps = await db.query(tableName);
    return Tags.fromMapObject(maps.first as Map<String, dynamic>);
  }

  static Future<Tags?> getTagByID(int id, cols) async {
    Database db = (await DatabaseHelper.instance.db)!;
    List<Map> maps = await db.query(tableName,
        columns: cols ? cols : Tags.columns,
        where: '${Tags.columns[0]} = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Tags.fromMapObject(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  static Future<List<Tags>> getAllTags() async {
    Database db = (await DatabaseHelper.instance.db)!;
    List<Map> maps = await db.query(tableName);
    return maps.map((m) {
      return Tags.fromMapObject(m as Map<String, dynamic>);
    }).toList();
  }
}
