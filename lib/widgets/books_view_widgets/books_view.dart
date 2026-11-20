import 'package:calibre_carte/helpers/book_author_link_provider.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:calibre_carte/widgets/books_view_widgets/books_grid_view.dart';
import 'package:calibre_carte/widgets/books_view_widgets/books_list_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:calibre_carte/helpers/books_provider.dart';
import 'package:calibre_carte/helpers/book_sort.dart';
import 'package:calibre_carte/helpers/tags_provider.dart';
import 'package:calibre_carte/helpers/series_provider.dart';
import 'package:calibre_carte/models/books.dart';

class BooksView extends StatefulWidget {
  final String? layout;
  final String filter;
  final String sortOption;
  final String sortDirection;
  final Update update;

  BooksView(this.layout, this.filter,
      {this.sortOption = 'title',
      this.sortDirection = 'asc',
      required this.update});

  @override
  _BooksViewState createState() => _BooksViewState();
}

class _BooksViewState extends State<BooksView> {
  Future<void>? afterSorting;
  List<Books> books = [];
  Map<int, List<String>> tagsByBookId = {};
  Map<int, String> seriesByBookId = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    afterSorting = _loadBooksAndSort();
  }

  @override
  void didUpdateWidget(BooksView oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    if (widget.update.shouldDoUpdate == true) {
      afterSorting = _loadBooksAndSort();
      widget.update.shouldDoUpdateFalse();
      return;
    }
    if (oldWidget.sortOption == widget.sortOption &&
        oldWidget.sortDirection == widget.sortDirection) {
      return;
    }
    afterSorting = sortBooks();
  }

  Future<void> _loadBooksAndSort() async {
    await getBooks();
    await sortBooks();
  }

  Future<void> sortBooks() async {
    books.sort(
      (a, b) => compareBooks(
        a,
        b,
        sortOption: widget.sortOption,
        sortDirection: widget.sortDirection,
      ),
    );
  }

  //aggregates all the data to display
  Future<void> getBooks() async {
    books = await BooksProvider.getAllBooks(widget.update.shouldDoUpdate);
    final bookIds =
        books.map((book) => book.id).whereType<int>().toList(growable: false);
    final authorNamesFuture =
        BooksAuthorsLinksProvider.getAuthorNamesByBookIds(bookIds);
    final tagsFuture = TagsProvider.getTagNamesByBookIds(bookIds);
    final seriesFuture = SeriesProvider.getNamesByBookIds(bookIds);

    final authorNames = await authorNamesFuture;
    tagsByBookId = await tagsFuture;
    seriesByBookId = await seriesFuture;
    for (final book in books) {
      book.author_sort = authorNames[book.id]?.join(', ') ?? '';
      book.series = seriesByBookId[book.id];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: afterSorting,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return widget.layout == "list"
                ? BooksListView(widget.filter, books, tagsByBookId)
                : (widget.layout == "grid"
                    ? BooksGridView(widget.filter, books, tagsByBookId)
                    : BooksListView(widget.filter, books, tagsByBookId));
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
}
