import 'package:calibre_carte/helpers/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class BookMetadataProvider {
  static const _bookFieldLabels = <String, String>{
    'title': 'Title',
    'sort': 'Title sort',
    'timestamp': 'Date added',
    'pubdate': 'Publication date',
    'series_index': 'Series number',
    'author_sort': 'Author sort',
    'isbn': 'ISBN',
    'lccn': 'LCCN',
    'uuid': 'UUID',
    'has_cover': 'Has cover',
    'last_modified': 'Last modified',
  };

  static Future<Map<String, String>> getMetadataForBook(int bookId) async {
    final database = (await DatabaseHelper.instance.db)!;
    final result = <String, String>{};

    final bookRows = await database.query(
      'Books',
      where: 'id = ?',
      whereArgs: [bookId],
    );
    if (bookRows.isEmpty) return result;

    final book = bookRows.first;
    for (final entry in book.entries) {
      if (entry.key == 'id' || entry.key == 'path') continue;
      final value = _displayValue(entry.value);
      if (value.isEmpty) continue;
      result[_bookFieldLabels[entry.key] ?? _humanize(entry.key)] = value;
    }

    await _addRelation(
      database,
      result,
      'Authors',
      'books_authors_link',
      'author',
      'name',
      bookId,
    );
    await _addRelation(
      database,
      result,
      'Tags',
      'books_tags_link',
      'tag',
      'name',
      bookId,
    );
    await _addRelation(
      database,
      result,
      'Series',
      'books_series_link',
      'series',
      'name',
      bookId,
    );
    await _addRelation(
      database,
      result,
      'Publishers',
      'books_publishers_link',
      'publisher',
      'name',
      bookId,
    );
    await _addRelation(
      database,
      result,
      'Ratings',
      'books_ratings_link',
      'rating',
      'rating',
      bookId,
    );
    await _addRelation(
      database,
      result,
      'languages',
      'books_languages_link',
      'lang_code',
      'lang_code',
      bookId,
    );

    final formatRows = await database.query(
      'data',
      columns: ['format'],
      where: 'book = ?',
      whereArgs: [bookId],
      orderBy: 'format COLLATE NOCASE',
    );
    if (formatRows.isNotEmpty) {
      result['Available formats'] =
          formatRows.map((row) => row['format'].toString()).join(', ');
    }
    final sizeRows = await database.rawQuery(
      'SELECT SUM(uncompressed_size) AS total_size FROM data WHERE book = ?',
      [bookId],
    );
    final totalSize = sizeRows.first['total_size'];
    if (totalSize is num && totalSize > 0) {
      result['Total file size'] = _formatBytes(totalSize.toInt());
    }

    final pagesTable = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name = 'books_pages_link'",
    );
    if (pagesTable.isNotEmpty) {
      final pageRows = await database.query(
        'books_pages_link',
        columns: ['pages'],
        where: 'book = ?',
        whereArgs: [bookId],
      );
      if (pageRows.isNotEmpty) {
        final pages = pageRows.first['pages'];
        if (pages is num && pages > 0) {
          result['Page count'] = pages.toString();
        }
      }
    }

    final identifierRows = await database.query(
      'identifiers',
      columns: ['type', 'val'],
      where: 'book = ?',
      whereArgs: [bookId],
      orderBy: 'type COLLATE NOCASE',
    );
    for (final row in identifierRows) {
      final type = row['type']?.toString();
      final value = row['val']?.toString();
      if (type != null && value != null && value.isNotEmpty) {
        result['Identifier (${_humanize(type)})'] = value;
      }
    }

    final commentRows = await database.query(
      'comments',
      columns: ['text'],
      where: 'book = ?',
      whereArgs: [bookId],
    );
    if (commentRows.isNotEmpty) {
      final comment = _displayValue(commentRows.first['text']);
      if (comment.isNotEmpty) result['Description'] = comment;
    }

    await _addCustomColumns(database, result, bookId);
    return result;
  }

  static Future<void> _addRelation(
    Database database,
    Map<String, String> result,
    String valueTable,
    String linkTable,
    String linkedColumn,
    String valueColumn,
    int bookId,
  ) async {
    final rows = await database.rawQuery(
      'SELECT $valueTable.$valueColumn AS value '
      'FROM $linkTable '
      'INNER JOIN $valueTable ON $valueTable.id = $linkTable.$linkedColumn '
      'WHERE $linkTable.book = ? '
      'ORDER BY $valueTable.$valueColumn COLLATE NOCASE',
      [bookId],
    );
    if (rows.isEmpty) return;
    final values = rows
        .map((row) => _displayValue(row['value']))
        .where((value) => value.isNotEmpty)
        .toList();
    if (values.isNotEmpty) result[valueTable] = values.join(', ');
  }

  static Future<void> _addCustomColumns(
    Database database,
    Map<String, String> result,
    int bookId,
  ) async {
    final table = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name = 'custom_columns'",
    );
    if (table.isEmpty) return;

    final customColumns = await database.query('custom_columns');
    for (final column in customColumns) {
      final id = (column['id'] as num?)?.toInt();
      final label = column['name']?.toString().trim().isNotEmpty == true
          ? column['name'].toString()
          : column['label']?.toString();
      if (id == null || label == null || label.isEmpty) continue;

      final valueTable = 'custom_column_$id';
      final linkTable = 'books_custom_column_${id}_link';
      final existingTables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        'AND name IN (?, ?)',
        [valueTable, linkTable],
      );
      final existingNames =
          existingTables.map((row) => row['name'] as String).toSet();
      final values = <String>[];

      if (existingNames.contains(linkTable)) {
        final linkColumns =
            await database.rawQuery('PRAGMA table_info("$linkTable")');
        final hasBook = linkColumns.any((entry) => entry['name'] == 'book');
        final hasValue = linkColumns.any((entry) => entry['name'] == 'value');
        if (hasBook && hasValue) {
          final links = await database.rawQuery(
            'SELECT value FROM "$linkTable" WHERE book = ?',
            [bookId],
          );
          if (existingNames.contains(valueTable)) {
            final valueColumns =
                await database.rawQuery('PRAGMA table_info("$valueTable")');
            final valueColumn =
                valueColumns.any((entry) => entry['name'] == 'value')
                    ? 'value'
                    : valueColumns.any((entry) => entry['name'] == 'name')
                        ? 'name'
                        : null;
            if (valueColumn != null) {
              for (final link in links) {
                final linkedValue = link['value'];
                if (linkedValue is num) {
                  final rows = await database.rawQuery(
                    'SELECT "$valueColumn" AS value FROM "$valueTable" '
                    'WHERE id = ?',
                    [linkedValue],
                  );
                  if (rows.isNotEmpty) {
                    final value = _displayValue(rows.first['value']);
                    if (value.isNotEmpty) values.add(value);
                  }
                } else {
                  final value = _displayValue(linkedValue);
                  if (value.isNotEmpty) values.add(value);
                }
              }
            }
          } else {
            values.addAll(
              links
                  .map((link) => _displayValue(link['value']))
                  .where((value) => value.isNotEmpty),
            );
          }
        }
      } else if (existingNames.contains(valueTable)) {
        final columns =
            await database.rawQuery('PRAGMA table_info("$valueTable")');
        final hasBook = columns.any((entry) => entry['name'] == 'book');
        final hasValue = columns.any((entry) => entry['name'] == 'value');
        if (hasBook && hasValue) {
          final rows = await database.rawQuery(
            'SELECT value FROM "$valueTable" WHERE book = ?',
            [bookId],
          );
          values.addAll(
            rows
                .map((row) => _displayValue(row['value']))
                .where((value) => value.isNotEmpty),
          );
        }
      }

      if (values.isNotEmpty) result[label] = values.join(', ');
    }
  }

  static String _displayValue(Object? value) {
    if (value == null) return '';
    if (value is List<int>) return '';
    return value.toString().trim();
  }

  static String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  static String _humanize(String value) {
    final spaced = value.replaceAll('_', ' ').replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}');
    return spaced.isEmpty
        ? spaced
        : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}
