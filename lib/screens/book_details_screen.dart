import 'package:calibre_carte/helpers/authors_provider.dart';
import 'package:calibre_carte/helpers/book_author_link_provider.dart';
import 'package:calibre_carte/helpers/book_downloader.dart';
import 'package:calibre_carte/helpers/book_metadata_provider.dart';
import 'package:calibre_carte/helpers/book_publisher_link_provider.dart';
import 'package:calibre_carte/helpers/book_rating_link_provider.dart';
import 'package:calibre_carte/helpers/comments_provider.dart';
import 'package:calibre_carte/helpers/data_provider.dart';
import 'package:calibre_carte/models/authors.dart';
import 'package:calibre_carte/models/books_authors_link.dart';
import 'package:calibre_carte/models/comments.dart';
import 'package:calibre_carte/models/data.dart';
import 'package:calibre_carte/models/publishers.dart';
import 'package:calibre_carte/models/ratings.dart';
import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/details_lefttile.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/details_sidebar.dart';
import 'package:calibre_carte/widgets/book_details_cover_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../helpers/books_provider.dart';
import '../models/books.dart';

class BookDetailsScreen extends StatefulWidget {
  static const routeName = '/book-detailsbeta';
  final int bookId;
  final VoidCallback refreshTile;

  const BookDetailsScreen({
    required this.bookId,
    required this.refreshTile,
  });

  @override
  _BookDetailsScreenState createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late Books bookDetails;
  Ratings? rating;
  Comments? bookComments;
  late Future<void> myFuture;
  String authorText = '';
  late Future<bool> mySecondFuture;
  List<Map<String, String>> dataFormatsFileNameMap = [];
  Publishers? publishers;
  Map<String, String> allMetadata = {};

  Future<bool> checkIfLocalCopyExists() async {
    List<Data> dataList = await DataProvider.getDataByBookID(widget.bookId);
    final List<Map<String, String>> dataFormatsFileNameMapTemp = [];

    for (final element in dataList) {
      final String? name = element.name;
      final String? format = element.format;
      if (name == null || format == null) continue;

      final String fileNameWithExtension = '$name.${format.toLowerCase()}';
      final Map<String, String> tempMap = {
        "format": format,
        "name": fileNameWithExtension
      };
      dataFormatsFileNameMapTemp.add(tempMap);
    }
    final BookDownloader bd = BookDownloader();

    for (final file in dataFormatsFileNameMapTemp) {
      final bool exists = await bd.checkIfDownloadedFileExists(file['name']!);
      if (exists) {
        dataFormatsFileNameMap = dataFormatsFileNameMapTemp;
        return true;
      }
    }
    dataFormatsFileNameMap = dataFormatsFileNameMapTemp;
    return false;
  }

  _checkCopies() {
    setState(() {
      mySecondFuture = checkIfLocalCopyExists();
    });
    widget.refreshTile();
  }

  Future<void> getBookDetails() async {
    final Books? details = await BooksProvider.getBookByID(widget.bookId, null);
    if (details == null) {
      throw StateError('Book ${widget.bookId} was not found.');
    }
    bookDetails = details;
    bookComments =
        await CommentsProvider.getCommentByBookID(widget.bookId, null);
    final List<BooksAuthorsLink> bookAuthorsLinks =
        await BooksAuthorsLinksProvider.getAuthorsByBookID(widget.bookId);

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

    authorText = authors.join(', ');
    rating = await BooksRatingLinkProvider.getRatingByBookID(widget.bookId);
    publishers =
        await BooksPublisherLinkProvider.getPublisherByBookID(widget.bookId);
    allMetadata = await BookMetadataProvider.getMetadataForBook(widget.bookId);
  }

  @override
  void initState() {
    super.initState();
    myFuture = getBookDetails();
    mySecondFuture = checkIfLocalCopyExists();
  }

  @override
  void didUpdateWidget(BookDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId == widget.bookId) {
      return;
    }

    myFuture = getBookDetails();
    mySecondFuture = checkIfLocalCopyExists();
  }

  double textScaleFactor(BuildContext context) {
    if (MediaQuery.of(context).size.height > 610) {
      return MediaQuery.of(context).textScaler.scale(1).clamp(0.6, 1.0);
    } else {
      return MediaQuery.of(context).textScaler.scale(1).clamp(0.6, 0.85);
    }
  }

  Widget description() {
    final update = Provider.of<Update>(context);
    final size = MediaQuery.of(context).size;
    final gridCellWidth = (size.width - 16) / update.gridColumns;
    final coverWidth = update.bookLayout == 'list' ? 83.0 : gridCellWidth - 12;
    final coverHeight =
        update.bookLayout == 'list' ? 124.0 : gridCellWidth * 1.5 - 12;
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScaleFactor(context))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(update.coverCornerRadius),
                  child: BookDetailsCoverImage(
                    widget.bookId,
                    bookDetails.path,
                    coverHeight,
                    coverWidth,
                    fit: update.matchOriginalCoverSize
                        ? BoxFit.contain
                        : BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: rightTile(coverHeight),
                ),
              ],
            ),
            DetailsLeftTile(
              publishers: publishers,
              rating: rating,
              bookDetails: bookDetails,
              authorText: authorText,
              onShowAllMetadata: _showAllMetadata,
            ),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (bookComments?.text?.isNotEmpty == true)
              Html(
                data: bookComments!.text,
                style: {
                  'body': Style(
                    fontSize: FontSize(16),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                },
              )
            else
              Text(
                'No description available.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
    );
  }

  void _showAllMetadata() {
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All book metadata'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(0.85),
                1: FlexColumnWidth(1.15),
              },
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              children: [
                for (final entry in allMetadata.entries)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        child: SelectableText(entry.value),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget rightTile(double coverHeight) {
    return FutureBuilder<bool>(
      future: mySecondFuture,
      builder: (context, snapshot) {
        return DetailsSidebar(
          height: coverHeight,
          bookDetails: bookDetails,
          bookId: widget.bookId,
          dataFormatsFileNameMap: dataFormatsFileNameMap,
          downloaded: snapshot.data ?? false,
          checkCopies: _checkCopies,
        );
      },
    );
  }

  PreferredSizeWidget getAppbar() {
    return AppBar(title: const Text('Book details'));
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colorTheme = Provider.of(context);
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScaleFactor(context))),
      child: Scaffold(
        backgroundColor: colorTheme.descriptionBackground,
        appBar: getAppbar(),
        body: FutureBuilder<void>(
            future: myFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Unable to load book details.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.done) {
                return description();
              } else {
                return Center(
                  child: CircularProgressIndicator(
                    color: colorTheme.settingsIcon,
                  ),
                );
              }
            }),
      ),
    );
  }
}

//FloatingActionButton(
