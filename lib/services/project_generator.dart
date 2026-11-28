import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/framework_config.dart';
import 'prerequisite_service.dart';

import '../services/pack_artwork_service.dart';

class ProjectGenerator {
  const ProjectGenerator(this.prerequisites);
  final PrerequisiteService prerequisites;

  static final _validNamespace = RegExp(r'^[a-z][a-z0-9_]*$');
  static final _anvilProject = RegExp(r'^[a-z][a-z0-9_]{0,15}$');
  static final _invalidFolderChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  static String projectInitials(String projectName) => projectName
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part.substring(0, 1))
      .join();

  Future<String> create(ProjectCreationRequest request) async {
    final name = request.name.trim();
    final ns = request.namespace.trim();
    if (name.isEmpty ||
        name == '.' ||
        name == '..' ||
        name.endsWith('.') ||
        name.endsWith(' ') ||
        _invalidFolderChars.hasMatch(name) ||
        RegExp(
          r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$',
          caseSensitive: false,
        ).hasMatch(name)) {
      throw const FormatException('Enter a valid project folder name.');
    }
    if (!_validNamespace.hasMatch(ns) || ns.length > 64 || ns == 'minecraft') {
      throw const FormatException(
        'Namespace must start with a lowercase letter, use a-z/0-9/_, and must not be minecraft.',
      );
    }

    // Validate Anvil-specific naming.
    if (request.framework == ProjectFramework.anvil) {
      if (!_anvilProject.hasMatch(name)) {
        throw const FormatException(
          'Anvil project name must be 1-16 lowercase '
          'letters, digits or underscores.',
        );
      }

      if (ns.length > 8) {
        throw const FormatException(
          'Anvil namespace is limited to 8 characters.',
        );
      }

      if (request.anvilAddon && !ns.endsWith(projectInitials(name))) {
        throw FormatException(
          'Anvil namespace must end with the '
          'project initials: ${projectInitials(name)}',
        );
      }
    }

    // Check the parent project directory.
    final parent = Directory(
      p.normalize(p.absolute(request.parentDirectory.trim())),
    );

    if (!await parent.exists()) {
      throw const FileSystemException('Choose an existing parent directory.');
    }

    // Construct the new project path.
    final root = p.normalize(p.join(parent.path, name));

    // Never overwrite another project.
    if (await File(root).exists() || await Directory(root).exists()) {
      throw const FileSystemException(
        'Project already exists. Choose another name.',
      );
    }

    final createdRoot = request.framework == ProjectFramework.anvil
        ? await _createAnvil(request, root, parent.path)
        : await _createBedrockOrOther(request, root);

    final iconBytes = request.packIconPng;

    if (iconBytes != null) {
      const artwork = PackArtworkService();

      // Save the original project artwork.
      await artwork.saveProjectArtwork(
        projectPath: createdRoot,
        packIconPng: iconBytes,
        bugPackIconPng: request.bugPackIconPng,
      );

      // Standard, bridge. and Regolith already have source BP/RP folders.
      if (request.framework != ProjectFramework.anvil) {
        final prefix = request.framework == ProjectFramework.regolith
            ? 'packs'
            : '';

        await artwork.copyToPacks(
          projectPath: createdRoot,
          bpPath: p.join(createdRoot, prefix, 'BP'),
          rpPath: p.join(createdRoot, prefix, 'RP'),
          copyBugIcontoBP: true,
        );
      }
    }

    return createdRoot;
  }

  Future<void> _writeJson(String root, String relative, Object document) async {
    final file = File(p.join(root, relative));
    await file.parent.create(recursive: true);
    await file.writeAsString(FrameworkConfig.prettyJson(document), flush: true);
  }

  Future<String> _createAnvil(
    ProjectCreationRequest request,
    String root,
    String parent,
  ) async {
    final executable = request.prerequisiteChoice == PrerequisiteChoice.skip
        ? null
        : await prerequisites.resolveExecutable(request);
    final installed =
        executable != null && await prerequisites.canLaunch(executable);

    // Skip option produces a metadata-only draft, never a counterfeit anvilconfig.json.
    if (!installed) {
      if (request.prerequisiteChoice != PrerequisiteChoice.skip) {
        throw const FileSystemException(
          'Anvil CLI is not installed or cannot run. Follow the installation guide, '
          'then restart the app or select an existing executable. '
          'Choose Skip only to make an uninitialized draft.',
        );
      }
      await Directory(root).create();
      await _writeJson(
        root,
        '.addons-maker/project.json',
        FrameworkConfig.appMetadata(
          request,
          prerequisiteStatus: 'notConfigured',
          projectStatus: 'pendingInitialization',
        ),
      );
      return root;
    }

    final args = <String>[
      'init',
      request.namespace.trim(),
      request.name.trim(),
      if (request.anvilAddon) '--addon',
      if (request.anvilScriptApi) '--scriptapi',
      if (request.anvilPreview) '--preview',
    ];
    // Avoid constructing any anvilconfig.json by hand. The Anvil CLI owns it.
    final result = await Process.run(
      executable,
      args,
      workingDirectory: parent,
      runInShell: false,
    ).timeout(const Duration(minutes: 5));
    if (result.exitCode != 0) {
      throw FileSystemException(
        'Anvil initialization failed (exit ${result.exitCode}). '
        'stdout: ${result.stdout}\nstderr: ${result.stderr}. '
        'Inspect the target folder if Anvil partially created it.',
        root,
      );
    }
    if (!await File(p.join(root, 'anvilconfig.json')).exists()) {
      throw FileSystemException(
        'Anvil reported success but did not generate anvilconfig.json at the expected location. '
        'Check the CLI output: ${result.stdout}',
        root,
      );
    }

    await _configureAnvil(root, request);

    await _writeJson(
      root,
      '.addons-maker/project.json',
      FrameworkConfig.appMetadata(
        request,
        prerequisiteStatus: 'detected',
        projectStatus: 'ready',
      ),
    );
    return root;
  }

  Future<void> _configureAnvil(
    String root,
    ProjectCreationRequest request,
  ) async {
    final file = File(p.join(root, 'anvilconfig.json'));

    final decoded = jsonDecode(await file.readAsString());

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Anvil configuration.');
    }

    final config = decoded;

    // Preserve the config generated by Anvil.
    if (config['package'] is! Map ||
        config['features'] is! Map ||
        config['build'] is! Map) {
      throw const FormatException('Unsupported Anvil configuration structure.');
    }

    final package = Map<String, dynamic>.from(config['package'] as Map);

    final features = Map<String, dynamic>.from(config['features'] as Map);

    final build = Map<String, dynamic>.from(config['build'] as Map);

    if (request.anvilCompany.isNotEmpty) {
      package['company'] = request.anvilCompany;
    }

    if (request.anvilDisplayName.isNotEmpty) {
      package['display_name'] = request.anvilDisplayName;
    }

    features['scriptapi'] = request.anvilScriptApi;
    features['scriptui'] = request.anvilScriptApi && request.anvilScriptUi;
    features['pbr'] = request.anvilPbr;

    build['preview'] = request.anvilPreview;
    build['minify'] = request.anvilMinify;
    build['local_export'] = request.anvilLocalExport;
    build['add_stamp'] = request.anvilAddStamp;

    config['package'] = package;
    config['features'] = features;
    config['build'] = build;

    // Keep a backup before changing Anvil's own config.
    await file.copy('${file.path}.bak');

    await file.writeAsString(FrameworkConfig.prettyJson(config), flush: true);
  }

  Future<String> _createBedrockOrOther(
    ProjectCreationRequest request,
    String root,
  ) async {
    final uuid = const Uuid();
    final bpUuid = uuid.v4();
    final rpUuid = uuid.v4();
    await Directory(root).create();
    final name = request.name.trim();
    final prefix = request.framework == ProjectFramework.regolith
        ? 'packs/'
        : '';
    await _writeJson(root, '${prefix}BP/manifest.json', {
      'format_version': 2,
      'header': {
        'name': '$name BP',
        'description': '$name behavior pack',
        'uuid': bpUuid,
        'version': [1, 0, 0],
        'min_engine_version': [1, 21, 0],
      },
      'modules': [
        {
          'type': 'data',
          'uuid': uuid.v4(),
          'version': [1, 0, 0],
        },
      ],
      'dependencies': [
        {
          'uuid': rpUuid,
          'version': [1, 0, 0],
        },
      ],
    });
    await _writeJson(root, '${prefix}RP/manifest.json', {
      'format_version': 2,
      'header': {
        'name': '$name RP',
        'description': '$name resource pack',
        'uuid': rpUuid,
        'version': [1, 0, 0],
        'min_engine_version': [1, 21, 0],
      },
      'modules': [
        {
          'type': 'resources',
          'uuid': uuid.v4(),
          'version': [1, 0, 0],
        },
      ],
    });
    for (final part in [
      'BP/entities',
      'BP/items',
      'BP/blocks',
      'RP/models',
      'RP/textures',
    ]) {
      await Directory(p.join(root, prefix, part)).create(recursive: true);
    }
    switch (request.framework) {
      case ProjectFramework.standard:
        break;
      case ProjectFramework.bridge:
        await _writeJson(root, 'config.json', FrameworkConfig.bridge(request));
        break;
      case ProjectFramework.regolith:
        await _writeJson(
          root,
          'config.json',
          FrameworkConfig.regolith(request),
        );
        await Directory(p.join(root, 'packs', 'data')).create(recursive: true);
        break;
      case ProjectFramework.anvil:
        throw StateError('Anvil is handled separately.');
    }
    await _writeJson(
      root,
      '.addons-maker/project.json',
      FrameworkConfig.appMetadata(
        request,
        prerequisiteStatus: await prerequisites.statusFor(request),
        projectStatus: 'ready',
      ),
    );
    return root;
  }
}
