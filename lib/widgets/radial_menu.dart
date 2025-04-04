import 'package:flutter/material.dart';

class RadialMenu extends StatelessWidget {
  final Function() onMoveSelected;
  final Function() onAttackSelected;
  final Function() onEndTurnSelected;
  final Function() onChargeSelected;
  final Function() onMeleeSelected;

  const RadialMenu({
    Key? key,
    required this.onMoveSelected,
    required this.onAttackSelected,
    required this.onEndTurnSelected,
    required this.onChargeSelected,
    required this.onMeleeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160, // Más grande
      height: 160, // Más grande
      child: Stack(
        children: [
          // Centro
          Positioned(
            left: 60,
            top: 60,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Mover (arriba)
          Positioned(
            top: 0,
            left: 60,
            child: _buildButton(
              icon: Icons.directions_walk,
              color: Colors.blue,
              onTap: onMoveSelected,
              tooltip: 'Mover',
            ),
          ),
          // Cancelar (abajo)
          Positioned(
            bottom: 0,
            left: 60,
            child: _buildButton(
              icon: Icons.close,
              color: Colors.grey,
              onTap: onEndTurnSelected,
              tooltip: 'Cancelar',
            ),
          ),
          // Atacar (izquierda)
          Positioned(
            top: 60,
            left: 0,
            child: _buildButton(
              icon: Icons.gps_fixed,
              color: Colors.red,
              onTap: onAttackSelected,
              tooltip: 'Atacar',
            ),
          ),
          // Cargar (abajo derecha)
          Positioned(
            bottom: 15,
            right: 15,
            child: _buildButton(
              icon: Icons.sports_martial_arts,
              color: Colors.green,
              onTap: onChargeSelected,
              tooltip: 'Cargar',
            ),
          ),
          // Combate (derecha)
          Positioned(
            top: 60,
            right: 0,
            child: _buildButton(
              icon: Icons.sports_kabaddi,
              color: Colors.orange,
              onTap: onMeleeSelected,
              tooltip: 'Combate',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color color,
    required Function() onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2),
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
