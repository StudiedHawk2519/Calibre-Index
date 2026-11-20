import 'dart:async';
import 'dart:io';

import 'package:calibre_carte/homepage.dart';
import 'package:calibre_carte/providers/book_details_navigation_provider.dart';
import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:calibre_carte/providers/list_tile.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]));
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? tokenExists;
  bool matchOriginalCoverSize = true;
  bool showCoverTitles = true;
  int gridColumns = 2;
  double coverCornerRadius = 24;
  bool stackSeries = false;
  bool goodreadsLinks = false;
  List<String> pinnedCustomMetadata = [];
  String bookLayout = 'list';
  Future? myFuture;
  bool darkMode = false;
  Future<void> getTokenAndSearchFromPreferences() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    darkMode = sp.getBool('darkMode') ?? false;
    if (mounted) setState(() {});
    tokenExists = sp.containsKey('token');
    matchOriginalCoverSize = sp.getBool('matchOriginalCoverSize') ?? true;
    showCoverTitles = sp.getBool('showCoverTitles') ?? true;
    gridColumns = (sp.getInt('gridColumns') ?? 2).clamp(2, 5).toInt();
    coverCornerRadius = (sp.getDouble('coverCornerRadius') ?? 24).clamp(0, 40);
    stackSeries = sp.getBool('stackSeries') ?? false;
    goodreadsLinks = sp.getBool('goodreadsLinks') ?? false;
    pinnedCustomMetadata = sp.getStringList('pinnedCustomMetadata') ?? [];
    bookLayout = sp.getString('layout') ?? 'list';
    unawaited(_ensureDefaultDownloadDirectory(sp));
  }

  Future<void> _ensureDefaultDownloadDirectory(
    SharedPreferences preferences,
  ) async {
    if (preferences.containsKey('downloaded_directory')) return;
    try {
      final externalDirectory = await getExternalStorageDirectory();
      if (externalDirectory == null) {
        throw FileSystemException(
          'Android did not provide an app storage directory.',
        );
      }
      final booksDirectory = Directory(
        '${externalDirectory.path}${Platform.pathSeparator}books',
      );
      await booksDirectory.create(recursive: true);
      if (preferences.containsKey('downloaded_directory')) return;
      await preferences.setString('downloaded_directory', booksDirectory.path);
    } on Exception catch (error, stackTrace) {
      debugPrint(
        'Could not prepare the default download directory: $error\n$stackTrace',
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    myFuture = getTokenAndSearchFromPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: myFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => Update(
                  tokenExists,
                  matchOriginalCoverSize: matchOriginalCoverSize,
                  showCoverTitles: showCoverTitles,
                  gridColumns: gridColumns,
                  coverCornerRadius: coverCornerRadius,
                  stackSeries: stackSeries,
                  goodreadsLinks: goodreadsLinks,
                  pinnedCustomMetadata: pinnedCustomMetadata,
                  bookLayout: bookLayout,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => BookDetailsNavigation(),
              ),
              ChangeNotifierProvider(
                create: (_) => ColorTheme(darkMode),
              ),
              ChangeNotifierProvider(
                create: (_) => ListTileProvider(),
              ),
            ],
            child: DynamicColorLoader(
              child: Consumer<ColorTheme>(
                builder: (context, colorTheme, child) => MaterialApp(
                  title: "Calibre Index",
                  debugShowCheckedModeBanner: false,
                  theme: colorTheme.themeDataFor(colorTheme.lightColorScheme),
                  darkTheme:
                      colorTheme.themeDataFor(colorTheme.darkColorScheme),
                  themeMode:
                      colorTheme.darkMode ? ThemeMode.dark : ThemeMode.light,
                  home: MyHomePage(),
                ),
              ),
            ),
          );
        } else {
          final splashScheme = ColorScheme.fromSeed(
            seedColor: const Color(0xFF7351A6),
            brightness: darkMode ? Brightness.dark : Brightness.light,
            dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
          );
          final splashTheme = ThemeData(
            useMaterial3: true,
            colorScheme: splashScheme,
          );
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: splashTheme,
            home: Scaffold(
              backgroundColor: splashScheme.surface,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Calibre Index',
                      style: splashTheme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: splashScheme.primary,
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class DynamicColorLoader extends StatefulWidget {
  final Widget child;

  const DynamicColorLoader({required this.child, super.key});

  @override
  State<DynamicColorLoader> createState() => _DynamicColorLoaderState();
}

class _DynamicColorLoaderState extends State<DynamicColorLoader> {
  @override
  void initState() {
    super.initState();
    unawaited(_loadDynamicColors());
  }

  Future<void> _loadDynamicColors() async {
    if (!Platform.isAndroid) return;
    try {
      final corePalette = await DynamicColorPlugin.getCorePalette();
      if (corePalette == null || !mounted) return;
      Provider.of<ColorTheme>(context, listen: false).updateDynamicColorSchemes(
        corePalette.toColorScheme(),
        corePalette.toColorScheme(brightness: Brightness.dark),
      );
    } on PlatformException catch (error) {
      debugPrint('Could not read the Android dynamic color palette: $error');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
