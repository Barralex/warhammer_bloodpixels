class UnitConfig {
  final int hp;
  final int maxHp;
  final int movement;
  final int attackRange;
  final int chargeRange;
  final int damage;
  final int weaponBS;

  const UnitConfig({
    required this.hp,
    required this.maxHp,
    required this.movement,
    required this.attackRange,
    required this.chargeRange,
    required this.damage,
    required this.weaponBS,
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

  static const Map<String, UnitConfig> unitConfigs = {
    'space_marine': UnitConfig(
      hp: 10,
      maxHp: 10,
      movement: 6,
      attackRange: 3,
      chargeRange: 12,
      damage: 3,
      weaponBS: 3,
    ),
    'tyranid': UnitConfig(
      hp: 5,
      maxHp: 5,
      movement: 6,
      attackRange: 6,
      chargeRange: 12,
      damage: 2,
      weaponBS: 4,
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
      weaponBS = unitConfigs[type]!.weaponBS;
}
