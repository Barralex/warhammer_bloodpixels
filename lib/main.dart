import 'package:flutter/material.dart';
import 'dart:math';

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
      attackRange =
          type == 'space_marine'
              ? 3
              : 1, // 3 for Space Marine (range), 1 for Tyranids (melee)
      damage =
          type == 'space_marine'
              ? 3
              : 2; // Damage for Space Marine (higher) and Tyranids (lower)
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: GameBoard());
  }
}

class GameBoard extends StatefulWidget {
  @override
  _GameBoardState createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  List<List<Unit?>> board = List.generate(10, (index) => List.filled(14, null));
  Offset? _selectedTile;
  String _currentTurn = 'space_marine';
  List<Offset> _moveRange = [];
  List<Offset> _attackRange = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 5; i++) {
      board[0][i] = Unit("tyranid");
    }
    for (int i = 0; i < 3; i++) {
      board[9][i] = Unit("space_marine");
    }
  }

  void _onTileTapped(int row, int col) {
    Unit? unit = board[row][col];
    if (unit?.type == _currentTurn) {
      setState(() {
        _selectedTile = Offset(col.toDouble(), row.toDouble());
        _moveRange = _calculateMoveRange(row, col, unit!);
        _attackRange = _calculateAttackRange(row, col, unit!);
      });
    } else if (_selectedTile != null && unit == null) {
      int selectedRow = _selectedTile!.dy.toInt();
      int selectedCol = _selectedTile!.dx.toInt();
      double distance = sqrt(
        pow(row - selectedRow, 2) + pow(col - selectedCol, 2),
      );
      if (distance <= board[selectedRow][selectedCol]!.movement) {
        setState(() {
          board[row][col] = board[selectedRow][selectedCol];
          board[selectedRow][selectedCol] = null;
          _selectedTile = null;
          _moveRange = [];
          _attackRange = [];
          _currentTurn =
              _currentTurn == 'space_marine' ? 'tyranid' : 'space_marine';
        });
      }
    } else if (unit?.type != _currentTurn && unit != null) {
      int selectedRow = _selectedTile!.dy.toInt();
      int selectedCol = _selectedTile!.dx.toInt();

      double distance = sqrt(
        pow(row - selectedRow, 2) + pow(col - selectedCol, 2),
      );

      if (distance <= board[selectedRow][selectedCol]!.attackRange) {
        _attack(selectedRow, selectedCol, row, col);
      }
    }
  }

  void _attack(int selectedRow, int selectedCol, int targetRow, int targetCol) {
    Unit attacker = board[selectedRow][selectedCol]!;
    Unit target = board[targetRow][targetCol]!;

    target.hp -= attacker.damage;

    if (target.hp <= 0) {
      setState(() {
        board[targetRow][targetCol] = null;
      });
    }

    setState(() {
      _currentTurn =
          _currentTurn == 'space_marine' ? 'tyranid' : 'space_marine';
    });
  }

  List<Offset> _calculateMoveRange(int row, int col, Unit unit) {
    List<Offset> moveRange = [];
    for (int i = -unit.movement; i <= unit.movement; i++) {
      for (int j = -unit.movement; j <= unit.movement; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 && newRow < 10 && newCol >= 0 && newCol < 14) {
          if (sqrt(i * i + j * j) <= unit.movement) {
            moveRange.add(Offset(newCol.toDouble(), newRow.toDouble()));
          }
        }
      }
    }
    return moveRange;
  }

  List<Offset> _calculateAttackRange(int row, int col, Unit unit) {
    List<Offset> attackRange = [];
    for (int i = -unit.attackRange; i <= unit.attackRange; i++) {
      for (int j = -unit.attackRange; j <= unit.attackRange; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 && newRow < 10 && newCol >= 0 && newCol < 14) {
          if (sqrt(i * i + j * j) <= unit.attackRange) {
            attackRange.add(Offset(newCol.toDouble(), newRow.toDouble()));
          }
        }
      }
    }
    return attackRange;
  }

  Future<int> _roll2D6(BuildContext context) async {
    int die1 = Random().nextInt(6) + 1;
    int die2 = Random().nextInt(6) + 1;
    int total = die1 + die2;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Carga"),
          content: Text("Resultado: \$die1 + \$die2 = \$total"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[800],
        title: Text(
          _currentTurn == 'space_marine'
              ? "Space Marines' Turn"
              : "Tyranids' Turn",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF5F5DC),
        child: Center(
          child: AspectRatio(
            aspectRatio: 14 / 10,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 14,
                childAspectRatio: 1,
              ),
              itemCount: 140,
              itemBuilder: (context, index) {
                int row = index ~/ 14;
                int col = index % 14;
                Unit? unit = board[row][col];
                bool isSelected =
                    _selectedTile?.dx == col && _selectedTile?.dy == row;
                return GestureDetector(
                  onTap: () => _onTileTapped(row, col),
                  child: Container(
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/tile.png'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: Colors.black),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: Colors.yellowAccent,
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ]
                              : [],
                    ),
                    child: Stack(
                      children: [
                        if (_moveRange.contains(
                          Offset(col.toDouble(), row.toDouble()),
                        ))
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                        if (_attackRange.contains(
                          Offset(col.toDouble(), row.toDouble()),
                        ))
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                        unit != null
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Image.asset('assets/${unit.type}.png'),
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  height: 10,
                                  width: 40,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: unit.hp / unit.maxHp,
                                          backgroundColor: Colors.black26,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                unit.type == 'space_marine'
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                          minHeight: 10,
                                        ),
                                      ),
                                      Text(
                                        '${unit.hp}',
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                            : Container(), // Ensures that if there's no unit, we render an empty container.
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
