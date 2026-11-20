import 'dart:io';
import 'dart:async';

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
  String? _imagePath;
  bool _loading = true;

  Future<void> _loadCover() async {
    final relativePath = widget.relativePath;
    final bookId = widget.bookId;
    if (relativePath == null || bookId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final cacher = ImageCacher();
    if (!await cacher.checkIfCachedFileExists(relativePath, bookId) &&
        !await cacher.downloadAndCacheImage(relativePath, bookId)) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final imagePath = await cacher.returnCachedImagePath(relativePath, bookId);
    if (mounted) {
      setState(() {
        _imagePath = imagePath;
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _imagePath = _getInMemoryCoverPath();
    _loading = _imagePath == null;
    if (_loading) unawaited(_loadCover());
  }

  @override
  void didUpdateWidget(BookDetailsCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.relativePath != widget.relativePath) {
      _imagePath = _getInMemoryCoverPath();
      _loading = _imagePath == null;
      if (_loading) unawaited(_loadCover());
    }
  }

  String? _getInMemoryCoverPath() {
    final bookId = widget.bookId;
    final relativePath = widget.relativePath;
    if (bookId == null || relativePath == null) return null;
    return ImageCacher.cachedCoverPath(relativePath, bookId);
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _imagePath;
    if (imagePath != null) {
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
    return _placeholder(loading: _loading);
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
