import 'dart:io';

import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import 'editor_screen.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  const ProjectWorkspaceScreen({super.key, required this.projectPath});

  final String projectPath;

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  String? _selectedFile;

  @override
  Widget build(BuildContext context) {
    final root = p.normalize(p.absolute(widget.projectPath));

    return Scaffold(
      appBar: AppBar(title: Text(p.basename(root))),

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
                Row(children: [
                  Padding(padding: EdgeInsets.all(12), child: FButton(child: Icon(Icons.add), onPress: (){}),),
                  Padding(padding: EdgeInsets.all(12), child: FButton(child: Icon(Icons.arrow_back), onPress: (){}),)
                ]),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      ProjectTreeNode(
                        path: root,
                        depth: 0,
                        selectedFile: _selectedFile,
                        onFileSelected: (file) {
                          setState(() {
                            _selectedFile = file;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedFile == null
                ? const Center(child: Text('Select a file to begin editing'))
                : EditorScreen(
                    key: ValueKey(_selectedFile),
                    projectPath: root,
                    filePath: _selectedFile!,
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
