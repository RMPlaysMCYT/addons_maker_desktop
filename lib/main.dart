import 'package:addons_maker_desktop/screens/create_project_screen.dart';
import 'package:addons_maker_desktop/screens/project_workspace.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

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
      home: Builder(
        builder: (innerContext){
        return FScaffold(
        child: Container(
          width: 1280,
          height: 720,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello, Welcome to Minecraft Addons Maker Ultimate!',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Pick up the project where you left at',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FButton(
                        variant: .primary,
                        size: .lg,
                        prefix: const Icon(Icons.folder_open, size: 32),
                        onPress: () async {
                          final folder = await FilePicker.getDirectoryPath();
                          if(folder == null || !innerContext.mounted){
                            return;
                          }
                          await Navigator.of(innerContext).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProjectWorkspaceScreen(
                                projectPath: folder,
                              ),
                            ),
                          );
                        }, // Fill in the actual click logic
                        child: const Text(
                          'Open Project',
                          style: TextStyle(fontSize: 32),
                        ),
                      ),
                      SizedBox(width: 16),
                      FButton(
                        variant: .secondary,
                        size: .lg,
                        prefix: const Icon(Icons.add, size: 32),
                        onPress: () async {
                          final path = await showDialog<String>(
                            context: innerContext,
                            barrierDismissible: false,
                            builder: (_) => const CreateProjectScreen(),
                          );
                          if (path == null || !innerContext.mounted) {
                            return;
                          }
                          await Navigator.of(innerContext).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProjectWorkspaceScreen(
                                projectPath: path,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'New Project',
                          style: TextStyle(fontSize: 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Projects',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  // Placeholder for recent projects list
                  Container(
                    height: 300,
                    color: const Color.fromARGB(255, 21, 21, 21),
                    child: Center(child: Text('No recent projects found.')),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
        },
      ),
    );
  }
}