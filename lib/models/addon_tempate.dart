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
}
