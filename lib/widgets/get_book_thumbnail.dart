import 'package:calibre_carte/widgets/book_details_cover_image.dart';
import 'package:material_ui/material_ui.dart';

class GetBookThumbnail extends StatelessWidget {
  final int bookId;
  final String relativePath;

  const GetBookThumbnail(this.bookId, this.relativePath, {super.key});

  @override
  Widget build(BuildContext context) {
    return BookDetailsCoverImage(
      bookId,
      relativePath,
      null,
      null,
      fit: BoxFit.fitHeight,
    );
  }
}
