import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_ui/material_ui.dart';

class Update with ChangeNotifier {
  bool? _tokenExists;
  bool _shouldUpdate = false;
  bool _matchOriginalCoverSize;
  bool _showCoverTitles;
  int _gridColumns;
  double _coverCornerRadius;
  bool _stackSeries;
  String _bookLayout;

  Update(
    this._tokenExists, {
    bool matchOriginalCoverSize = true,
    bool showCoverTitles = true,
    int gridColumns = 2,
    double coverCornerRadius = 24,
    bool stackSeries = false,
    String bookLayout = 'list',
  })  : _matchOriginalCoverSize = matchOriginalCoverSize,
        _showCoverTitles = showCoverTitles,
        _gridColumns = gridColumns.clamp(2, 5).toInt(),
        _coverCornerRadius = coverCornerRadius.clamp(0, 40),
        _stackSeries = stackSeries,
        _bookLayout = bookLayout;

  void changeTokenState(bool tokenStateFlag) {
    _tokenExists = tokenStateFlag;
    notifyListeners();
  }

  void updateFlagState(bool updateFlag) {
    _shouldUpdate = updateFlag;
    notifyListeners();
  }

  Future<void> changeMatchOriginalCoverSize(bool value) async {
    if (_matchOriginalCoverSize == value) return;
    _matchOriginalCoverSize = value;
    await _saveBool('matchOriginalCoverSize', value);
    notifyListeners();
  }

  Future<void> changeShowCoverTitles(bool value) async {
    if (_showCoverTitles == value) return;
    _showCoverTitles = value;
    await _saveBool('showCoverTitles', value);
    notifyListeners();
  }

  Future<void> changeGridColumns(int value) async {
    final columns = value.clamp(2, 5).toInt();
    if (_gridColumns == columns) return;
    _gridColumns = columns;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('gridColumns', columns);
    notifyListeners();
  }

  Future<void> changeCoverCornerRadius(double value) async {
    final radius = value.clamp(0, 40).toDouble();
    if (_coverCornerRadius == radius) return;
    _coverCornerRadius = radius;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble('coverCornerRadius', radius);
    notifyListeners();
  }

  Future<void> changeStackSeries(bool value) async {
    if (_stackSeries == value) return;
    _stackSeries = value;
    await _saveBool('stackSeries', value);
    notifyListeners();
  }

  Future<void> changeBookLayout(String value) async {
    if (value != 'grid' && value != 'list') return;
    if (_bookLayout == value) return;
    _bookLayout = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('layout', value);
    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }

  void shouldDoUpdateFalse() {
    _shouldUpdate = false;
  }

  bool? get tokenExists {
    return _tokenExists;
  }

  bool get shouldDoUpdate {
    return _shouldUpdate;
  }

  bool get matchOriginalCoverSize => _matchOriginalCoverSize;
  bool get showCoverTitles => _showCoverTitles;
  int get gridColumns => _gridColumns;
  double get coverCornerRadius => _coverCornerRadius;
  bool get stackSeries => _stackSeries;
  String get bookLayout => _bookLayout;
}
