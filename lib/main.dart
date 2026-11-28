import 'package:addons_maker_desktop/screens/about_screen.dart';
import 'package:addons_maker_desktop/screens/create_project_screen.dart';
import 'package:addons_maker_desktop/screens/project_workspace.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:addons_maker_desktop/services/recent_projects_service.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const Application());
}

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    /// Try changing this and hot reloading the application.
    ///
    /// To create a custom theme:
    /// ```shell
    /// dart forui theme create
    /// ```
    final (lightTheme, darkTheme) =
        const <TargetPlatform>{
          .android,
          .iOS,
          .fuchsia,
        }.contains(defaultTargetPlatform)
        ? (FTheme.neutral.light.touch, FTheme.neutral.dark.touch)
        : (FTheme.neutral.light.desktop, FTheme.neutral.dark.desktop);

    return MaterialApp(
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [...FLocalizations.localizationsDelegates],
      theme: lightTheme.toApproximateMaterialTheme(),
      darkTheme: darkTheme.toApproximateMaterialTheme(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => FTheme(
        data: Theme.brightnessOf(context) == .light ? lightTheme : darkTheme,
        child: FToaster(child: FTooltipGroup(child: child!)),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recentService = RecentProjectsService();

  List<String> _recentProjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentProjects();
    _loadAppVersion();
  }

  Future<void> _loadRecentProjects() async {
    try {
      final projects = await _recentService.load();

      if (!mounted) return;

      setState(() {
        _recentProjects = projects;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showError('Cannot load recent projects: $e');
    }
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Project Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openProject(String path) async {
    final root = p.normalize(p.absolute(path));

    if (!await Directory(root).exists()) {
      await _showError('Project folder does not exist:\n$root');
      return;
    }

    try {
      final updated = await _recentService.add(root);

      if (!mounted) return;

      setState(() {
        _recentProjects = updated;
      });

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ProjectWorkspaceScreen(key: ValueKey(root), projectPath: root),
        ),
      );

      if (mounted) {
        await _loadRecentProjects();
      }
    } catch (e) {
      await _showError('Unable to open project: $e');
    }
  }

  Future<void> _pickProject() async {
    try {
      final path = await FilePicker.getDirectoryPath(
        dialogTitle: 'Open Minecraft Bedrock Project',
      );

      if (path == null || !mounted) return;

      await _openProject(path);
    } catch (e) {
      await _showError('Cannot select project: $e');
    }
  }

  Future<void> _createProject() async {
    final path = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateProjectScreen(),
    );

    if (path == null || !mounted) return;

    await _openProject(path);
  }

    Future<void> _aboutScreen() async {
    final path = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AboutScreen(),
    );

    if (path == null || !mounted) return;

    await _openProject(path);
  }

  Future<void> _removeRecentProject(String path) async {
    try {
      final updated = await _recentService.remove(path);

      if (!mounted) return;

      setState(() {
        _recentProjects = updated;
      });
    } catch (e) {
      await _showError('Cannot update recent projects: $e');
    }
  }

  String _appVersion = 'Loading...';

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = 'Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMac = Platform.isMacOS;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyO, control: !isMac, meta: isMac):
            _pickProject,
        SingleActivator(LogicalKeyboardKey.keyN, control: !isMac, meta: isMac):
            _createProject,
      },
      child: Focus(
        autofocus: true,
        child: FScaffold(
          child: LayoutBuilder(
            builder: (context, viewport) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Minecraft Addons Maker Ultimate',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Pick up the project where you left off.',
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 24),

                            Center(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  FButton(
                                    variant: .primary,
                                    prefix: const Icon(Icons.folder_open),
                                    onPress: _pickProject,
                                    child: const Text('Open Project'),
                                  ),
                                  FButton(
                                    variant: .secondary,
                                    prefix: const Icon(Icons.add),
                                    onPress: _createProject,
                                    child: const Text('New Project'),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            const Text(
                              'Recent Projects',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (_loading)
                              const Center(child: CircularProgressIndicator())
                            else if (_recentProjects.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text('No recent projects found.'),
                                  ),
                                ),
                              )
                            else
                              for (final path in _recentProjects)
                                Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.folder_outlined),
                                    title: Text(p.basename(path)),
                                    subtitle: Text(
                                      path,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _openProject(path),
                                    trailing: IconButton(
                                      tooltip: 'Remove from recent list',
                                      icon: const Icon(Icons.close),
                                      onPressed: () =>
                                          _removeRecentProject(path),
                                    ),
                                  ),
                                ),

                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Text(
                                  isMac
                                      ? '⌘+O  Open Project   •   ⌘+N  New Project'
                                      : 'Ctrl+O  Open Project   •   Ctrl+N  New Project',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  'Version $_appVersion',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Expanded(flex: 1, child: Container(),),
                                FButton(
                                  prefix: const Icon(Icons.info),
                                  onPress: _aboutScreen,
                                  child: const Text('About'),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
