import 'package:flutter/material.dart';

class RadialMenu extends StatelessWidget {
  final Function() onMoveSelected;
  final Function() onAttackSelected;
  final Function() onEndTurnSelected;

  const RadialMenu({
    Key? key,
    required this.onMoveSelected,
    required this.onAttackSelected,
    required this.onEndTurnSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 40,
            child: _buildButton(
              icon: Icons.directions_walk,
              color: Colors.blue,
              onTap: onMoveSelected,
              tooltip: 'Mover',
            ),
          ),
          Positioned(
            bottom: 0,
            left: 40,
            child: _buildButton(
              icon: Icons.close,
              color: Colors.grey,
              onTap: onEndTurnSelected,
              tooltip: 'Cancelar',
            ),
          ),
          Positioned(
            top: 40,
            left: 0,
            child: _buildButton(
              icon: Icons.gps_fixed,
              color: Colors.red,
              onTap: onAttackSelected,
              tooltip: 'Atacar',
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
