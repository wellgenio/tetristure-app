import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tetristure/components/controls.dart';
import 'package:tetristure/components/pixel.dart';
import 'package:tetristure/models/high_score.dart';
import 'package:tetristure/models/piece.dart';
import 'package:tetristure/models/values.dart';

List<List<Tetromino?>> gameBoard = List.generate(
  colLength,
  (i) => List.generate(
    rowLength,
    (j) => null,
  ),
);

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late Isar isar;

  // current tetris piece
  Piece currentPiece = Piece(type: Tetromino.L);

  // current score
  int currentScore = 0;

  // record: high score
  int highscore = 0;

  // game over status
  bool gameOver = false;

  @override
  void initState() {
    super.initState();

    initializeIsar();
  }

  initializeIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [HighScoreSchema],
      directory: dir.path,
    );

    starGame();
  }

  void starGame() async {
    final highScoreRecord = await isar.highScores.where().findFirst();

    // initialize high score
    if (highScoreRecord != null) {
      highscore = highScoreRecord.score!.toInt();
    } else {
      final newHighScore = HighScore()..score = 0;
      await isar.writeTxn(() => isar.highScores.put(newHighScore));
    }

    currentPiece.initalizePiece();

    // frame refresh rate
    Duration frameRate = const Duration(milliseconds: 600);
    gameLoop(frameRate);
  }

  void gameLoop(Duration frameRate) {
    Timer.periodic(frameRate, (timer) {
      setState(() {
        // clear lines
        clearLines();

        // check lading
        checkLading();

        // check if game over
        if (gameOver == true) {
          timer.cancel();
          showGameOver();
        }

        // move current piece down
        currentPiece.movePiece(Direction.down);
      });
    });
  }

  // Check for collision  in a future position
  // return true -> there is a collision
  // return false -> there is no collision
  bool checkCollision(Direction direction) {
    // loop through each position of the current piece
    for (int i = 0; i < currentPiece.position.length; i++) {
      // calculate the row and column of the current position
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      // adjust the row and col based on the direction
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      // check if the piece is out bounds
      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }

      // check if the current position is already occupied by another piece in the game board
      if (row >= 0 && col >= 0) {
        if (gameBoard[row][col] != null) {
          return true;
        }
      }
    }
    // if not collision are detected, return false
    return false;
  }

  void checkLading() {
    // if going down is occupied
    if (checkCollision(Direction.down)) {
      // mark position as occupied on the gameBoard
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;
        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }

      // once landed, create the next piece
      createNewPiece();
    }
  }

  void createNewPiece() {
    // reset rotate state
    rotateState = 3;

    // create a random object to generate random tetromine types
    Random rand = Random();

    // Create a new piece with random type
    Tetromino randomType = Tetromino.values[rand.nextInt(Tetromino.values.length)];

    currentPiece = Piece(type: randomType);
    currentPiece.initalizePiece();

    if (isGameOver()) {
      gameOver = true;
    }
  }

  // clear lines
  void clearLines() {
    // step 1: loop through each row of the game board from bottom to top
    for (int row = colLength - 1; row >= 0; row--) {
      // step 2: initalize a variable to track if the row is full
      bool rowIsFull = true;

      // setp 3: check if the row it full
      for (int col = 0; col < rowLength; col++) {
        // if there's an empty column, set rowIsFull to false and break the loop
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }

      // step 4: if the row is full, clear the row and shilf rows down
      if (rowIsFull) {
        // step 5: move all rows above the cleared row down by one position
        for (int r = row; r > 0; r--) {
          // copy the above row to the current row
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }

        // step 6: set the top row to empty
        gameBoard[0] = List.generate(row, (index) => null);

        // step 7: Increment the score;
        currentScore++;
      }
    }
  }

  bool isGameOver() {
    // check if any  columns in the top row are filled
    for (int col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }

    // if the top row is empty, the game is not over
    return false;
  }

  void moveLeft() {
    // make sure move is valid before moving there
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  void moveRight() {
    // make sure move is valid before moving there
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  int rotateState = 3;
  void rotatePiece() {
    List<int> newPosition = [];

    // rotate the piece based on it's type
    switch (currentPiece.type) {
      case Tetromino.L:
        switch (rotateState) {
          case 0:
            /**
            
              x
              x
              x x 
            
            */
            newPosition = [
              currentPiece.position[1] - rowLength,
              currentPiece.position[1],
              currentPiece.position[1] + rowLength,
              currentPiece.position[1] + rowLength + 1,
            ];
            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 1:
            /**
            
              x x x
              x 
            
            */
            newPosition = [
              currentPiece.position[1] - 1,
              currentPiece.position[1],
              currentPiece.position[1] + 1,
              currentPiece.position[1] + rowLength - 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 2:
            /**
            
              x x
                x
                x
            */
            newPosition = [
              currentPiece.position[1] + rowLength,
              currentPiece.position[1],
              currentPiece.position[1] - rowLength,
              currentPiece.position[1] - rowLength - 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 3:
            /**
            
                  x
              x x x
              
            */
            newPosition = [
              currentPiece.position[1] - rowLength + 1,
              currentPiece.position[1],
              currentPiece.position[1] + 1,
              currentPiece.position[1] - 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
        }
        break;
      case Tetromino.J:
        switch (rotateState) {
          case 0:
            /**
            
                x
                x
              x x 
            
            */
            newPosition = [
              currentPiece.position[1] - rowLength,
              currentPiece.position[1],
              currentPiece.position[1] + rowLength,
              currentPiece.position[1] + rowLength + 1,
            ];
            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 1:
            /**
            
              x
              x x x
            
            */
            newPosition = [
              currentPiece.position[1] - rowLength - 1,
              currentPiece.position[1],
              currentPiece.position[1] - 1,
              currentPiece.position[1] + 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 2:
            /**
            
               x x
               x
               x

            */
            newPosition = [
              currentPiece.position[1] + rowLength,
              currentPiece.position[1],
              currentPiece.position[1] - rowLength,
              currentPiece.position[1] - rowLength + 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 3:
            /**
            
              x x x
              x
              
            */
            newPosition = [
              currentPiece.position[1] + 1,
              currentPiece.position[1],
              currentPiece.position[1] - 1,
              currentPiece.position[1] + rowLength + 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
        }
        break;
      case Tetromino.I:
        switch (rotateState) {
          case 0:
            /**
            
              x x x x
            
            */
            newPosition = [
              currentPiece.position[1] - 1,
              currentPiece.position[1],
              currentPiece.position[1] + 1,
              currentPiece.position[1] + 2,
            ];
            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 1:
            /**
            
              x
              x
              x
              x

            */
            newPosition = [
              currentPiece.position[1] - rowLength,
              currentPiece.position[1],
              currentPiece.position[1] + rowLength,
              currentPiece.position[1] + 2 * rowLength,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 2:
            /**
            
              x x x x

            */
            newPosition = [
              currentPiece.position[1] - 1,
              currentPiece.position[1],
              currentPiece.position[1] + 1,
              currentPiece.position[1] + 2,
            ];
            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 3:
            /**

              x
              x
              x
              x
              
            */
            newPosition = [
              currentPiece.position[1] - rowLength,
              currentPiece.position[1],
              currentPiece.position[1] + rowLength,
              currentPiece.position[1] + 2 * rowLength,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
        }
        break;
      case Tetromino.O:
        // the O does not need to be rotated
        break;
      case Tetromino.S:
        switch (rotateState) {
          case 0:
            /**
            
                x x
              x x
            */
            newPosition = [
              currentPiece.position[1],
              currentPiece.position[1] + 1,
              currentPiece.position[1] + rowLength - 1,
              currentPiece.position[1] + rowLength,
            ];
            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 1:
            /**
            
              x
              x x
                x

            */
            newPosition = [
              currentPiece.position[0] - rowLength,
              currentPiece.position[0],
              currentPiece.position[0] + 1,
              currentPiece.position[0] + rowLength + 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 2:
            /**
            
                x x 
              x x

            */
            newPosition = [
              currentPiece.position[1],
              currentPiece.position[1] + 1,
              currentPiece.position[1] + rowLength - 1,
              currentPiece.position[1] + rowLength,
            ];
            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 3:
            /**

              x
              x x
                x
              
            */
            newPosition = [
              currentPiece.position[0] - rowLength,
              currentPiece.position[0],
              currentPiece.position[0] + 1,
              currentPiece.position[0] + rowLength + 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
        }
        break;
      case Tetromino.Z:
        switch (rotateState) {
          case 0:
            /**
            
              x x
                x x
            */
            newPosition = [
              currentPiece.position[0] + rowLength - 2,
              currentPiece.position[1],
              currentPiece.position[2] + rowLength - 1,
              currentPiece.position[3] + 1,
            ];
            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 1:
            /**
            
                x
              x x
              x

            */
            newPosition = [
              currentPiece.position[0] - rowLength + 2,
              currentPiece.position[1],
              currentPiece.position[2] - rowLength + 1,
              currentPiece.position[3] - 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 2:
            /**
            
              x x 
                x x

            */
            newPosition = [
              currentPiece.position[0] + rowLength - 2,
              currentPiece.position[1],
              currentPiece.position[2] + rowLength - 1,
              currentPiece.position[3] + 1,
            ];
            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 3:
            /**

                x
              x x
              x
              
            */
            newPosition = [
              currentPiece.position[0] - rowLength + 2,
              currentPiece.position[1],
              currentPiece.position[2] - rowLength + 1,
              currentPiece.position[3] - 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
        }
        break;
      case Tetromino.T:
        switch (rotateState) {
          case 0:
            /**
            
              x
              x x
              x

            */
            newPosition = [
              currentPiece.position[2] - rowLength,
              currentPiece.position[2],
              currentPiece.position[2] + 1,
              currentPiece.position[2] + rowLength,
            ];
            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 1:
            /**

              x x x
                x

            */
            newPosition = [
              currentPiece.position[1] - 1,
              currentPiece.position[1],
              currentPiece.position[1] + 1,
              currentPiece.position[1] + rowLength,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 2:
            /**
            
                x 
              x x
                x

            */
            newPosition = [
              currentPiece.position[1] - rowLength,
              currentPiece.position[1] - 1,
              currentPiece.position[1],
              currentPiece.position[1] + rowLength,
            ];
            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
          case 3:
            /**

                x
              x x x
              
            */
            newPosition = [
              currentPiece.position[2] - rowLength,
              currentPiece.position[2] - 1,
              currentPiece.position[2],
              currentPiece.position[2] + 1,
            ];

            // check that this new position is valid move before assigning it the real position
            if (piecePositionIsValid(newPosition)) {
              currentPiece.position = newPosition;
              rotateState = (rotateState + 1) % 4;
            }
            break;
        }
        break;
    }
  }

  // check if valid position
  bool positionIsValid(int position) {
    // get the row and col of position
    int row = (position / rowLength).floor();
    int col = position % rowLength;

    // if the position is taken, return false
    if (row < 0 || col < 0 || gameBoard[row][col] != null) {
      return false;
    }
    // otherwise position is valid so return true
    else {
      return true;
    }
  }

  // check piece is valid position
  bool piecePositionIsValid(List<int> piecePosition) {
    bool firstColOccupied = false;
    bool lastColOccupied = false;

    for (int pos in piecePosition) {
      // return false if any position is already taken
      if (!positionIsValid(pos)) {
        return false;
      }

      // get the col of position
      int col = pos % rowLength;

      // check if the first or last column is occupied
      if (col == 0) {
        firstColOccupied = true;
      }
      if (col == rowLength - 1) {
        lastColOccupied = true;
      }
    }
    // if there is a piece in the first col and last col, it is going through the wall
    return !(firstColOccupied && lastColOccupied);
  }

  // game over message
  void showGameOver() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game over!'),
        content: Text('Sua pontuação: $currentScore'),
        actions: [
          TextButton(
            onPressed: () {
              resetGame();

              Navigator.pop(context);
            },
            child: const Text('Novo jogo'),
          ),
        ],
      ),
    );
  }

  void resetGame() async {
    await isar.writeTxn(() async {
      final highScoreRecord = await isar.highScores.where().findFirst();
      if (highScoreRecord != null) {
        if (currentScore > highScoreRecord.score!.toInt()) {
          final newRecord = highScoreRecord..score = currentScore;
          await isar.highScores.put(newRecord);
        }
      }
    });

    // clear the gameboard
    gameBoard = List.generate(
      colLength,
      (i) => List.generate(
        rowLength,
        (j) => null,
      ),
    );

    // new game
    gameOver = false;
    currentScore = 0;

    createNewPiece();

    starGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "T",
                  style: TextStyle(color: Colors.cyan, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  "e",
                  style: TextStyle(color: Color.fromARGB(255, 22, 223, 29), fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  "t",
                  style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  "r",
                  style: TextStyle(color: Colors.orange, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  "i",
                  style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  "s",
                  style: TextStyle(color: Color.fromARGB(255, 248, 93, 144), fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text('Recorde: $highscore', style: const TextStyle(color: Colors.white)),
          Expanded(
            child: GridView.builder(
              itemCount: rowLength * colLength,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: rowLength,
              ),
              itemBuilder: (context, index) {
                // get row and col of each index
                int row = (index / rowLength).floor();
                int col = index % rowLength;

                // current piece
                if (currentPiece.position.contains(index)) {
                  return Pixel(color: currentPiece.color);
                }
                // landed pieces
                else if (gameBoard[row][col] != null) {
                  final Tetromino? tetrominoType = gameBoard[row][col];

                  return Pixel(color: tetrominoColors[tetrominoType]);
                }
                // blank pixel
                else {
                  return Pixel(color: Colors.grey[900]);
                }
              },
            ),
          ),
          Text(
            'Pontos:  $currentScore',
            style: const TextStyle(color: Colors.white, fontSize: 20.0),
          ),
          GameControls(
            moveLeft: moveLeft,
            rotatePiece: rotatePiece,
            moveRight: moveRight,
          ),
        ],
      ),
    );
  }
}
