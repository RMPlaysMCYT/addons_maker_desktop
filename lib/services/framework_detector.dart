import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/framework_config.dart';

/// Read-only detection for *existing* projects. Never rewrites config.json.
class FrameworkDetector {
  const FrameworkDetector();

  Future<ProjectFramework?> detect(String root) async {
    final anvil = File(p.join(root, 'anvilconfig.json'));
    if (await anvil.exists()) return ProjectFramework.anvil;

    final configuration = File(p.join(root, 'config.json'));
    if (await configuration.exists()) {
      try {
        final json = jsonDecode(await configuration.readAsString());
        if (json is Map<String, dynamic>) {
          final regolith = json['regolith'] is Map;
          final dash = json['bridge'] is Map || json['compiler'] is Map;
          // A mixed configuration needs an explicit user selection.
          if (regolith && dash) return null;
          if (regolith) return ProjectFramework.regolith;
          if (dash) return ProjectFramework.bridge;
        }
      } on FormatException {
        return null;
      } on FileSystemException {
        return null;
      }
    }

    if (await File(p.join(root, 'BP', 'manifest.json')).exists() ||
        await File(p.join(root, 'RP', 'manifest.json')).exists()) {
      return ProjectFramework.standard;
    }
    return null;
  }
}
