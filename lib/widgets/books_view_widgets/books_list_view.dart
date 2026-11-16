import 'package:calibre_carte/helpers/book_search.dart';
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
          searchFilter: update.searchFilter,
          query: query,
          tagsByBookId: tagsByBookId,
        ))
          index,
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: visibleIndexes.length,
      itemBuilder: (context, index) => CoolTile(
        visibleIndexes[index],
        books,
        matchOriginalCoverSize: update.matchOriginalCoverSize,
      ),
    );
  }
}
