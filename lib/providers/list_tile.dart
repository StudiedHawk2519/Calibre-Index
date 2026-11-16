import 'package:material_ui/material_ui.dart';

class ListTileProvider extends ChangeNotifier {
  void refreshTile() {
    notifyListeners();
  }
}
