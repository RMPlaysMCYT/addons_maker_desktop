import 'dart:convert';
import 'dart:io';

import './template_installer.dart';

import 'package:path/path.dart' as p;

import '../models/addon_tempate.dart';

class TemplateGenerator {
  const TemplateGenerator();

  static final _identifier = RegExp(r'^[a-z][a-z0-9_]*:[a-z][a-z0-9_]*$');

  Future<GeneratedTemplate> create(TemplateRequestfromUser request) async {
    if (!_identifier.hasMatch(request.identifier) ||
        request.identifier.startsWith('minecraft:')) {
      throw const FormatException(
        'Use a custom identifier such as myaddon:my_block.',
        'minecraft is now a reserved identifier',
      );
    }
    final root = p.normalize(p.absolute(request.projectPath));
    if (!await Directory(root).exists()) {
      throw const FileSystemException('Project Folder does not exist');
    }

    final framework = await _framework(root);
    if (framework == 'anvil') {
      throw UnsupportedError(
        'Anvil Requires Python Source Adaptor, No generated packs were changed',
      );
    }
    if (!{'standard', 'bridge', 'regolith'}.contains(framework)) {
      throw StateError('Cannot Identify the project framework.');
    }
    final (bp, rp) = framework == 'regolith'
        ? await _regolithPacks(root)
        : (p.join(root, 'BP'), p.join(root, 'RP'));
    if (!await File(p.join(bp, 'manifest.json')).exists()) {
      throw FileSystemException('No Behavior Pack manifest found', bp);
    }

    final name = request.identifier.split(':').last;

    // Validate the Resource Pack too.
    if (!await File(p.join(rp, 'manifest.json')).exists()) {
      throw FileSystemException('No Resource Pack manifest found', rp);
    }

    // Use the complete BP + RP installer for
    // the first three supported templates.
    const basicTemplates = {
      AddonTemplate.basicBlock,
      AddonTemplate.basicItem,
      AddonTemplate.basicMob,
    };

    if (basicTemplates.contains(request.template)) {
      return const TemplateInstaller().install(request, bpPath: bp, rpPath: rp);
    }

    final id = request.identifier;
    final version = request.minecraftFormatVersion;
    final label = request.displayName.trim().isEmpty
        ? name
        : request.displayName.trim();

    final files = <String, Object>{};
    final baseBlock = <String, Object?>{
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

    Map<String, Object?> blockWith(Map<String, Object?> extra) {
      final block = Map<String, Object?>.from(
        baseBlock['minecraft:block'] as Map,
      );
      final components = Map<String, Object?>.from(block['components'] as Map);
      components.addAll(extra);
      block['components'] = components;
      return {'format_version': version, 'minecraft:block': block};
    }

    final blockPath = p.join(bp, 'blocks', '$name.json');
    final itemPath = p.join(bp, 'items', '$name.json');
    final entityPath = p.join(bp, 'entities', '$name.json');

    switch (request.template) {
      case AddonTemplate.basicBlock:
        files[blockPath] = baseBlock;

      case AddonTemplate.geometryBlock:
        files[blockPath] = baseBlock;

      case AddonTemplate.interactiveBlock:
        files[blockPath] = baseBlock;

      case AddonTemplate.crafttingTableBlock:
        files[blockPath] = blockWith({
          'minecraft:crafting_table': {
            'crafting_tags': [
              'crafting_table',
              '${id.split(':').first}_crafting',
            ],
          },
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
        files[entityPath] = _vehicle(id, version);
    }

    for (final path in files.keys) {
      final normalized = p.normalize(path);
      if (!(p.isWithin(root, normalized) || p.equals(root, normalized))) {
        throw StateError('Generated Outside the root?');
      }
      if (await File(path).exists() || await Directory(path).exists()) {
        throw FileSystemException(
          'Refusing to overwrite existing content.',
          path,
        );
      }
    }

    final written = <String>[];

    try {
      for (final entry in files.entries) {
        final file = File(entry.key);
        await file.parent.create(recursive: true);
        await file.writeAsString(
          '${const JsonEncoder.withIndent('  ').convert(entry.value)}\n',
          flush: true,
        );
        written.add(file.path);
      }
    } catch (_) {
      for (final path in written.reversed) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      rethrow;
    }

    return GeneratedTemplate(
      paths: written,
      isScaffold: request.template.requiresFollowUp,
      notes: request.template.description,
    );
  }

  static Map<String, Object?> _item(String id, String label, String version) =>
      {
        'format_version': version,
        'minecraft:item': {
          'description': {
            'identifier': id,
            'menu_category': {'category': 'items'},
          },
          'components': {
            'minecraft:display_name': {'value': label},
            'minecraft:max_stack_size': 64,
            'minecraft:icon': {'texture': 'apple'},
          },
        },
      };

  static Map<String, Object?> _entity(String id, String version) => {
    'format_version': version,
    'minecraft:entity': {
      'description': {
        'identifier': id,
        'is_spawnable': true,
        'is_summonable': true,
      },
      'components': {
        'minecraft:type_family': {
          'family': ['mob'],
        },
        'minecraft:health': {'value': 20, 'max': 20},
        'minecraft:physics': {},
        'minecraft:collision_box': {'width': 0.6, 'height': 1.8},
        'minecraft:movement': {'value': 0.2},
        'minecraft:movement.basic': {},
        'minecraft:navigation.walk': {},
        'minecraft:jump.static': {},
        'minecraft:behavior.random_stroll': {'priority': 6},
        'minecraft:behavior.look_at_player': {'priority': 7},
      },
    },
  };

  static Map<String, Object?> _vehicle(String id, String version) => {
    'format_version': version,
    'minecraft:entity': {
      'description': {
        'identifier': id,
        'is_spawnable': true,
        'is_summonable': true,
      },
      'components': {
        'minecraft:health': {'value': 40, 'max': 40},
        'minecraft:physics': {},
        'minecraft:collision_box': {'width': 1.6, 'height': 1.2},
        'minecraft:rideable': {
          'seat_count': 1,
          'seats': [
            {
              'position': [0, 0.5, 0],
            },
          ],
        },
      },
    },
  };

  Future<String> _framework(String root) async {
    final meta = File(p.join(root, '.addons-maker', 'project.json'));
    if (await meta.exists()) {
      try {
        final decoded = jsonDecode(await meta.readAsString());
        if (decoded is Map && decoded['framework'] is String) {
          return decoded['framework'] as String;
        }
      } catch (_) {}
    }
    if (await File(p.join(root, 'anvilconfig.json')).exists()) return 'anvil';
    final config = File(p.join(root, 'config.json'));
    if (await config.exists()) {
      try {
        final decoded = jsonDecode(await config.readAsString());
        if (decoded is Map && decoded['regolith'] is Map) return 'regolith';
        if (decoded is Map &&
            (decoded['bridge'] is Map || decoded['compiler'] is Map))
          return 'bridge';
      } catch (_) {}
    }
    if (await File(p.join(root, 'BP', 'manifest.json')).exists())
      return 'standard';
    return 'unknown';
  }

  Future<(String, String)> _regolithPacks(String root) async {
    final config = jsonDecode(
      await File(p.join(root, 'config.json')).readAsString(),
    );
    if (config is! Map || config['packs'] is! Map) {
      throw const FormatException('Regolith config is missing packs.');
    }
    final packs = config['packs'] as Map;
    final bp = packs['behaviorPack'];
    final rp = packs['resourcePack'];
    if (bp is! String || rp is! String) {
      throw const FormatException('Regolith source pack paths are missing.');
    }
    final bpPath = p.normalize(p.join(root, bp));
    final rpPath = p.normalize(p.join(root, rp));
    for (final path in [bpPath, rpPath]) {
      if (!p.isWithin(root, path)) {
        throw StateError(
          'Regolith pack path must stay inside the project root.',
        );
      }
    }
    return (bpPath, rpPath);
  }
}
