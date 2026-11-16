import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/models/publishers.dart';
import 'package:calibre_carte/models/ratings.dart';
import 'package:calibre_carte/widgets/book_details_cover_image.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/details_text.dart';
import 'package:material_ui/material_ui.dart';

class DetailsLeftTile extends StatelessWidget {
  final int bookId;
  final Books bookDetails;
  final String authorText;
  final Ratings? rating;
  final Publishers? publishers;
  final bool matchOriginalCoverSize;

  const DetailsLeftTile({
    super.key,
    required this.bookId,
    required this.bookDetails,
    required this.authorText,
    required this.rating,
    required this.publishers,
    required this.matchOriginalCoverSize,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double coverWidth = (size.width * 0.68).clamp(210.0, 300.0);
    final double coverHeight = (size.height * 0.4).clamp(280.0, 380.0);
    final double contentWidth = size.width - 32;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: BookDetailsCoverImage(
              bookId,
              bookDetails.path,
              coverHeight,
              coverWidth,
              fit: matchOriginalCoverSize ? BoxFit.contain : BoxFit.cover,
            ),
          ),
        ),
        BookDetailsText(
          contentWidth,
          bookDetails,
          authorText,
          rating,
          publishers,
        ),
      ],
    );
  }
}
