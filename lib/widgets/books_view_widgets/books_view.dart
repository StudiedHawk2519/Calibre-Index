import 'package:calibre_carte/helpers/book_author_link_provider.dart';
import 'package:calibre_carte/models/books_authors_link.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:calibre_carte/widgets/books_view_widgets/books_grid_view.dart';
import 'package:calibre_carte/widgets/books_view_widgets/books_list_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:calibre_carte/helpers/authors_provider.dart';
import 'package:calibre_carte/helpers/books_provider.dart';
import 'package:calibre_carte/helpers/tags_provider.dart';
import 'package:calibre_carte/models/authors.dart';
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
    if (widget.sortOption == 'author') {
      books.sort((a, b) => (a.author_sort ?? '')
          .toLowerCase()
          .compareTo((b.author_sort ?? '').toLowerCase()));
    } else if (widget.sortOption == 'title') {
      books.sort((a, b) => (a.title ?? '')
          .toLowerCase()
          .compareTo((b.title ?? '').toLowerCase()));
    } else {
      books.sort((a, b) => (a.title ?? '')
          .toLowerCase()
          .compareTo((b.title ?? '').toLowerCase()));
    }

    if (widget.sortDirection == 'desc') {
      books = books.reversed.toList();
    }
  }

  //aggregates all the data to display
  Future<void> getBooks() async {
    books = await BooksProvider.getAllBooks(widget.update.shouldDoUpdate);
    for (final book in books) {
      List<BooksAuthorsLink> bookAuthorsLinks =
          await BooksAuthorsLinksProvider.getAuthorsByBookID(book.id);
      final List<String> authors = [];
      for (final link in bookAuthorsLinks) {
        final int? authorId = link.author;
        if (authorId == null) continue;

        final Authors? author =
            await AuthorsProvider.getAuthorByID(authorId, null);
        final String? name = author?.name;
        if (name != null && name.isNotEmpty) {
          authors.add(name);
        }
      }
      book.author_sort = authors.join(', ');
    }
    final bookIds =
        books.map((book) => book.id).whereType<int>().toList(growable: false);
    tagsByBookId = await TagsProvider.getTagNamesByBookIds(bookIds);
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
