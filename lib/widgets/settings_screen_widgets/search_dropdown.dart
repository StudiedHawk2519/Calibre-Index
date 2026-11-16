import 'package:calibre_carte/providers/update_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchDropdown extends StatelessWidget {
  const SearchDropdown({super.key});

  Future<void> _saveSearchFilter(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('searchFilter', value);
  }

  @override
  Widget build(BuildContext context) {
    final Update update = Provider.of<Update>(context);
    final scheme = Theme.of(context).colorScheme;

    return RadioGroup<String>(
      groupValue: update.searchFilter,
      onChanged: (value) async {
        if (value == null) return;
        await _saveSearchFilter(value);
        update.changeSearchFilter(value);
      },
      child: Column(
        children: [
          RadioListTile<String>(
            secondary: Icon(Icons.title_rounded, color: scheme.primary),
            title: const Text('Book title'),
            subtitle: const Text('Match words in each book title'),
            value: 'title',
          ),
          RadioListTile<String>(
            secondary: Icon(Icons.person_rounded, color: scheme.primary),
            title: const Text('Author'),
            subtitle: const Text('Match words in author names'),
            value: 'author',
          ),
          RadioListTile<String>(
            secondary: Icon(Icons.sell_rounded, color: scheme.primary),
            title: const Text('Tags'),
            subtitle: const Text('Match words in book tags'),
            value: 'tags',
          ),
        ],
      ),
    );
  }
}
