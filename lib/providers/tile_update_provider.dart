import 'package:cupertino_ui/cupertino_ui.dart';

class UpdateTile with ChangeNotifier {
  bool _updateTile = false;

  bool get updateTile => _updateTile;

  void shouldUpdateTile() {
    _updateTile = true;
    notifyListeners();
  }
}
