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
      builder: (context, child) => FTheme(
        data: Theme.brightnessOf(context) == .light ? lightTheme : darkTheme,
        child: FToaster(child: FTooltipGroup(child: child!)),
      ),
      home: FScaffold(
        child: Container(
          width: 1280,
          height: 720,
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hello, Welcome to Minecraft Addons Maker Ultimate!',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Pick up the project where you left at',
                    style: TextStyle(fontSize: 16),
                  ),
                  FButton(
                    onPress: () {}, // Fill in the actual click logic
                    child: const Text('Open Project'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
