// FUCK YOU TILL I put you in trypophobia state 
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import '../models/addon_tempate.dart';

class TemplateInstaller {
  const TemplateInstaller();

  static const _assets = 'assets/bedrock_templates';
  static final _idPattern = RegExp(r'^[a-z][a-z0-9_]*:[a-z][a-z0-9_]*$');

  Future<GeneratedTemplate> install(
    TemplateRequestfromUser request, {
    required String bpPath,
    required String rpPath,
  }) async {
    final id = request.identifier.trim();
    if (!_idPattern.hasMatch(id) || id.startsWith('minecraft:')) {
      throw const FormatException('Use an identifier such as myaddon:my_block.');
    }

    final ns = id.split(':').first;
    final name = id.split(':').last;
    final label = request.displayName.trim().isEmpty
        ? name.replaceAll('_', ' ')
        : request.displayName.trim();
    final alias = '${ns}_$name';

    if (!await File(p.join(bpPath, 'manifest.json')).exists() ||
        !await File(p.join(rpPath, 'manifest.json')).exists()) {
      throw const FileSystemException('Existing BP and RP manifests are required.');
    }

    final newFiles = <String, Uint8List>{};
    final sharedFiles = <String, Uint8List>{};
    final languageEntries = <String, String>{};
    final assetPath = p.join(rpPath, 'textures');
    String mainFile;

    switch (request.template) {
      case AddonTemplate.basicBlock:
        mainFile = p.join(bpPath, 'blocks', '$name.json');
        newFiles[mainFile] = await _loadJsonTemplate(
          '$_assets/basic_block/BP/blocks/basic_block.json',
          {
            'rmstarter:basic_block': id,
            'rmstarter_basic_block': alias,
          },
          formatVersion: request.minecraftFormatVersion,
        );
        newFiles[p.join(assetPath, 'blocks', ns, '$name.png')] =
            await _loadAsset('$_assets/basic_block/RP/textures/blocks/basic_block.png');
        await _mergeAtlas(
          sharedFiles,
          p.join(assetPath, 'terrain_texture.json'),
          alias: alias,
          texture: 'textures/blocks/$ns/$name',
          atlas: 'atlas.terrain',
        );
        await _mergeJsonEntry(
          sharedFiles,
          p.join(rpPath, 'blocks.json'),
          id,
          {'sound': 'stone'},
          defaults: {'format_version': '1.19.30'},
        );
        languageEntries['tile.$id.name'] = label;

      case AddonTemplate.basicItem:
        mainFile = p.join(bpPath, 'items', '$name.json');
        newFiles[mainFile] = await _loadJsonTemplate(
          '$_assets/basic_item/BP/items/basic_item.json',
          {
            'rmstarter:basic_item': id,
            'rmstarter_basic_item': alias,
          },
          formatVersion: request.minecraftFormatVersion,
        );
        newFiles[p.join(assetPath, 'items', ns, '$name.png')] =
            await _loadAsset('$_assets/basic_item/RP/textures/items/basic_item.png');
        await _mergeAtlas(
          sharedFiles,
          p.join(assetPath, 'item_texture.json'),
          alias: alias,
          texture: 'textures/items/$ns/$name',
          atlas: 'atlas.items',
        );
        languageEntries['item.$id.name'] = label;

      case AddonTemplate.basicMob:
        mainFile = p.join(bpPath, 'entities', '$name.json');
        final replacements = <String, String>{
          'rmstarter:basic_mob': id,
          'rmstarter_basic_mob': alias,
          'geometry.rmstarter.basic_mob': 'geometry.$ns.$name',
          'textures/entity/basic_mob': 'textures/entity/$ns/$name',
        };
        newFiles[mainFile] = await _loadJsonTemplate(
          '$_assets/basic_mob/BP/entities/basic_mob.json',
          replacements,
        );
        newFiles[p.join(rpPath, 'entity', '$name.entity.json')] =
            await _loadJsonTemplate(
              '$_assets/basic_mob/RP/entity/basic_mob.entity.json',
              replacements,
            );
        newFiles[p.join(rpPath, 'models', 'entity', '$name.geo.json')] =
            await _loadJsonTemplate(
              '$_assets/basic_mob/RP/models/entity/basic_mob.geo.json',
              replacements,
            );
        newFiles[p.join(assetPath, 'entity', ns, '$name.png')] =
            await _loadAsset('$_assets/basic_mob/RP/textures/entity/basic_mob.png');
        languageEntries['entity.$id.name'] = label;
        languageEntries['item.spawn_egg.entity.$id.name'] = 'Spawn $label';

      default:
        throw UnsupportedError(
          'Only Basic Block, Basic Item and Basic Mob use this installer.',
        );
    }

    await _mergeLang(
      sharedFiles,
      p.join(rpPath, 'texts', 'en_US.lang'),
      languageEntries,
    );
    await _mergeLanguagesJson(
      sharedFiles,
      p.join(rpPath, 'texts', 'languages.json'),
    );

    for (final filename in newFiles.keys) {
      if (await File(filename).exists() || await Directory(filename).exists()) {
        throw FileSystemException('Content already exists; choose another identifier.', filename);
      }
    }

    final planned = <String, Uint8List>{...newFiles, ...sharedFiles};
    final previous = <String, Uint8List?>{};
    for (final path in planned.keys) {
      previous[path] = await File(path).exists() ? await File(path).readAsBytes() : null;
    }
    final written = <String>[];
    try {
      for (final entry in planned.entries) {
        final file = File(entry.key);
        await file.parent.create(recursive: true);
        written.add(file.path);
        await file.writeAsBytes(entry.value, flush: true);
      }
    } catch (_) {
      for (final filename in written.reversed) {
        try {
          final old = previous[filename];
          if (old == null) {
            if (await File(filename).exists()) await File(filename).delete();
          } else {
            await File(filename).writeAsBytes(old, flush: true);
          }
        } catch (_) {
        }
      }
      rethrow;
    }

    return GeneratedTemplate(
      paths: [mainFile, ...planned.keys.where((path) => path != mainFile)],
      isScaffold: request.template == AddonTemplate.basicMob,
      notes: 'Created BP/RP files and merged en_US.lang without replacing unrelated entries.',
    );
  }

