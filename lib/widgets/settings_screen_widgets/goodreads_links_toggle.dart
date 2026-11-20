import 'package:calibre_carte/providers/update_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class GoodreadsLinksToggle extends StatelessWidget {
  const GoodreadsLinksToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final update = Provider.of<Update>(context);
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: Icon(Icons.open_in_new_rounded, color: scheme.primary),
      title: const Text('Link titles and authors to Goodreads'),
      subtitle: const Text('Tap a book or author name to search Goodreads'),
      value: update.goodreadsLinks,
      onChanged: update.changeGoodreadsLinks,
    );
  }
}
