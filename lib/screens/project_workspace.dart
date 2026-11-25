
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import 'editor_screen.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  const ProjectWorkspaceScreen({
    super.key,
    required this.projectPath,
  });

  final String projectPath;

  @override
  State<ProjectWorkspaceScreen> createState() =>
      _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState
    extends State<ProjectWorkspaceScreen> {
  late final String _root;
  late String _currentDirectory;

  List<FileSystemEntity> _entries = [];
  String? _error;

  @override
  void initState() {
    super.initState();

    _root = p.normalize(p.absolute(widget.projectPath));
    _currentDirectory = _root;

    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final entries = await Directory(_currentDirectory)
          .list(followLinks: false)
          .toList();

      entries.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;

        return p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase());
      });

      if (!mounted) return;

      setState(() {
        _entries = entries;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openDirectory(String path) async {
    final normalized = p.normalize(p.absolute(path));

    if (!p.equals(normalized, _root) &&
        !p.isWithin(_root, normalized)) {
      return;
    }

    setState(() {
      _currentDirectory = normalized;
    });

    await _loadFiles();
  }

  Future<void> _openFile(String path) async {
    const editableExtensions = {
      '.json',
      '.jsonc',
      '.js',
      '.ts',
      '.py',
      '.mcfunction',
      '.lang',
      '.txt',
      '.md',
      '.yaml',
      '.yml',
    };

    if (!editableExtensions.contains(
      p.extension(path).toLowerCase(),
    )) {
      setState(() {
        _error = 'This file type is not supported by Raw Editor.';
      });
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(
          projectPath: _root,
          filePath: path,
        ),
      ),
    );

    if (mounted) await _loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(_root)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Project Explorer'),
            subtitle: Text(_currentDirectory),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          if (!p.equals(_currentDirectory, _root))
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('Go to parent folder'),
              onTap: () => _openDirectory(
                p.dirname(_currentDirectory),
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final isDirectory = entry is Directory;

                return ListTile(
                  leading: Icon(
                    isDirectory
                        ? Icons.folder
                        : Icons.description,
                  ),
                  title: Text(p.basename(entry.path)),
                  subtitle: Text(
                    isDirectory ? 'Folder' : 'File',
                  ),
                  onTap: () {
                    if (isDirectory) {
                      _openDirectory(entry.path);
                    } else if (entry is File) {
                      _openFile(entry.path);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
