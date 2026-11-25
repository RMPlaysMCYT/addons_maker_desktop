import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:re_editor/re_editor.dart';

import '../screens/editor/raw_editor_screen.dart';
import '../screens/editor/visual_editor_screen.dart';

enum EditorMode { raw, visual }

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.projectPath,
    required this.filePath,
  });

  final String projectPath;
  final String filePath;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  EditorMode _mode = EditorMode.raw;

  CodeLineEditingController? _controller;

  bool _loading = true;
  bool _dirty = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final content = await File(widget.filePath).readAsString();

      if (!mounted) return;

      setState(() {
        _controller = CodeLineEditingController.fromText(content);
        _dirty = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _markDirty() {
    if (!mounted) return;

    setState(() => _dirty = true);
  }

  Future<void> _saveFile() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      await File(widget.filePath).writeAsString(controller.text, flush: true);

      if (!mounted) return;

      setState(() {
        _dirty = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.description_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.basename(widget.filePath),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_dirty) const Text('● Modified'),
                IconButton(
                  tooltip: 'Save',
                  onPressed: _controller == null ? null : _saveFile,
                  icon: const Icon(Icons.save_outlined),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<EditorMode>(
              segments: const [
                ButtonSegment(
                  value: EditorMode.raw,
                  icon: Icon(Icons.code),
                  label: Text('Raw Editor'),
                ),
                ButtonSegment(
                  value: EditorMode.visual,
                  icon: Icon(Icons.tune),
                  label: Text('Visual Editor'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() => _mode = selection.first);
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _controller == null
                ? const Center(child: Text('Unable to open file'))
                : _mode == EditorMode.raw
                ? RawEditorScreen(controller: _controller!)
                : VisualEditorScreen(source: _controller!.text),
          ),
        ],
      ),
    );
  }
}
