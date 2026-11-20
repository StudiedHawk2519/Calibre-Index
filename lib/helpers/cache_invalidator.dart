import 'dart:io';
import 'package:calibre_carte/helpers/db_helper.dart';
import 'package:calibre_carte/helpers/image_cacher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CacheInvalidator {
  static Future<void> invalidateImagesCache() async {
    ImageCacher.clearMemoryCache();
    final supportDirectory = await getApplicationSupportDirectory();
    final coverCache = Directory(join(supportDirectory.path, 'cover_cache'));
    if (await coverCache.exists()) {
      await coverCache.delete(recursive: true);
    }

    final temporaryDirectory = await getTemporaryDirectory();
    await for (final entity in temporaryDirectory.list()) {
      final name = basename(entity.path);
      if (entity is File &&
          (name.startsWith('cover_') || name.startsWith('thumbnail_'))) {
        await entity.delete();
      }
    }
  }

  static Future<void> invalidateDatabaseCache() async {
    await DatabaseHelper.invalidateCache();
  }
}
