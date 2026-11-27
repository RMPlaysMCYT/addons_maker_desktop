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

    final files = <String, Object>{};
    final baseBlock = <String, Object?> {
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

    switch (request.template){
      case AddonTemplate.basicBlock:
        files[blockPath] = baseBlock;

      case AddonTemplate.geometryBlock:
        files[blockPath] = baseBlock;

      case AddonTemplate.interactiveBlock:
        files[blockPath] = baseBlock;

      case AddonTemplate.crafttingTableBlock:
        files[blockPath] = blockWith({
          'minecraft:crafting_table':{'crafting_tags':['crafting_table', '${id.split(':').first}_crafting']},
      });

      case AddonTemplate.basicItem:
        files[itemPath] = _item(id, label, version);

      case AddonTemplate.attachableItem:
        files[itemPath] = _item(id, label, version);

      case AddonTemplate.basicMob:
        files[entityPath] = _entity(id, version);

      case AddonTemplate.skeletonMob:
        files[entityPath] = _entity(id, version);

      case AddonTemplate.vehicle:
        files[entityPath] = _entity(id, version);
    }
    
    for (final path in files.keys){
      final normalized = p.normalize(path);
      if(!(p.isWithin(root, normalized) || p.equals(root, normalized))){
        throw StateError('Generated Outside the root?');
      }
      if (await File(path).exists() || await Directory(path).exists()) {
        throw FileSystemException('Refusing to overwrite existing content.', path);
      }
    }

    final written = <String>[];

    try{
      for (final entry in files.entries){

      }
    } catch (_) {
      
    }

  }
}
