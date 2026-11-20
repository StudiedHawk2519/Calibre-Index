import 'package:calibre_carte/helpers/cache_invalidator.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

class BooksProvider {
  static String tableName = 'Books';

  static Future<Books> getFirstBook() async {
    Database db = (await DatabaseHelper.instance.db)!;
    List<Map> maps = await db.query(tableName);
    return Books.fromMapObject(maps.first as Map<String, dynamic>);
  }

  static Future<Books?> getBookByID(int? id, cols) async {
    Database db = (await DatabaseHelper.instance.db)!;
    List<Map> maps = await db.query(tableName,
//        columns: Books.columns,
        where: '${Books.columns[0]} = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
//      print(Books.fromMapObject(maps.first).title);
      return Books.fromMapObject(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  static Future<List<Books>> getAllBooks(bool refresh) async {
    Database? db = await DatabaseHelper.instance.db;

    if (refresh) {
      db = null;
      await CacheInvalidator.invalidateDatabaseCache();
      db = await DatabaseHelper.instance.db;
    }

    List<Map> maps = await db!.query(tableName);
    return maps.map((m) {
      return Books.fromMapObject(m as Map<String, dynamic>);
    }).toList();
  }

  static Future<List<String>> getLibraryTextEntries() async {
    final Database database = (await DatabaseHelper.instance.db)!;
    final rows = await database.rawQuery(
      'SELECT Books.title AS title, '
      'GROUP_CONCAT(Authors.name, ", ") AS author_names '
      'FROM Books '
      'LEFT JOIN books_authors_link '
      'ON books_authors_link.book = Books.id '
      'LEFT JOIN Authors ON Authors.id = books_authors_link.author '
      'GROUP BY Books.id '
      'ORDER BY COALESCE(Books.sort, Books.title) COLLATE NOCASE, '
      'Books.title COLLATE NOCASE',
    );
    return rows.map((row) {
      final title = row['title']?.toString().trim();
      final authors = row['author_names']?.toString().trim();
      if (authors == null || authors.isEmpty) return title ?? 'Untitled';
      return '${title?.isNotEmpty == true ? title : 'Untitled'} - $authors';
    }).toList(growable: false);
  }
}
