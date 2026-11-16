import 'package:calibre_carte/models/authors.dart';
import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

class AuthorsProvider {
  static String tableName = 'Authors';

  static Future<Authors> getFirstAuthor() async {
    Database db = (await DatabaseHelper.instance.db)!;
    List<Map> maps = await db.query(tableName);
    return Authors.fromMapObject(maps.first as Map<String, dynamic>);
  }

  static Future<Authors?> getAuthorByID(int? id, cols) async {
    Database db = (await DatabaseHelper.instance.db)!;
    List<Map> maps = await db
        .query(tableName, where: '${Authors.columns[0]} = ?', whereArgs: [id]);
    if (maps.length > 0) {
      return Authors.fromMapObject(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  static Future<List<Authors>> getAllAuthors() async {
    Database db = (await DatabaseHelper.instance.db)!;
    List<Map> maps = await db.query(tableName);
    return maps.map((m) {
      return Authors.fromMapObject(m as Map<String, dynamic>);
    }).toList();
  }
}
