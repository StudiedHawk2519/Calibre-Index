import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:calibre_carte/helpers/image_cacher.dart';

class BookDetailsCoverImage extends StatefulWidget {
  final int? bookId;
  final String? relativePath;
  final double? height;
  final double? width;
  final BoxFit fit;

  const BookDetailsCoverImage(
    this.bookId,
    this.relativePath,
    this.height,
    this.width, {
    this.fit = BoxFit.contain,
    super.key,
  });

  @override
  _BookDetailsCoverImageState createState() => _BookDetailsCoverImageState();
}

class _BookDetailsCoverImageState extends State<BookDetailsCoverImage> {
  late Future<String?> _imagePath;

  Future<String?> _loadCover() async {
    final relativePath = widget.relativePath;
    final bookId = widget.bookId;
    if (relativePath == null || bookId == null) return null;

    final cacher = ImageCacher();
    final cached = await cacher.checkIfCachedFileExists(relativePath, bookId);
    if (!cached && !await cacher.downloadAndCacheImage(relativePath, bookId)) {
      return null;
    }
    return cacher.returnCachedImagePath(relativePath, bookId);
  }

  @override
  void initState() {
    super.initState();
    _imagePath = _loadCover();
  }

  @override
  void didUpdateWidget(BookDetailsCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.relativePath != widget.relativePath) {
      _imagePath = _loadCover();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imagePath,
      builder: (context, snapshot) {
        final imagePath = snapshot.data;
        if (snapshot.connectionState == ConnectionState.done &&
            imagePath != null) {
          return Image.file(
            File(imagePath),
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Could not display cached book cover: $error');
              return _placeholder();
            },
          );
        }
        if (snapshot.hasError) {
          debugPrint('Could not load book cover: ${snapshot.error}');
          return _placeholder();
        }
        return _placeholder(loading: true);
      },
    );
  }

  Widget _placeholder({bool loading = false}) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Image.asset(
                'assets/images/logo.png',
                fit: widget.fit,
              ),
      ),
    );
  }
}
