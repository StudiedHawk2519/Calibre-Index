import 'package:calibre_carte/helpers/book_search.dart';
import 'package:calibre_carte/models/book_display_group.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:calibre_carte/widgets/books_view_widgets/list_tile.dart';
import 'package:calibre_carte/widgets/books_view_widgets/series_stack_tile.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class BooksListView extends StatefulWidget {
  final String filter;
  final List<Books> books;
  final Map<int, List<String>> tagsByBookId;

  const BooksListView(this.filter, this.books, this.tagsByBookId, {super.key});

  @override
  State<BooksListView> createState() => _BooksListViewState();
}

class _BooksListViewState extends State<BooksListView> {
  final Set<String> _expandedSeries = {};

  @override
  Widget build(BuildContext context) {
    final update = Provider.of<Update>(context);
    final visibleBooks = widget.books
        .where(
          (book) => matchesBookSearch(
            book,
            query: widget.filter,
            tagsByBookId: widget.tagsByBookId,
          ),
        )
        .toList();

    CoolTile tileFor(Books book) => CoolTile(
          widget.books.indexOf(book),
          widget.books,
          matchOriginalCoverSize: update.matchOriginalCoverSize,
          coverCornerRadius: update.coverCornerRadius,
        );

    final children = <Widget>[];
    if (!update.stackSeries) {
      children.addAll(visibleBooks.map(tileFor));
    } else {
      for (final group in groupBooksBySeries(visibleBooks)) {
        if (!group.isSeries) {
          children.addAll(group.books.map(tileFor));
          continue;
        }

        final expanded = _expandedSeries.contains(group.seriesKey);
        children.add(
          SeriesListStackTile(
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
        if (expanded) children.addAll(group.books.map(tileFor));
      }
    }

    return ListView(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: children,
    );
  }
}
