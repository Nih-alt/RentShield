class RoomTemplate {
  final String id;
  final String name;
  final String icon;
  final List<ChecklistTemplateItem> checklistItems;

  const RoomTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.checklistItems,
  });
}

class ChecklistTemplateItem {
  final String id;
  final String name;
  final String category;

  const ChecklistTemplateItem({
    required this.id,
    required this.name,
    required this.category,
  });
}

class DefaultTemplates {
  DefaultTemplates._();

  static const List<RoomTemplate> rooms = [
    RoomTemplate(
      id: 'living_room',
      name: 'Living Room',
      icon: '🛋️',
      checklistItems: [
        ChecklistTemplateItem(id: 'lr_walls', name: 'Walls & Paint', category: 'Structure'),
        ChecklistTemplateItem(id: 'lr_ceiling', name: 'Ceiling', category: 'Structure'),
        ChecklistTemplateItem(id: 'lr_flooring', name: 'Flooring / Tiles', category: 'Structure'),
        ChecklistTemplateItem(id: 'lr_windows', name: 'Windows & Glass', category: 'Fixtures'),
        ChecklistTemplateItem(id: 'lr_doors', name: 'Doors & Handles', category: 'Fixtures'),
        ChecklistTemplateItem(id: 'lr_switches', name: 'Switches & Sockets', category: 'Electrical'),
        ChecklistTemplateItem(id: 'lr_lights', name: 'Lights & Fans', category: 'Electrical'),
        ChecklistTemplateItem(id: 'lr_curtain_rods', name: 'Curtain Rods / Blinds', category: 'Fixtures'),
        ChecklistTemplateItem(id: 'lr_ac', name: 'AC Unit', category: 'Appliances'),
      ],
    ),
    RoomTemplate(
      id: 'bedroom',
      name: 'Bedroom',
      icon: '🛏️',
      checklistItems: [
        ChecklistTemplateItem(id: 'br_walls', name: 'Walls & Paint', category: 'Structure'),
        ChecklistTemplateItem(id: 'br_ceiling', name: 'Ceiling', category: 'Structure'),
        ChecklistTemplateItem(id: 'br_flooring', name: 'Flooring / Tiles', category: 'Structure'),
        ChecklistTemplateItem(id: 'br_windows', name: 'Windows & Glass', category: 'Fixtures'),
        ChecklistTemplateItem(id: 'br_doors', name: 'Doors & Locks', category: 'Fixtures'),
        ChecklistTemplateItem(id: 'br_wardrobe', name: 'Wardrobe / Closet', category: 'Furniture'),
        ChecklistTemplateItem(id: 'br_switches', name: 'Switches & Sockets', category: 'Electrical'),
        ChecklistTemplateItem(id: 'br_lights', name: 'Lights & Fans', category: 'Electrical'),
        ChecklistTemplateItem(id: 'br_ac', name: 'AC Unit', category: 'Appliances'),
      ],
    ),
    RoomTemplate(
      id: 'kitchen',
      name: 'Kitchen',
      icon: '🍳',
      checklistItems: [
        ChecklistTemplateItem(id: 'kt_walls', name: 'Walls & Tiles', category: 'Structure'),
        ChecklistTemplateItem(id: 'kt_flooring', name: 'Flooring', category: 'Structure'),
        ChecklistTemplateItem(id: 'kt_countertop', name: 'Countertop / Slab', category: 'Structure'),
        ChecklistTemplateItem(id: 'kt_cabinets', name: 'Cabinets & Drawers', category: 'Fixtures'),
        ChecklistTemplateItem(id: 'kt_sink', name: 'Sink & Faucet', category: 'Plumbing'),
        ChecklistTemplateItem(id: 'kt_stove', name: 'Stove / Gas Connection', category: 'Appliances'),
        ChecklistTemplateItem(id: 'kt_exhaust', name: 'Chimney / Exhaust', category: 'Appliances'),
        ChecklistTemplateItem(id: 'kt_switches', name: 'Switches & Sockets', category: 'Electrical'),
        ChecklistTemplateItem(id: 'kt_windows', name: 'Windows', category: 'Fixtures'),
      ],
    ),
    RoomTemplate(
      id: 'bathroom',
      name: 'Bathroom',
      icon: '🚿',
      checklistItems: [
        ChecklistTemplateItem(id: 'bt_walls', name: 'Walls & Tiles', category: 'Structure'),
        ChecklistTemplateItem(id: 'bt_flooring', name: 'Floor Tiles', category: 'Structure'),
        ChecklistTemplateItem(id: 'bt_toilet', name: 'Toilet / Commode', category: 'Plumbing'),
        ChecklistTemplateItem(id: 'bt_sink', name: 'Wash Basin & Tap', category: 'Plumbing'),
        ChecklistTemplateItem(id: 'bt_shower', name: 'Shower / Geyser', category: 'Plumbing'),
        ChecklistTemplateItem(id: 'bt_mirror', name: 'Mirror & Cabinet', category: 'Fixtures'),
        ChecklistTemplateItem(id: 'bt_door', name: 'Door & Lock', category: 'Fixtures'),
        ChecklistTemplateItem(id: 'bt_exhaust', name: 'Exhaust Fan', category: 'Electrical'),
        ChecklistTemplateItem(id: 'bt_drain', name: 'Drainage', category: 'Plumbing'),
      ],
    ),
    RoomTemplate(
      id: 'balcony',
      name: 'Balcony',
      icon: '🌿',
      checklistItems: [
        ChecklistTemplateItem(id: 'bl_flooring', name: 'Flooring', category: 'Structure'),
        ChecklistTemplateItem(id: 'bl_railing', name: 'Railing / Grille', category: 'Structure'),
        ChecklistTemplateItem(id: 'bl_walls', name: 'Walls & Paint', category: 'Structure'),
        ChecklistTemplateItem(id: 'bl_ceiling', name: 'Ceiling', category: 'Structure'),
        ChecklistTemplateItem(id: 'bl_drain', name: 'Drainage', category: 'Plumbing'),
        ChecklistTemplateItem(id: 'bl_lights', name: 'Lights', category: 'Electrical'),
      ],
    ),
    RoomTemplate(
      id: 'entrance',
      name: 'Entrance / Common Area',
      icon: '🚪',
      checklistItems: [
        ChecklistTemplateItem(id: 'en_door', name: 'Main Door & Lock', category: 'Fixtures'),
        ChecklistTemplateItem(id: 'en_doorbell', name: 'Doorbell', category: 'Electrical'),
        ChecklistTemplateItem(id: 'en_flooring', name: 'Flooring', category: 'Structure'),
        ChecklistTemplateItem(id: 'en_walls', name: 'Walls & Paint', category: 'Structure'),
        ChecklistTemplateItem(id: 'en_lights', name: 'Lights', category: 'Electrical'),
        ChecklistTemplateItem(id: 'en_meter', name: 'Electric Meter Reading', category: 'Utility'),
        ChecklistTemplateItem(id: 'en_water', name: 'Water Meter / Connection', category: 'Utility'),
      ],
    ),
  ];
}
