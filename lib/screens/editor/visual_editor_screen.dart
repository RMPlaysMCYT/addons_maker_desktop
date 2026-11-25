
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

class VisualEditorScreen extends StatelessWidget {
  const VisualEditorScreen({
    super.key,
    required this.source,
  });

  final String source;

  @override
  Widget build(BuildContext context) {
    try {
      final json = jsonDecode(source);

      if (json is! Map<String, dynamic>) {
        return const Center(
          child: Text('Unsupported document structure'),
        );
      }

      final entity = json['minecraft:entity'];

      if (entity is! Map) {
        return const Center(
          child: Text(
            'Visual editing is not available for this file yet.',
          ),
        );
      }

      final description = entity['description'];
      final components = entity['components'];

      final identifier = description is Map
          ? description['identifier']?.toString() ?? ''
          : '';

      final health = components is Map
          ? components['minecraft:health']
          : null;

      final hp = health is Map
          ? health['value']?.toString() ?? ''
          : '';

      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Entity Overview',
            style: TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 20),

          TextFormField(
            initialValue: identifier,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Identifier',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            initialValue: hp,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Health',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Visual editing is currently read-only. '
            'Use Raw Editor to modify this file.',
          ),
        ],
      );
    } catch (_) {
      return const Center(
        child: Text('Invalid JSON document'),
      );
    }
  }
}
