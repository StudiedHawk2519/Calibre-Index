import 'dart:async';

import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:calibre_carte/screens/settings_screen.dart';
import 'package:calibre_carte/widgets/books_view_widgets/books_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? layout;

  final TextEditingController controller = TextEditingController();
  String filter = "";
  String sortOption = "title";
  String sortDirection = "asc";
  String? token;
  Future? myFuture;
  final _textUpdates = StreamController<String>();
  int _selectedIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
//    TODO: Listener requires that we dispose it off when the widget terrminates
    controller.addListener(() => _textUpdates.add(controller.text));

    _textUpdates.stream
        .debounceTime(const Duration(milliseconds: 500))
        .listen((s) {
      if ((filter != s) || (filter == "")) {
        setState(() {
          filter = s;
        });
      }
    });

    myFuture = getLayoutFromPreferences();
  }

  @override
  void dispose() {
    controller.dispose();
    _textUpdates.close();
    super.dispose();
  }

  Future<void> getLayoutFromPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    layout = preferences.getString('layout') ?? 'list';
    sortOption = preferences.getString('sortOption') ?? 'title';
    sortDirection = preferences.getString('sortDirection') ?? 'asc';
  }

  Future<void> _storeSortPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('sortOption', sortOption);
    await preferences.setString('sortDirection', sortDirection);
  }

  Future<void> _toggleLayout() async {
    final nextLayout = layout == 'grid' ? 'list' : 'grid';
    setState(() => layout = nextLayout);
    await Provider.of<Update>(context, listen: false)
        .changeBookLayout(nextLayout);
  }

  void showSettings(BuildContext context) {
    setState(() => _selectedIndex = 1);
  }

  void showSortOptions(
    BuildContext context,
    ColorTheme colorTheme, {
    bool closeCurrentSheet = false,
  }) {
    if (closeCurrentSheet) Navigator.of(context).pop();
    showModalBottomSheet(
        backgroundColor: colorTheme.modalSheetColor,
        context: context,
        builder: (BuildContext bc) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScaleFactor(context))),
            child: Container(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.title),
                    title: Text("Title"),
                    onTap: () {
                      showSortDirectionOptions("title", colorTheme);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.alternate_email),
                    title: Text("Author Name"),
                    onTap: () {
                      showSortDirectionOptions("author", colorTheme);
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  void showSortDirectionOptions(String sortOpt, ColorTheme colorTheme) {
    Navigator.of(context).pop();
    showModalBottomSheet(
        backgroundColor: colorTheme.modalSheetColor,
        context: context,
        builder: (BuildContext bc) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScaleFactor(context))),
            child: Container(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.keyboard_arrow_up),
                    title: Text("Ascending"),
                    onTap: () {
                      setState(() {
                        sortOption = sortOpt;
                        sortDirection = "asc";
                      });
                      _storeSortPreferences();
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.keyboard_arrow_down),
                    title: Text("Descending"),
                    onTap: () {
                      setState(() {
                        sortOption = sortOpt;
                        sortDirection = "desc";
                      });
                      _storeSortPreferences();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  textScaleFactor(BuildContext context) {
    if (MediaQuery.of(context).size.height > 610) {
      return MediaQuery.of(context).textScaler.scale(1).clamp(0.6, 1.0);
    } else {
      return MediaQuery.of(context).textScaler.scale(1).clamp(0.6, 0.85);
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = Provider.of<Update>(context);
    final colorTheme = Provider.of<ColorTheme>(context);
    final scheme = Theme.of(context).colorScheme;

    final Widget libraryContent = FutureBuilder(
      future: myFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (update.tokenExists == true) {
          return BooksView(
            layout ?? 'list',
            filter,
            sortDirection: sortDirection,
            sortOption: sortOption,
            update: update,
          );
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 56,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your library starts here',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: scheme.onSecondaryContainer),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect your Calibre library to browse and download your books.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: scheme.onSecondaryContainer),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => showSettings(context),
                      icon: const Icon(Icons.cloud_rounded),
                      label: const Text('Connect Dropbox'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScaleFactor(context))),
        child: Scaffold(
          appBar: AppBar(
            title: _selectedIndex == 0 && update.tokenExists == true
                ? SearchBar(
                    controller: controller,
                    hintText: 'Search titles, authors, or tags',
                    leading: const Icon(Icons.search_rounded),
                    trailing: controller.text.isEmpty
                        ? null
                        : [
                            IconButton(
                              tooltip: 'Clear search',
                              onPressed: controller.clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                  )
                : Text(_selectedIndex == 0 ? 'Calibre Index' : 'Settings'),
            actions: [
              if (_selectedIndex == 0 && update.tokenExists == true)
                Container(
                  margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: sortDirection == 'asc'
                            ? 'Ascending order'
                            : 'Descending order',
                        onPressed: () {
                          setState(
                            () => sortDirection =
                                sortDirection == 'asc' ? 'desc' : 'asc',
                          );
                          _storeSortPreferences();
                        },
                        icon: Icon(
                          sortDirection == 'asc'
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sort books',
                        onPressed: () => showSortOptions(context, colorTheme),
                        icon: const Icon(Icons.sort_rounded),
                      ),
                    ],
                  ),
                ),
              if (_selectedIndex == 0 && update.tokenExists == true)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton.filledTonal(
                    tooltip: layout == 'grid'
                        ? 'Switch to list view'
                        : 'Switch to grid view',
                    onPressed: _toggleLayout,
                    icon: Icon(
                      layout == 'grid'
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                    ),
                  ),
                ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              libraryContent,
              const SettingsNew(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: scheme.surfaceContainer,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
