import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/addon_tempate.dart';

class TemplateGenerator {
  const TemplateGenerator();

  static final _identifier = RegExp(r'^[a-z][a-z0-9_]*:[a-z][a-z0-9_]*$');

  Future<GeneratedTemplate> create(TemplateRequestfromUser request) async {
    if (_identifier.hasMatch(request.identifier) ||
        request.identifier.startsWith('minecraft:')) {
      throw const FormatException(
        'Use a custom identifier such as myaddon:my_block. minecraft is now a reserved identifier',
      );
    }
    final root = p.normalize(p.absolute(request.projectPath));
    if(!await Directory(root).exists()){
      throw const FileSystemException('Project Folder does not exist');
    }

    final framework = await _framework(root)
    if(framework == 'anvil'){
      throw UnsupportedError('Anvil Requires Python Source Adaptor, No generated packs were changed');
    }
    if(!{'standard', 'bridge', 'regolith'}.contains(framework)){
      throw StateError('Cannot Identify the project framework.');
    }
    final(bp, rp) = framework == 'regolith'
    ? await _regolithPacks(root)
    : (p.join(root, 'BP'), p.join(root, 'RP'));
    if(!await File(p.join(bp, 'manifest.json')).exists()){
      throw FileSystemException('No Behavior Pack manifest found', bp);
    }






  }
}
