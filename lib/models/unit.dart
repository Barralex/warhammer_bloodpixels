class UnitConfig {
  final int hp;
  final int maxHp;
  final int movement;
  final int attackRange;
  final int chargeRange;
  final int damage;
  final int weaponBS;
  final String faction;

  const UnitConfig({
    required this.hp,
    required this.maxHp,
    required this.movement,
    required this.attackRange,
    required this.chargeRange,
    required this.damage,
    required this.weaponBS,
    required this.faction,
  });
}

class Unit {
  final String type;
  int hp;
  final int maxHp;
  final int movement;
  final int attackRange;
  final int chargeRange;
  final int damage;
  final int weaponBS;
  final String faction;

  static const Map<String, UnitConfig> unitConfigs = {
    'space_marine': UnitConfig(
      hp: 10,
      maxHp: 10,
      movement: 6,
      attackRange: 12,
      chargeRange: 12,
      damage: 3,
      weaponBS: 3,
      faction: 'space_marine',
    ),
    'sergeant': UnitConfig(
      hp: 10,
      maxHp: 10,
      movement: 6,
      attackRange: 12,
      chargeRange: 12,
      damage: 3,
      weaponBS: 3,
      faction: 'space_marine',
    ),
    'tyranid': UnitConfig(
      hp: 5,
      maxHp: 5,
      movement: 6,
      attackRange: 6,
      chargeRange: 12,
      damage: 1,
      weaponBS: 4,
      faction: 'tyranid',
    ),
    'reaper_swarm': UnitConfig(
      hp: 1,
      maxHp: 1,
      movement: 6,
      attackRange: 0,
      chargeRange: 12,
      damage: 3,
      weaponBS: 4,
      faction: 'tyranid',
    ),
  };

  Unit(this.type)
    : assert(unitConfigs.containsKey(type), 'Unknown unit type: $type'),
      hp = unitConfigs[type]!.hp,
      maxHp = unitConfigs[type]!.maxHp,
      movement = unitConfigs[type]!.movement,
      attackRange = unitConfigs[type]!.attackRange,
      chargeRange = unitConfigs[type]!.chargeRange,
      damage = unitConfigs[type]!.damage,
      weaponBS = unitConfigs[type]!.weaponBS,
      faction = unitConfigs[type]!.faction;
}