  static Future<Uint8List> _loadAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  static Future<Uint8List> _loadJsonTemplate(
    String path,
    Map<String, String> replacements, {
    String? formatVersion,
  }) async {
    var contents = await rootBundle.loadString(path);
    for (final replacement in replacements.entries) {
      contents = contents.replaceAll(replacement.key, replacement.value);
    }
    final data = jsonDecode(contents);
    if (data is! Map<String, dynamic>) throw FormatException('Bad template JSON: $path');
    if (formatVersion != null) data['format_version'] = formatVersion;
    return _asJsonBytes(data);
  }

  static Uint8List _asJsonBytes(Object data) => Uint8List.fromList(
    utf8.encode('${const JsonEncoder.withIndent('  ').convert(data)}\n'),
  );

  static Future<Map<String, dynamic>> _readJsonObject(
    String filename, {
    Map<String, dynamic>? defaults,
  }) async {
    final file = File(filename);
    if (!await file.exists()) return {...?defaults};
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected JSON object: $filename');
    }
    return decoded;
  }

  static Future<void> _mergeJsonEntry(
    Map<String, Uint8List> writes,
    String filename,
    String key,
    Object value, {
    Map<String, dynamic>? defaults,
  }) async {
    final doc = await _readJsonObject(filename, defaults: defaults);
    if (doc.containsKey(key)) {
      throw FileSystemException('Entry already exists in shared JSON.', filename);
    }
    doc[key] = value;
    writes[filename] = _asJsonBytes(doc);
  }

  static Future<void> _mergeAtlas(
    Map<String, Uint8List> writes,
    String filename, {
    required String alias,
    required String texture,
    required String atlas,
  }) async {
    final doc = await _readJsonObject(filename, defaults: {
      'resource_pack_name': 'generated',
      'texture_name': atlas,
      'texture_data': <String, dynamic>{},
    });
    if (doc['texture_name'] != atlas) {
      throw FormatException('Unexpected atlas type in $filename');
    }
    final sourceData = doc['texture_data'];
    if (sourceData is! Map) {
      throw FormatException('Invalid texture_data in $filename');
    }
    final entries = Map<String, dynamic>.from(sourceData);
    if (entries.containsKey(alias)) {
      throw FileSystemException('Texture alias already exists.', filename);
    }
    entries[alias] = {'textures': texture};
    doc['texture_data'] = entries;
    writes[filename] = _asJsonBytes(doc);
  }

  static Future<void> _mergeLang(
    Map<String, Uint8List> writes,
    String filename,
    Map<String, String> entries,
  ) async {
    final file = File(filename);
    final oldText = await file.exists() ? await file.readAsString() : '';
    final lineBreak = oldText.contains('\r\n') ? '\r\n' : '\n';
    final lines = oldText.isEmpty
        ? <String>[]
        : oldText.replaceAll('\r\n', '\n').split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();

    for (final entry in entries.entries) {
      final index = lines.indexWhere((line) => line.startsWith('${entry.key}='));
      final sanitized = entry.value.replaceAll(RegExp(r'[\r\n]'), ' ').trim();
      final line = '${entry.key}=$sanitized';
      if (index >= 0) {
        lines[index] = line;
        // Remove only duplicate occurrences of THIS key; preserve all others.
        for (var i = lines.length - 1; i > index; i--) {
          if (lines[i].startsWith('${entry.key}=')) lines.removeAt(i);
        }
      } else {
        lines.add(line);
      }
    }
    writes[filename] = Uint8List.fromList(utf8.encode('${lines.join(lineBreak)}$lineBreak'));
  }

  static Future<void> _mergeLanguagesJson(
    Map<String, Uint8List> writes,
    String filename,
  ) async {
    final file = File(filename);
    final value = await file.exists()
        ? jsonDecode(await file.readAsString())
        : <dynamic>[];
    if (value is! List) throw FormatException('Expected languages JSON list: $filename');
    final languages = List<String>.from(value);
    if (!languages.contains('en_US')) languages.add('en_US');
    writes[filename] = _asJsonBytes(languages);
  }
}
