import 'package:calibre_carte/helpers/book_search.dart';
import 'package:calibre_carte/models/book_display_group.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:calibre_carte/widgets/books_view_widgets/list_tile.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class BooksListView extends StatelessWidget {
  final String filter;
  final List<Books> books;
  final Map<int, List<String>> tagsByBookId;

  BooksListView(this.filter, this.books, this.tagsByBookId);

  @override
  Widget build(BuildContext context) {
    final Update update = Provider.of(context);
    final query = filter.toLowerCase();
    final visibleIndexes = <int>[
      for (var index = 0; index < books.length; index++)
        if (matchesBookSearch(
          books[index],
          query: query,
          tagsByBookId: tagsByBookId,
        ))
          index,
    ];

    CoolTile tileFor(Books book) => CoolTile(
          books.indexOf(book),
          books,
          matchOriginalCoverSize: update.matchOriginalCoverSize,
          coverCornerRadius: update.coverCornerRadius,
        );

    final visibleBooks = visibleIndexes.map((index) => books[index]).toList();
    if (!update.stackSeries) {
      return ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: visibleBooks.map(tileFor).toList(),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        for (final group in groupBooksBySeries(visibleBooks))
          if (group.isSeries)
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.library_books_rounded),
                title: Text(group.seriesName!),
                subtitle: Text(
                  '${group.books.length} books'
                  '${group.author?.isNotEmpty == true ? ' · ${group.author}' : ''}',
                ),
                children: group.books.map(tileFor).toList(),
              ),
            )
          else
            ...group.books.map(tileFor),
      ],
    );
  }
}
