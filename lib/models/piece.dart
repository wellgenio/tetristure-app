import 'package:flutter/services.dart';
import 'package:tetristure/models/values.dart';

class Piece {
  // type of tetris piece
  Tetromino type;

  Piece({required this.type});

  // the piece is just list of integers
  List<int> position = [];

  // color of tetris piece
  Color get color {
    return tetrominoColors[type] ?? const Color(0xFFFFFFFF);
  }

  // generate of integers
  void initalizePiece() {
    switch (type) {
      case Tetromino.L:
        position = [-26, -16, -6, -5];
        break;
      case Tetromino.J:
        position = [-25, -15, -5, -6];
        break;
      case Tetromino.I:
        position = [-26, -16, -6, -36];
        break;
      case Tetromino.O:
        position = [-26, -16, -25, -15];
        break;
      case Tetromino.S:
        position = [-26, -25, -17, -16];
        break;
      case Tetromino.Z:
        position = [-26, -25, -15, -14];
        break;
      case Tetromino.T:
        position = [-27, -26, -25, -16];
        break;
    }
  }

  void movePiece(Direction direction) {
    switch (direction) {
      case Direction.left:
        for (int i = 0; i < position.length; i++) {
          position[i] -= 1;
        }
        break;
      case Direction.right:
        for (int i = 0; i < position.length; i++) {
          position[i] += 1;
        }
        break;
      case Direction.down:
        for (int i = 0; i < position.length; i++) {
          position[i] += rowLength;
        }
        break;
    }
  }
}
