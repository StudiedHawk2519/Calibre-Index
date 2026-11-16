import 'dart:io';
import 'package:calibre_carte/helpers/metadata_cacher.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "metadata.db";
  static const _databaseVersion = 1;

  //  Make this class a singleton class(A singleton class is has only one instance active at any time)
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _db;

  Future<Database?> get db async {
    _db ??= await initDb();
    return _db;
  }

  static nullDb() async {
    _db = null;
  }

  static Future<String> getDatabasePath() async {
    final databasePath = await getDatabasesPath();
    return join(databasePath, _databaseName);
  }

  // Here we are checking that there is not already a copy of the
  initDb() async {
//    print("I am inside initDb");
    final path = await getDatabasePath();
    final bool exists = await databaseExists(path);

    if (!exists) {
//      print("Database at path doesn't exist");
//      Making sure  the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      MetadataCacher mc = MetadataCacher();
//      print('Metdata cacher should now run"');
      await mc.downloadAndCacheMetadata();
    } else {
//      print("Database at path exists");
    }
//    print("Open gets called asfter this stateemnt");
    try {
      return await openDatabase(path, version: _databaseVersion);
    } catch (e) {
//      print(" exception $e");
      MetadataCacher mc = MetadataCacher();
//      print('Metdata cacher should now run"');
      await mc.downloadAndCacheMetadata();
      return await openDatabase(path, version: _databaseVersion);
    }
  }

  static deleteDb() async {
    String path = await getDatabasePath();
    await deleteDatabase(path);
  }

  static invalidateCache() async {
    await _db!.close();
    await DatabaseHelper.nullDb();
  }
}
