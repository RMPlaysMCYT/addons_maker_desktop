import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:forui/forui.dart' show FButton;
import 'package:url_launcher/url_launcher.dart';

import '../models/framework_config.dart';
import '../services/prerequisite_service.dart';
import '../services/project_generator.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _namespace = TextEditingController();
  final _parent = TextEditingController();
  final _prerequisites = const PrerequisiteService();

  ProjectFramework _framework = ProjectFramework.standard;
  bool _anvilAddon = true;
  bool _anvilScriptApi = false;
  PrerequisiteChoice _choice = PrerequisiteChoice.install;
  String? _selectedExecutable;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.text = 'my_addon';
    _namespace.text = 'myaddon';
  }

  @override
  void dispose() {
    _name.dispose();
    _namespace.dispose();
    _parent.dispose();
    super.dispose();
  }

  Future<void> _selectFolder() async {
    try {
      final directory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Choose projects directory',
      );

      if (!mounted || directory == null) return;

      setState(() {
        _parent.text = directory;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to choose directory: $e';
      });
    }
  }

  Future<void> _chooseExecutable() async {
    try {
      final result = await FilePicker.pickFile(
        dialogTitle: 'Select ${_framework.executable} executable',
        type: FileType.any,
      );

      if (!mounted || result == null || result.path == null) {
        return;
      }

      setState(() {
        _selectedExecutable = result.path;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to select executable: $e';
      });
    }
  }

  Future<void> _openInstallPage() async {
    final url = _framework.installationUrl;
    if (url == null) return;
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        mounted) {
      setState(() => _error = 'Could not open the installation instructions.');
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final request = ProjectCreationRequest(
        name: _name.text,
        namespace: _namespace.text,
        parentDirectory: _parent.text,
        framework: _framework,
        prerequisiteChoice: _choice,
        customExecutable: _choice == PrerequisiteChoice.locate
            ? _selectedExecutable
            : null,
        anvilAddon: _anvilAddon,
        anvilScriptApi: _anvilScriptApi,
      );
      if (_framework != ProjectFramework.standard &&
          _choice == PrerequisiteChoice.locate &&
          !await _prerequisites.isValidCustomExecutable(_selectedExecutable)) {
        throw const FormatException('Choose an existing executable file.');
      }
      final path = await ProjectGenerator(_prerequisites).create(request);
      if (mounted) Navigator.of(context).pop(path);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Create Minecraft Bedrock Project',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose one framework for the new project. Each creates its own configuration; Standard Bedrock needs no external CLI.',
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Project name',
                            hintText: 'my_addon',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return 'Project name is required';
                            if (_framework == ProjectFramework.anvil &&
                                !RegExp(r'^[a-z][a-z0-9_]{0,15}$')
                                    .hasMatch(v)) {
                              return 'Anvil name: 1–16 lowercase a-z, 0-9 or _';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _namespace,
                          decoration: const InputDecoration(
                            labelText: 'Namespace',
                            hintText: 'rm_ma',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final ns = value?.trim() ?? '';
                            if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(ns) ||
                                ns == 'minecraft') {
                              return 'Use a lowercase namespace (not minecraft)';
                            }
                            if (_framework == ProjectFramework.anvil) {
                              if (ns.length > 8)
                                return 'Anvil namespace: at most 8 characters';
                              final initials = ProjectGenerator.projectInitials(
                                _name.text.trim(),
                              );
                              if (_anvilAddon && !ns.endsWith(initials)) {
                                return 'Addon namespace must end with project initials: $initials';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _parent,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Parent projects folder',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Choose a folder'
                                    : null,
                                onTap: _selectFolder,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Browse folder',
                              onPressed: _selectFolder,
                              icon: const Icon(Icons.folder_open),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ProjectFramework>(
                          value: _framework,
                          decoration: const InputDecoration(
                            labelText: 'Development framework',
                            border: OutlineInputBorder(),
                          ),
                          items: ProjectFramework.values
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f.label),
                                ),
                              )
                              .toList(),
                          onChanged: _busy
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _framework = value;
                                    if (value == ProjectFramework.anvil) {
                                      _name.text = 'my_addon';
                                      _namespace.text = 'rm_ma';
                                    }
                                    _choice = PrerequisiteChoice.install;
                                    _selectedExecutable = null;
                                    _error = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _framework.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        if (_framework == ProjectFramework.anvil) ...[
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Minecraft add-on target (--addon)',
                            ),
                            subtitle: const Text(
                              'Require Anvil add-on namespace naming rules',
                            ),
                            value: _anvilAddon,
                            onChanged: _busy
                                ? null
                                : (v) =>
                                      setState(() => _anvilAddon = v ?? true),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Enable Script API (--scriptapi)',
                            ),
                            subtitle: const Text(
                              'Anvil may install npm dependencies during initialization',
                            ),
                            value: _anvilScriptApi,
                            onChanged: _busy
                                ? null
                                : (v) => setState(
                                    () => _anvilScriptApi = v ?? false,
                                  ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_framework == ProjectFramework.standard)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Standard Bedrock requires no external CLI. '
                                'The “install” prerequisite option does not apply. '
                                'This project will contain BP and RP manifests only.',
                              ),
                            ),
                          )
                        else ...[
                          Text(
                            'External compiler prerequisite: ${_framework.executable}',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          RadioListTile<PrerequisiteChoice>(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Install / view official instructions',
                            ),
                            value: PrerequisiteChoice.install,
                            groupValue: _choice,
                            onChanged: _busy
                                ? null
                                : (value) => setState(() => _choice = value!),
                          ),
                          RadioListTile<PrerequisiteChoice>(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Use an existing executable'),
                            value: PrerequisiteChoice.locate,
                            groupValue: _choice,
                            onChanged: _busy
                                ? null
                                : (value) => setState(() => _choice = value!),
                          ),
                          RadioListTile<PrerequisiteChoice>(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Skip (configure later)'),
                            value: PrerequisiteChoice.skip,
                            groupValue: _choice,
                            onChanged: _busy
                                ? null
                                : (value) => setState(() => _choice = value!),
                          ),
                          if (_choice == PrerequisiteChoice.install)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _busy ? null : _openInstallPage,
                                icon: const Icon(Icons.open_in_new),
                                label: const Text(
                                  'Open official installation page',
                                ),
                              ),
                            ),
                          if (_choice == PrerequisiteChoice.locate)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedExecutable ??
                                        'No executable selected',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _busy ? null : _chooseExecutable,
                                  child: const Text('Browse'),
                                ),
                              ],
                            ),
                          Text(
                            _framework == ProjectFramework.anvil
                                ? 'Install opens the official Anvil guide (pip install mcanvil). If the CLI is not available, creation requires installation unless Skip is selected. Skip creates metadata only, not an Anvil-ready project.'
                                : 'Install opens the official setup guide. The app will not silently install tools. You can still create the project and configure the tool later.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FButton(
                      variant: .secondary,
                      onPress: _busy ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FButton(
                      onPress: _busy ? null : _create,
                      child: Text(_busy ? 'Creating...' : 'Create Project'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
