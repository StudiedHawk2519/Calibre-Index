import 'package:calibre_carte/helpers/book_search.dart';
import 'package:calibre_carte/models/book_display_group.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:calibre_carte/widgets/books_view_widgets/grid_tile.dart';
import 'package:calibre_carte/widgets/books_view_widgets/series_stack_tile.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class BooksGridView extends StatefulWidget {
  final String filter;
  final List<Books> books;
  final Map<int, List<String>> tagsByBookId;

  const BooksGridView(this.filter, this.books, this.tagsByBookId, {super.key});

  @override
  State<BooksGridView> createState() => _BooksGridViewState();
}

class _BooksGridViewState extends State<BooksGridView> {
  final Set<String> _expandedSeries = {};

  Widget _bookTile(Books book, List<Books> allBooks, Update update) {
    final index = allBooks.indexOf(book);
    return CalibreGridTile(
      index,
      book,
      allBooks,
      matchOriginalCoverSize: update.matchOriginalCoverSize,
      showTitleOverlay: update.showCoverTitles,
      coverCornerRadius: update.coverCornerRadius,
      goodreadsLinks: update.goodreadsLinks,
    );
  }

  @override
  Widget build(BuildContext context) {
    final update = Provider.of<Update>(context);
    final filteredBooks = widget.books
        .where(
          (book) => matchesBookSearch(
            book,
            query: widget.filter,
            tagsByBookId: widget.tagsByBookId,
          ),
        )
        .toList();

    final children = <Widget>[];
    if (!update.stackSeries) {
      children.addAll(
        filteredBooks.map((book) => _bookTile(book, filteredBooks, update)),
      );
    } else {
      for (final group in groupBooksBySeries(filteredBooks)) {
        if (!group.isSeries) {
          children.addAll(
            group.books.map((book) => _bookTile(book, filteredBooks, update)),
          );
          continue;
        }

        final expanded = _expandedSeries.contains(group.seriesKey);
        children.add(
          SeriesStackTile(
            group: group,
            coverCornerRadius: update.coverCornerRadius,
            expanded: expanded,
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedSeries.remove(group.seriesKey);
                } else {
                  _expandedSeries.add(group.seriesKey);
                }
              });
            },
          ),
        );
        if (expanded) {
          children.addAll(
            group.books.map((book) => _bookTile(book, filteredBooks, update)),
          );
        }
      }
    }

    return GridView.count(
      crossAxisCount: update.gridColumns,
      childAspectRatio: 2 / 3,
      scrollCacheExtent: const ScrollCacheExtent.pixels(600),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      children: children,
    );
  }
}
