
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

class RawEditorScreen extends StatelessWidget {
  const RawEditorScreen({
    super.key,
    required this.controller,
  });

  final CodeLineEditingController controller;

  static const List<CodePrompt> bedrockPrompts = [
    CodeFieldPrompt(
      word: 'format_version',
      type: 'String',
    ),
    CodeFieldPrompt(
      word: 'minecraft:entity',
      type: 'Object',
    ),
    CodeFieldPrompt(
      word: 'minecraft:item',
      type: 'Object',
    ),
    CodeFieldPrompt(
      word: 'minecraft:block',
      type: 'Object',
    ),
    CodeFieldPrompt(
      word: 'minecraft:health',
      type: 'Object',
    ),
    CodeFieldPrompt(
      word: 'minecraft:movement',
      type: 'Object',
    ),
    CodeFieldPrompt(
      word: 'minecraft:collision_box',
      type: 'Object',
    ),
    CodeFieldPrompt(
      word: 'minecraft:physics',
      type: 'Object',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CodeAutocomplete(
      promptsBuilder:
          DefaultCodeAutocompletePromptsBuilder(
        directPrompts: bedrockPrompts,
      ),
      viewBuilder: (context, notifier, onSelected) {
        return PreferredSize(
          preferredSize: const Size(320, 220),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: ValueListenableBuilder(
              valueListenable: notifier,
              builder: (context, value, _) {
                final prompts = value.prompts.take(8).toList();

                return SizedBox(
                  width: 320,
                  height: 220,
                  child: ListView.builder(
                    itemCount: prompts.length,
                    itemBuilder: (context, index) {
                      final prompt = prompts[index];

                      return ListTile(
                        dense: true,
                        selected: index == value.index,
                        title: Text(prompt.word),
                        subtitle: Text(
                          prompt is CodeFieldPrompt
                              ? prompt.type
                              : 'Suggestion',
                        ),
                        onTap: () {
                          onSelected(prompt.autocomplete);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
      child: CodeEditor(
        controller: controller,
        wordWrap: false,
      ),
    );
  }
}
