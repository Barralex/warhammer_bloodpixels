import 'package:flutter/material.dart';

class Unit {
  final String type;
  int hp;
  final int maxHp;
  final int movement;
  final int attackRange;
  final int damage;

  Unit(this.type)
    : hp = type == 'space_marine' ? 10 : 5,
      maxHp = type == 'space_marine' ? 10 : 5,
      movement = type == 'space_marine' ? 6 : 6,
      attackRange = type == 'space_marine' ? 3 : 1,
      damage = type == 'space_marine' ? 3 : 2;
}
