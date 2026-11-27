import 'dart:io';

import 'package:addons_maker_desktop/models/addon_tempate.dart';
import 'package:flutter/foundation.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import 'project_overview.dart';
import 'editor_screen.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  const ProjectWorkspaceScreen({super.key, required this.projectPath});

  final String projectPath;

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  final List<String> _openTabs = [];
  String? _activeFile;
  AddonCategory? _selectedCategory;

  void _openFileTab(String file) {
    setState(() {
      _selectedCategory = null;
      if (!_openTabs.contains(file)) {
        _openTabs.add(file);
      }
      _activeFile = file;
    });
  }

  void _selectTab(String file) {
    if (!_openTabs.contains(file)) return;
    setState(() {
      _selectedCategory = null;
      _activeFile = file;
    });
  }

  void _closeTab(String file) {
    final closedIndex = _openTabs.indexOf(file);
    if (closedIndex == -1) return;

    setState(() {
      _openTabs.removeAt(closedIndex);
      if (_activeFile == file) {
        if (_openTabs.isEmpty) {
          _activeFile = null;
        } else {
          final nextIndex = closedIndex >= _openTabs.length
              ? _openTabs.length - 1
              : closedIndex;
          _activeFile = _openTabs[nextIndex];
        }
      }
    });
  }

  void _showOverview() {
    setState(() {
      _activeFile = null;
      _selectedCategory = null;      
    });
  }

  void _openCategory(String name) {
    final category = switch (name) {
      'Blocks' => AddonCategory.blocks,
      'Items' => AddonCategory.items,
      'Entities' => AddonCategory.entities,
      _ => null,
    };

    if (category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name is not implemented yet')));
      return;
    }

    setState(() {
      _selectedCategory = category;
      _activeFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final root = p.normalize(p.absolute(widget.projectPath));

    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(root)),
        actions: [
          IconButton(
            tooltip: 'Project overview',
            icon: const Icon(Icons.home_outlined),
            onPressed: () {
              setState(() {
                _activeFile = null;
              });
            },
          ),
        ],
      ),

      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'EXPLORER',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: FButton(child: Icon(Icons.add), onPress: () {}),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: FButton(
                        child: Icon(Icons.arrow_back),
                        onPress: () {},
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      ProjectTreeNode(
                        path: root,
                        depth: 0,
                        selectedFile: _activeFile,
                        onFileSelected: _openFileTab,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),

          Expanded(
            child: Column(
              children: [
                // Tab bar
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Project Overview tab
                      TextButton.icon(
                        onPressed: _showOverview,
                        icon: const Icon(Icons.home_outlined, size: 16),
                        label: const Text('Overview'),
                      ),

                      for (final file in _openTabs)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _activeFile == file
                                ? Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh
                                : null,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => _selectTab(file),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(p.basename(file)),
                                  ],
                                ),
                              ),

                              IconButton(
                                tooltip: 'Close tab',
                                icon: const Icon(Icons.close, size: 15),
                                onPressed: () => _closeTab(file),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Active editor or Project Overview
                Expanded(
                  child: _activeFile == null
                      ? ProjectOverview(
                          projectPath: root,
                          onCategorySelected: (category) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$category visual editor '
                                  'is not connected yet',
                                ),
                              ),
                            );
                          },
                        )
                      : EditorScreen(
                          key: ValueKey(_activeFile),
                          projectPath: root,
                          filePath: _activeFile!,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectTreeNode extends StatelessWidget {
  const ProjectTreeNode({
    super.key,
    required this.path,
    required this.depth,
    required this.onFileSelected,
    this.selectedFile,
  });
  final String path;
  final int depth;
  final String? selectedFile;
  final ValueChanged<String> onFileSelected;

  static const editableExtenstions = {
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
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FileSystemEntity>>(
      future: _readDirectory(path),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Cannot red directory'),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          );
        }

        return ExpansionTile(
          initiallyExpanded: depth == 0,
          tilePadding: EdgeInsets.only(left: 4.0 + depth * 10, right: 8),
          leading: const Icon(Icons.folder, size: 18),
          title: Text(
            p.basename(path),
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          childrenPadding: EdgeInsets.zero,
          children: [
            for (final entry in snapshot.data!)
              if (entry is Directory)
                ProjectTreeNode(
                  key: ValueKey(entry.path),
                  path: entry.path,
                  depth: depth + 1,
                  selectedFile: selectedFile,
                  onFileSelected: onFileSelected,
                )
              else if (entry is File)
                ListTile(
                  dense: true,
                  minTileHeight: 30,
                  contentPadding: EdgeInsets.only(
                    left: 24.0 + depth * 10,
                    right: 8,
                  ),
                  leading: const Icon(Icons.description_outlined, size: 16),
                  title: Text(
                    p.basename(entry.path),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: selectedFile == entry.path,
                  onTap: () {
                    if (editableExtenstions.contains(
                      p.extension(entry.path).toLowerCase(),
                    )) {
                      onFileSelected(entry.path);
                    }
                  },
                ),
          ],
        );
      },
    );
  }

  Future<List<FileSystemEntity>> _readDirectory(String directory) async {
    final entries = await Directory(directory)
        .list(followLinks: false)
        .where((entry) => entry is! Link)
        .toList();

    entries.sort((a, b) {
      if (a is Directory && b is! Directory) {
        return -1;
      }
      if (a is! Directory && b is Directory) {
        return 1;
      }
      return p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase());
    });
    return entries;
  }
}
