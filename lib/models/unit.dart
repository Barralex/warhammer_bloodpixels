class Unit {
  final String type;
  int hp;
  final int maxHp;
  final int movement;
  final int attackRange;
  final int chargeRange; // Nueva propiedad
  final int damage;
  final int weaponBS; // Ballistic Skill

  Unit(this.type)
    : hp = type == 'space_marine' ? 10 : 5,
      maxHp = type == 'space_marine' ? 10 : 5,
      movement = type == 'space_marine' ? 6 : 6,
      attackRange =
          type == 'space_marine'
              ? 3
              : 6, // Tyranids ahora también tienen alcance
      chargeRange = 12, // 12" para ambos tipos según las reglas
      damage = type == 'space_marine' ? 3 : 2,
      weaponBS = type == 'space_marine' ? 3 : 4; // Marines 3+, Tiránidos 4+
}
