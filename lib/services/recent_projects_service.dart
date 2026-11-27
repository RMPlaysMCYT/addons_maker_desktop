
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class RecentProjectsService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const String _key = 'recent_projects';
  static const int maxRecent = 10;

  Future<List<String>> load() async {
    return await _prefs.getStringList(_key) ?? [];
  }

  Future<List<String>> add(String projectPath) async {
    final path = p.normalize(p.absolute(projectPath));
    final existing = await load();

    final updated = [
      path,
      ...existing.where((item) => !p.equals(item, path)),
    ].take(maxRecent).toList();

    await _prefs.setStringList(_key, updated);
    return updated;
  }

  Future<List<String>> remove(String projectPath) async {
    final existing = await load();

    final updated = existing
        .where((item) => !p.equals(item, projectPath))
        .toList();

    await _prefs.setStringList(_key, updated);
    return updated;
  }
}
