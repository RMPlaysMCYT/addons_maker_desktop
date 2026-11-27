import 'package:material_ui/material_ui.dart';

import '../../models/addon_tempate.dart';
import '../../services/template_generator.dart';

class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({
    super.key,
    required this.projectPath,
    required this.category,
    required this.onGenerated,
  });
  final String projectPath;
  final AddonCategory category;
  final ValueChanged<String> onGenerated;

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController(text: 'myaddon:custom_item');
  final _displayName = TextEditingController(text: 'My Custom Content');
  AddonTemplate? _selected;
  bool _working = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_selected == null || !_formKey.currentState!.validate()) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final result = await const TemplateGenerator().create(
        TemplateRequestfromUser(
          projectPath: widget.projectPath,
          template: _selected!,
          identifier: _identifier.text.trim(),
          displayName: _displayName.text.trim(),
        ),
      );
      if (!mounted) return;
      widget.onGenerated(result.paths.first);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isScaffold
                ? 'Created source scaffold. ${result.notes}'
                : 'Created ${_selected!.label}. Test in Minecraft.',
          ),
        ),
      );
      widget.onGenerated(result.paths.first);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = AddonTemplate.values
        .where((t) => t.category == widget.category)
        .toList();
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.category.name.toUpperCase()} TEMPLATES',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RadioGroup<AddonTemplate>(
            groupValue: _selected,
            onChanged: (next) => setState(() => _selected = next),
            child: Column(
              children: [
                ...templates.map(
                  (template) => Card(
                    child: RadioListTile<AddonTemplate>(
                      title: Text(template.label),
                      subtitle: Text(
                        '${template.description}${template.requiresFollowUp ? '  • Scaffold' : ''}',
                      ),
                      value: template,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _identifier,
            decoration: const InputDecoration(
              labelText: 'Content identifier',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                RegExp(r'^[a-z][a-z0-9_]*:[a-z][a-z0-9_]*$')
                    .hasMatch((value ?? '').trim())
                ? null
                : 'Example: myaddon:custom_block',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _displayName,
            decoration: const InputDecoration(
              labelText: 'Display name',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _working || _selected == null ? null : _create,
            icon: const Icon(Icons.add),
            label: Text(_working ? 'Creating...' : 'Create template'),
          ),
        ],
      ),
    );
  }
}
