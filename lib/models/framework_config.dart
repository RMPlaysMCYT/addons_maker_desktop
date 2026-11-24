import 'dart:convert';

enum ProjectFramework { standard, bridge, regolith, anvil }
enum PrerequisiteChoice { install, locate, skip }

extension ProjectFrameworkDetails on ProjectFramework {
  String get label => switch (this) {
    ProjectFramework.standard => 'Standard Bedrock',
    ProjectFramework.bridge => 'bridge. v2 / Dash',
    ProjectFramework.regolith => 'Regolith',
    ProjectFramework.anvil => 'Anvil (StarkTMA)',
  };
  String get description => switch (this) {
    ProjectFramework.standard => 'Native behavior/resource packs; no external compiler.',
    ProjectFramework.bridge => 'bridge. v2 project with Dash configuration and optional standalone Dash CLI.',
    ProjectFramework.regolith => 'Regolith pack sources, configuration and named build profiles.',
    ProjectFramework.anvil => 'Python-first project; initialized by the installed Anvil CLI.',
  };
  String get id => switch (this) {
    ProjectFramework.standard => 'standard',
    ProjectFramework.bridge => 'bridge',
    ProjectFramework.regolith => 'regolith',
    ProjectFramework.anvil => 'anvil',
  };
  String? get executable => switch (this) {
    ProjectFramework.standard => null,
    ProjectFramework.bridge => 'dash_compiler',
    ProjectFramework.regolith => 'regolith',
    ProjectFramework.anvil => 'anvil',
  };
  Uri? get installationUrl => switch (this) {
    ProjectFramework.standard => null,
    ProjectFramework.bridge => Uri.parse('https://github.com/bridge-core/deno-dash-compiler'),
    ProjectFramework.regolith => Uri.parse('https://regolith-docs.readthedocs.io/en/stable/introduction/installation/'),
    ProjectFramework.anvil => Uri.parse('https://github.com/StarkTMA/Anvil#installation'),
  };
}

class ProjectCreationRequest {
  const ProjectCreationRequest({
    required this.name,
    required this.namespace,
    required this.parentDirectory,
    required this.framework,
    required this.prerequisiteChoice,
    this.customExecutable,
    this.anvilScriptApi = false,
    this.anvilAddon = true,
  });
  final String name;
  final String namespace;
  final String parentDirectory;
  final ProjectFramework framework;
  final PrerequisiteChoice prerequisiteChoice;
  final String? customExecutable;
  final bool anvilScriptApi;
  final bool anvilAddon;
}

class FrameworkConfig {
  static Map<String, Object?> appMetadata(
    ProjectCreationRequest request, {
    required String prerequisiteStatus,
    required String projectStatus,
  }) => {
    'schemaVersion': 1,
    'projectType': 'minecraftBedrock',
    'framework': request.framework.id,
    'buildAdapter': switch (request.framework) {
      ProjectFramework.standard => 'builtin',
      ProjectFramework.bridge => 'dash',
      ProjectFramework.regolith => 'regolith',
      ProjectFramework.anvil => 'anvil',
    },
    'projectStatus': projectStatus,
    'buildProfile': 'default',
    'prerequisites': {
      if (request.framework.executable != null)
        request.framework.executable!: prerequisiteStatus,
    },
    if (request.framework == ProjectFramework.anvil) 'anvilOptions': {
      'addon': request.anvilAddon,
      'scriptapi': request.anvilScriptApi,
      'generatedBy': projectStatus == 'ready' ? 'anvil init' : 'none',
    },
    if (request.customExecutable != null)
      'customExecutable': request.customExecutable,
  };

  static Map<String, Object?> bridge(ProjectCreationRequest request) => {
    'type': 'minecraftBedrock',
    'name': request.name.trim(),
    'namespace': request.namespace.trim(),
    'packs': {'behaviorPack': './BP', 'resourcePack': './RP'},
    'compiler': {'plugins': <Object>[]},
    'bridge': <String, Object>{},
  };

  static Map<String, Object?> regolith(ProjectCreationRequest request) => {
    r'$schema': 'https://raw.githubusercontent.com/Bedrock-OSS/regolith-schemas/main/config/v1.4.json',
    'name': request.name.trim(),
    'packs': {'behaviorPack': './packs/BP', 'resourcePack': './packs/RP'},
    'regolith': {
      'dataPath': './packs/data',
      'filterDefinitions': <String, Object>{},
      'formatVersion': '1.4.0',
      'profiles': {
        'default': {
          'export': {'build': 'standard', 'readOnly': false, 'target': 'development'},
          'filters': <Object>[],
        },
      },
    },
  };

  static String prettyJson(Object value) =>
      '${const JsonEncoder.withIndent('  ').convert(value)}\n';
}
