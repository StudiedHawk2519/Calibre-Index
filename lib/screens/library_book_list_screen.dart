import 'package:calibre_carte/helpers/books_provider.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class LibraryBookListScreen extends StatefulWidget {
  const LibraryBookListScreen({super.key});

  @override
  State<LibraryBookListScreen> createState() => _LibraryBookListScreenState();
}

class _LibraryBookListScreenState extends State<LibraryBookListScreen> {
  late final Future<List<String>> _libraryEntries =
      BooksProvider.getLibraryTextEntries();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _copyAll() async {
    try {
      final entries = await _libraryEntries;
      await Clipboard.setData(ClipboardData(text: entries.join('\n')));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entries.length} books copied')),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not copy the library list: $error')),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not copy the library list: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library book list'),
        actions: [
          IconButton(
            tooltip: 'Copy full list',
            onPressed: _copyAll,
            icon: const Icon(Icons.copy_all_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _libraryEntries,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load the library list. Connect a Calibre library '
                  'and try again.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? const <String>[];
          final filteredEntries = entries
              .where(
                  (entry) => entry.toLowerCase().contains(_query.toLowerCase()))
              .toList(growable: false);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search this list',
                  leading: const Icon(Icons.search_rounded),
                  onChanged: (value) => setState(() => _query = value.trim()),
                  trailing: _query.isEmpty
                      ? null
                      : [
                          IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filteredEntries.length} of ${entries.length} books',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: filteredEntries.isEmpty
                    ? Center(
                        child: Text(
                          entries.isEmpty
                              ? 'This library has no books.'
                              : 'No books match your search.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredEntries.length,
                        scrollCacheExtent: const ScrollCacheExtent.pixels(400),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16),
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SelectableText(
                            filteredEntries[index],
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
