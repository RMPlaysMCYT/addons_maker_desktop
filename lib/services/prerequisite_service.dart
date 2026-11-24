import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/framework_config.dart';

class PrerequisiteService {
  const PrerequisiteService();

  /// Locate an executable, but do not execute user-controlled project code.
  Future<String?> findExecutable(ProjectFramework framework) async {
    final name = framework.executable;
    if (name == null) return null;
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where.exe' : 'which', [name],
        runInShell: false,
      );
      if (result.exitCode != 0) return null;
      for (final line in result.stdout.toString().split(RegExp(r'\r?\n'))) {
        final candidate = line.trim();
        if (candidate.isNotEmpty && await File(candidate).exists()) return candidate;
      }
    } on ProcessException {
      return null;
    }
    return null;
  }

  Future<bool> isValidCustomExecutable(String? path) async =>
      path != null && path.isNotEmpty &&
      await File(p.normalize(path)).exists();

  Future<String?> resolveExecutable(ProjectCreationRequest request) async {
    if (request.framework == ProjectFramework.standard) return null;
    if (request.prerequisiteChoice == PrerequisiteChoice.locate) {
      return await isValidCustomExecutable(request.customExecutable)
          ? p.normalize(request.customExecutable!) : null;
    }
    return findExecutable(request.framework);
  }

  /// Running --help tests invocation; CLI --help can differ between versions.
  Future<bool> canLaunch(String executable) async {
    try {
      final result = await Process.run(executable, ['--help'],
          runInShell: false).timeout(const Duration(seconds: 12));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<String> statusFor(ProjectCreationRequest request) async {
    if (request.framework == ProjectFramework.standard) return 'notRequired';
    final executable = await resolveExecutable(request);
    if (executable == null) return 'notConfigured';
    return await canLaunch(executable) ? 'detected' : 'notConfigured';
  }
}
