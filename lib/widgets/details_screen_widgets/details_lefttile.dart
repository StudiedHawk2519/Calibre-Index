import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/models/ratings.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/details_text.dart';
import 'package:material_ui/material_ui.dart';

class DetailsLeftTile extends StatelessWidget {
  final Books bookDetails;
  final String authorText;
  final Ratings? rating;
  final Map<String, String> pinnedMetadata;
  final bool goodreadsEnabled;
  final VoidCallback onShowAllMetadata;

  const DetailsLeftTile({
    super.key,
    required this.bookDetails,
    required this.authorText,
    required this.rating,
    required this.pinnedMetadata,
    required this.goodreadsEnabled,
    required this.onShowAllMetadata,
  });

  @override
  Widget build(BuildContext context) {
    return BookDetailsText(
      MediaQuery.of(context).size.width - 32,
      bookDetails,
      authorText,
      rating,
      pinnedMetadata,
      goodreadsEnabled,
      onShowAllMetadata,
    );
  }
}
