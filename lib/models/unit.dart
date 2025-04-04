class Unit {
  final String type;
  int hp;
  final int maxHp;
  final int movement;
  final int attackRange;
  final int chargeRange;
  final int damage;
  final int weaponBS;

  Unit(this.type)
    : hp = type == 'space_marine' ? 10 : 5,
      maxHp = type == 'space_marine' ? 10 : 5,
      movement = type == 'space_marine' ? 6 : 6,
      attackRange = type == 'space_marine' ? 3 : 6,
      chargeRange = 12,
      damage = type == 'space_marine' ? 3 : 2,
      weaponBS = type == 'space_marine' ? 3 : 4;
}
