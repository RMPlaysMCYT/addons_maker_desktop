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




    final name = request.identifier.split(':').last;
    final id = request.identifier;
    final version = request.minecraftFormatVersion;
    final label = request.displayName.trim().isEmpty
      ? name
      : request.displayName.trim();
    final baseblock = <String, Object?> {
      'format_version': version,
      'minecraft:block': {
        'description': {'identifier': id},
        'components': <String, Object?>{
          'minecraft:display_name': label,
          'minecraft:geometry': 'minecraft:geometry.full_block',
          'minecraft:material_instances': {
            '*': {'texture': 'dirt', 'render_method': 'opaque'},
          },
        },
      },
    };

    Map<String, Object?> blockWith(Map<String, Object?> extra){
      final block = Map<String, Object?>.from(baseblock['minecraft:block'] as Map);
      final components = Map<String, Object?>.from(block['components'] as Map);
      components.addAll(extra);
      block['components'] = components;
      return {
        'format_version': version,
        'minecraft:block': block
      };
    }

    final blockPath = p.join(bp, 'blocks', '$name.json');
    final itemPath = p.join(bp, 'items', '$name.json');
    final entityPath = p.join(bp, 'entities', '$name.json');


    
  }
}
