import 'package:calibre_carte/helpers/book_search.dart';
import 'package:calibre_carte/models/book_display_group.dart';
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

  Widget scrollGrid(List<Widget> children, int columns) {
    return CustomScrollView(
      primary: false,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          sliver: SliverGrid.count(
            childAspectRatio: 2 / 3,
            crossAxisCount: columns,
            children: children,
          ),
        )
      ],
    );
  }

  Widget _buildGrid(
    List<Books> visibleBooks,
    Update update, {
    bool shrinkWrap = false,
  }) {
    return GridView.count(
      crossAxisCount: update.gridColumns,
      childAspectRatio: 2 / 3,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding:
          shrinkWrap ? EdgeInsets.zero : const EdgeInsets.fromLTRB(8, 16, 8, 8),
      children: [
        for (var index = 0; index < visibleBooks.length; index++)
          CalibreGridTile(
            index,
            visibleBooks[index],
            visibleBooks,
            matchOriginalCoverSize: update.matchOriginalCoverSize,
            showTitleOverlay: update.showCoverTitles,
            coverCornerRadius: update.coverCornerRadius,
          ),
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
            query: filter,
            tagsByBookId: tagsByBookId,
          ),
        )
        .toList();

    if (!update.stackSeries) {
      return _buildGrid(filteredBooks, update);
    }

    final groups = groupBooksBySeries(filteredBooks);
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      children: [
        for (final group in groups)
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
                children: [_buildGrid(group.books, update, shrinkWrap: true)],
              ),
            )
          else
            _buildGrid(group.books, update, shrinkWrap: true),
      ],
    );
  }
}
