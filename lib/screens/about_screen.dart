import 'package:material_ui/material_ui.dart';
import 'package:forui/forui.dart' show FButton;

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 1280,
        height: 720,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'About the application',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Addons Maker Ultimate',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              const Text('Version 1.0.0', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 16),
              const Text(
                'Developed by RMPlaysMCYT',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              const Text(
                'THIS APPLICATION/PROGRAM IS NOT AFFILIATED/ENDORSED BY MOJANG STUDIOS/ MICROSOFT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
