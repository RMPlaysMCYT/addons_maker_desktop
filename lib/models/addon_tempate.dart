enum AddonCategory { blocks, items, entities }

enum AddonTemplate {
  basicBlock,
  geometryBlock,
  interactiveBlock,
  crafttingTableBlock,
  basicItem,
  attachableItem,
  basicMob,
  skeletonMob,
  vehicle,
}

extension AddonTemplateDetails on AddonTemplate {
  AddonCategory get category => switch (this) {
    AddonTemplate.basicBlock ||
    AddonTemplate.geometryBlock ||
    AddonTemplate.interactiveBlock ||
    AddonTemplate.crafttingTableBlock => AddonCategory.blocks,
    AddonTemplate.basicItem ||
    AddonTemplate.attachableItem => AddonCategory.items,
    _ => AddonCategory.entities,
  };

  String get label => switch (this){
    AddonTemplate.basicBlock => 'Basic Block',
    AddonTemplate.geometryBlock => 'Geometry Block',
    AddonTemplate.interactiveBlock => 'Interactable Block',
    AddonTemplate.crafttingTableBlock => 'Crafting Table Block',
    AddonTemplate.basicItem => 'Basic Item',
    AddonTemplate.attachableItem => 'Basic 3D Item',
    AddonTemplate.basicMob => 'Basic Mob',
    AddonTemplate.skeletonMob => 'Skeleton',
    AddonTemplate.vehicle => 'Vehicle',
  };

  bool get requiresFollowUp => switch (this) {
    AddonTemplate.basicBlock || AddonTemplate.basicItem|| AddonTemplate.crafttingTableBlock => false,
    _ => true,
  };

  String get description => switch (this){
    AddonTemplate.basicBlock => 'Vanilla Basic Block',
    AddonTemplate.geometryBlock => 'Connect with .geo.json file and texture (model limits to 30x30x30)',
    AddonTemplate.interactiveBlock => 'Block with custom components added best for interactable blocks',
    AddonTemplate.crafttingTableBlock => 'Block with interactable with vanilla-like, best for item specific crafting recipes',
    AddonTemplate.basicItem => 'Vanilla Basic Item',
    AddonTemplate.attachableItem => 'Vanilla Basic 3D Item (Best when if the item texture was beyong 16x16) and it has models, rendering and animation',
    AddonTemplate.basicMob => 'Draft: entity behavior only; client visuals needed.',
    AddonTemplate.skeletonMob => 'Draft: start from vanilla skeleton, then customize safely.',
    AddonTemplate.vehicle => 'Draft: rideable entity; control logic and visuals needed.',
  };
}

class TemplateRequestfromUser {
  const TemplateRequestfromUser({
    required this.projectPath,
    required this.template,
    required this.identifier,
    required this.displayName,
    this.minecraftFormatVersion = '1.21.80',
  });
  final String projectPath;
  final AddonTemplate template;
  final String identifier;
  final String displayName;
  final String minecraftFormatVersion;
}

class GeneratedTemplate {
  const GeneratedTemplate({
    required this.paths,
    required this.isScaffold,
    required this.notes,
  });
  final List<String>paths;
  final bool isScaffold;
  final String notes;
}