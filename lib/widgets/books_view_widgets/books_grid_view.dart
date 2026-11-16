import 'package:calibre_carte/helpers/book_search.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:calibre_carte/widgets/books_view_widgets/grid_tile.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class BooksGridView extends StatelessWidget {
  final String filter;
  final List<Books> books;
  final Map<int, List<String>> tagsByBookId;

  BooksGridView(this.filter, this.books, this.tagsByBookId);

  Widget scrollGrid(List<Widget> children, BuildContext context) {
    return CustomScrollView(
      primary: false,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          sliver: SliverGrid.count(
            childAspectRatio: 2 / 3,
            crossAxisCount: 2,
//            mainAxisSpacing: 5.0,
            children: children,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Update update = Provider.of(context);
    final filteredBooks = books
        .where(
          (book) => matchesBookSearch(
            book,
            searchFilter: update.searchFilter,
            query: filter,
            tagsByBookId: tagsByBookId,
          ),
        )
        .toList();

    return scrollGrid(
        filteredBooks
            .asMap()
            .map((index, book) => MapEntry(
                  index,
                  CalibreGridTile(
                    index,
                    book,
                    filteredBooks,
                    matchOriginalCoverSize: update.matchOriginalCoverSize,
                  ),
                ))
            .values
            .toList(),
        context);
  }
}
