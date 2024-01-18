import 'package:flutter/material.dart';

class GameControls extends StatelessWidget {
  final void Function()? moveLeft;
  final void Function()? rotatePiece;
  final void Function()? moveRight;

  const GameControls({
    super.key,
    required this.moveLeft,
    required this.rotatePiece,
    required this.moveRight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: moveLeft,
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_ios),
          ),
          IconButton(
            onPressed: rotatePiece,
            color: Colors.white,
            icon: const Icon(Icons.rotate_right),
          ),
          IconButton(
            onPressed: moveRight,
            color: Colors.white,
            icon: const Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }
}
