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
    try {
      if (await cacher.checkIfCachedFileExists(relativePath, bookId)) {
        final imagePath =
            await cacher.returnCachedImagePath(relativePath, bookId);
        if (mounted) {
          setState(() {
            _imagePath = imagePath;
            _loading = false;
          });
        }
        return;
      }

      final thumbnailPath =
          ImageCacher.cachedThumbnailPath(relativePath, bookId) ??
              await cacher.findCachedThumbnailPath(relativePath, bookId) ??
              await cacher.downloadAndCacheImageThumbnail(
                relativePath,
                bookId,
              );
      if (thumbnailPath != null && mounted) {
        setState(() {
          _imagePath = thumbnailPath;
          _loading = false;
        });
      }
      unawaited(_loadFullCover());
    } on Exception catch (error, stackTrace) {
      debugPrint('Could not load a cached book cover: $error\n$stackTrace');
      if (mounted) setState(() => _loading = false);
    } on StateError catch (error, stackTrace) {
      debugPrint('Could not load a cached book cover: $error\n$stackTrace');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFullCover() async {
    final relativePath = widget.relativePath;
    final bookId = widget.bookId;
    if (relativePath == null || bookId == null) return;

    try {
      final cacher = ImageCacher();
      if (!await cacher.downloadAndCacheImage(relativePath, bookId)) {
        if (mounted && _imagePath == null) setState(() => _loading = false);
        return;
      }
      final imagePath =
          await cacher.returnCachedImagePath(relativePath, bookId);
      if (mounted) {
        setState(() {
          _imagePath = imagePath;
          _loading = false;
        });
      }
    } on Exception catch (error, stackTrace) {
      debugPrint(
          'Could not load the full-size book cover: $error\n$stackTrace');
      if (mounted && _imagePath == null) setState(() => _loading = false);
    } on StateError catch (error, stackTrace) {
      debugPrint(
          'Could not load the full-size book cover: $error\n$stackTrace');
      if (mounted && _imagePath == null) setState(() => _loading = false);
    }
  }

  void _startLoading() {
    final relativePath = widget.relativePath;
    final bookId = widget.bookId;
    final fullPath = relativePath == null || bookId == null
        ? null
        : ImageCacher.cachedCoverPath(relativePath, bookId);
    _imagePath = fullPath ??
        (relativePath == null || bookId == null
            ? null
            : ImageCacher.cachedThumbnailPath(relativePath, bookId));
    _loading = _imagePath == null;
    if (fullPath == null) {
      unawaited(_imagePath == null ? _loadCover() : _loadFullCover());
    }
  }

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  @override
  void didUpdateWidget(BookDetailsCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.relativePath != widget.relativePath) {
      _startLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _imagePath;
    if (imagePath != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final displayWidth = widget.width ?? constraints.maxWidth;
          final physicalWidth = displayWidth.isFinite && displayWidth > 0
              ? (displayWidth * MediaQuery.of(context).devicePixelRatio).round()
              : null;
          return Image.file(
            File(imagePath),
            height: widget.height,
            width: widget.width,
            cacheWidth: physicalWidth,
            fit: widget.fit,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Could not display cached book cover: $error');
              return _placeholder();
            },
          );
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
