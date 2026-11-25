
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

class ProjectOverview extends StatelessWidget {
  const ProjectOverview({
    super.key,
    required this.projectPath,
    required this.onCategorySelected,
  });

  final String projectPath;
  final ValueChanged<String> onCategorySelected;

  static const categories = [
    ('Entities', Icons.pets),
    ('Items', Icons.inventory_2_outlined),
    ('Blocks', Icons.view_in_ar),
    ('Recipes', Icons.menu_book),
    ('Functions', Icons.code),
    ('Structures', Icons.domain),
    ('Textures', Icons.image),
    ('Models', Icons.view_in_ar_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          p.basename(projectPath),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Minecraft Bedrock Project'),
        const SizedBox(height: 24),
        const Text('WORKSPACE'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth >= 900 ? 4 :
                constraints.maxWidth >= 500 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: 110,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final (label, icon) = categories[index];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onCategorySelected(label),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(icon, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
