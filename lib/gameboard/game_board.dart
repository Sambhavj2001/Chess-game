import 'dart:math';

import 'package:chess_game/components/dead_piece.dart';
import 'package:js/js.dart';

import 'package:chess_game/components/square.dart';
import 'package:chess_game/values/colors.dart';
import 'package:flutter/material.dart';

import '../components/piece.dart';
import '../helper/helper_math.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({Key? key}) : super(key: key);

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late List<List<ChessPiece?>> board;
  List<List<int>> validMoves = [];
  List<ChessPiece> whitePieceTaken = [];
  List<ChessPiece> blackPieceTaken = [];

  ChessPiece? selectedPiece;

  //default value
  int selectedRow = -1;
  int selectedCol = -1;

  //turn
  bool isWhiteTurn = true;

  //king's position
  List<int> whiteKingPosition = [7, 4];
  List<int> blackKingPosition = [0, 4];
  bool checkStatus = false;

  @override
  void initState() {
    _initializedBoard();
    super.initState();
  }

  void _initializedBoard() {
    List<List<ChessPiece?>> newBoard =
        List.generate(8, (index) => List.generate(8, (index) => null));

    //place pawns
    for (int i = 0; i < 8; i++) {
      newBoard[1][i] = ChessPiece(
        type: ChessPieceType.pawn,
        imagePath: 'lib/images/pawn.png',
        isWhite: false,
      );
      newBoard[6][i] = ChessPiece(
        type: ChessPieceType.pawn,
        imagePath: 'lib/images/pawn.png',
        isWhite: true,
      );
    }

    //place rooks
    newBoard[0][0] = ChessPiece(
      type: ChessPieceType.rook,
      imagePath: 'lib/images/rook.png',
      isWhite: false,
    );
    newBoard[0][7] = ChessPiece(
      type: ChessPieceType.rook,
      imagePath: 'lib/images/rook.png',
      isWhite: false,
    );
    newBoard[7][0] = ChessPiece(
      type: ChessPieceType.rook,
      imagePath: 'lib/images/rook.png',
      isWhite: true,
    );
    newBoard[7][7] = ChessPiece(
      type: ChessPieceType.rook,
      imagePath: 'lib/images/rook.png',
      isWhite: true,
    );

    // place knight
    newBoard[0][1] = ChessPiece(
      type: ChessPieceType.knight,
      imagePath: 'lib/images/knight.png',
      isWhite: false,
    );
    newBoard[0][6] = ChessPiece(
      type: ChessPieceType.knight,
      imagePath: 'lib/images/knight.png',
      isWhite: false,
    );
    newBoard[7][1] = ChessPiece(
      type: ChessPieceType.knight,
      imagePath: 'lib/images/knight.png',
      isWhite: true,
    );
    newBoard[7][6] = ChessPiece(
      type: ChessPieceType.knight,
      imagePath: 'lib/images/knight.png',
      isWhite: true,
    );

    //place bishops
    newBoard[0][2] = ChessPiece(
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/bishop.png',
      isWhite: false,
    );
    newBoard[0][5] = ChessPiece(
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/bishop.png',
      isWhite: false,
    );
    newBoard[7][2] = ChessPiece(
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/bishop.png',
      isWhite: true,
    );
    newBoard[7][5] = ChessPiece(
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/bishop.png',
      isWhite: true,
    );

    //place queen
    newBoard[0][3] = ChessPiece(
      type: ChessPieceType.queen,
      imagePath: 'lib/images/queen.png',
      isWhite: false,
    );
    newBoard[7][4] = ChessPiece(
      type: ChessPieceType.queen,
      imagePath: 'lib/images/queen.png',
      isWhite: true,
    );

    //place king
    newBoard[0][4] = ChessPiece(
      type: ChessPieceType.king,
      imagePath: 'lib/images/king.png',
      isWhite: false,
    );
    newBoard[7][3] = ChessPiece(
      type: ChessPieceType.king,
      imagePath: 'lib/images/king.png',
      isWhite: true,
    );

    board = newBoard;
  }

  void pieceSelected(int row, int col) {
    setState(() {
      //no piece is has been selected yet
      if (selectedPiece == null && board[row][col] != null) {
        if (board[row][col]!.isWhite == isWhiteTurn) {
          selectedPiece = board[row][col];
          selectedRow = row;
          selectedCol = col;
        }
      }
      //piece is selected but user can selected is own kind
      else if (board[row][col] != null &&
          board[row][col]!.isWhite == selectedPiece!.isWhite) {
        selectedPiece = board[row][col];
        selectedRow = row;
        selectedCol = col;
      } else if (selectedPiece != null &&
          validMoves.any((element) => element[0] == row && element[1] == col)) {
        movePiece(row, col);
      }
      validMoves = calculateRealValidMoves(
          selectedRow, selectedCol, selectedPiece, true);
    });
  }

  //raw valid moves
  List<List<int>> calculateRawValidMoves(int row, int col, ChessPiece? piece) {
    List<List<int>> candidateMoves = [];

    if (piece == null) {
      return [];
    }

    //directions
    int directions = piece.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPieceType.pawn:
        //can move forward if the square is not occupied
        if (isInBoard(row + directions, col) &&
            board[row + directions][col] == null) {
          candidateMoves.add([row + directions, col]);
        }

        //for 2 steps
        if ((row == 1 && !piece.isWhite) || (row == 6 && piece.isWhite)) {
          if (isInBoard(row + 2 * directions, col) &&
              board[row + 2 * directions][col] == null &&
              board[row + directions][col] == null) {
            candidateMoves.add([row + 2 * directions, col]);
          }
        }

        //for kill
        if (isInBoard(row + directions, col - 1) &&
            board[row + directions][col - 1] != null &&
            board[row + directions][col - 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + directions, col - 1]);
        }
        if (isInBoard(row + directions, col + 1) &&
            board[row + directions][col + 1] != null &&
            board[row + directions][col + 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + directions, col + 1]);
        }
        break;
      case ChessPieceType.rook:
        //horizontal and vertical directions
        var rooKMoves = [
          [-1, 0], //up
          [1, 0], //down
          [0, -1], //left
          [0, 1], //right
        ];

        for (var move in rooKMoves) {
          var i = 1;
          while (true) {
            var newRow = row + i * move[0];
            var newCol = col + i * move[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); //kill
              }
              break; //blocked
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;
      case ChessPieceType.knight:
        //all moves
        var knightMoves = [
          [-2, -1], //up 2 left 1
          [-2, 1], //up 2 right 1
          [-1, -2], //up 1 left 2
          [-1, 2], //up 1 right 2
          [2, -1], //down 2 left 1
          [2, 1], //down 2 right 1
          [1, -2], //down 1 left 2
          [1, 2], //down 1 right 2
        ];
        for (var move in knightMoves) {
          var newRow = row + move[0];
          var newCol = col + move[1];

          if (!isInBoard(newRow, newCol)) {
            continue;
          }
          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]); //capture
            }
            continue; // blocked
          }
          candidateMoves.add([newRow, newCol]);
        }
        break;
      case ChessPieceType.bishop:
        var bishopMoves = [
          [-1, -1], //up left
          [-1, 1], //up right
          [1, -1], //down left
          [1, -1], //down right
        ];
        for (var move in bishopMoves) {
          var i = 1;
          while (true) {
            var newRow = row + i * move[0];
            var newCol = col + i * move[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); //capture
              }
              break; //blocked
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;
      case ChessPieceType.queen:
        var queenMoves = [
          [-1, 0], //up
          [1, 0], //down
          [0, -1], //left
          [0, 1], //right
          [-1, -1], //up left
          [-1, 1], //up right
          [1, -1], //down left
          [1, 1], //down right
        ];
        for (var move in queenMoves) {
          var i = 1;
          while (true) {
            var newRow = row + i * move[0];
            var newCol = col + i * move[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); //capture
              }
              break; //blocked
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;
      case ChessPieceType.king:
        var kingMoves = [
          [-1, 0], //up
          [1, 0], //down
          [0, -1], //left
          [0, 1], //right
          [-1, -1], //up left
          [-1, 1], //up right
          [1, -1], //down left
          [1, 1], //down right
        ];
        for (var move in kingMoves) {
          var newRow = row + move[0];
          var newCol = col + move[1];
          if (!isInBoard(newRow, newCol)) {
            continue;
          }
          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]); //capture
            }
            continue; //blocked
          }
          candidateMoves.add([newRow, newCol]);
        }
        break;
      default:
    }
    return candidateMoves;
  }

  //real valid moves
  List<List<int>> calculateRealValidMoves(
      int row, int col, ChessPiece? piece, bool checkSimulation) {
    List<List<int>> realValidMoves = [];
    List<List<int>> candidateMoves = calculateRawValidMoves(row, col, piece);

    if (checkSimulation) {
      for (var move in candidateMoves) {
        int endRow = move[0];
        int endCol = move[1];
        if (simulatedMoveIsSafe(piece!, row, col, endRow, endCol)) {
          realValidMoves.add(move);
        }
      }
    } else {
      realValidMoves = candidateMoves;
    }

    return realValidMoves;
  }

  void movePiece(int newRow, int newCol) {
    //if the new spot has an enemy piece
    if (board[newRow][newCol] != null) {
      var capturedPiece = board[newRow][newCol];
      if (capturedPiece!.isWhite) {
        whitePieceTaken.add(capturedPiece);
      } else {
        blackPieceTaken.add(capturedPiece);
      }
    }

    //if the piece is the king
    if (selectedPiece!.type == ChessPieceType.king) {
      //update the king post
      if (selectedPiece!.isWhite) {
        whiteKingPosition = [newRow, newCol];
      } else {
        blackKingPosition = [newRow, newCol];
      }
    }
    //move the piece and clear the spot
    board[newRow][newCol] = selectedPiece;
    board[selectedRow][selectedCol] = null;

    //king under attack or not
    if (isKingInCheck(!isWhiteTurn)) {
      checkStatus = true;
    } else {
      checkStatus = false;
    }

    //clear selection
    setState(() {
      selectedPiece = null;
      selectedRow = -1;
      selectedCol = -1;
      validMoves = [];
    });

    if (isCheckMate(!isWhiteTurn)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("CHECK MATE!"),
          actions: [
            TextButton(
              onPressed: resetGame,
              child: const Text("Play Again"),
            ),
          ],
        ),
      );
    }

    //change turns
    isWhiteTurn = !isWhiteTurn;
  }

  bool isKingInCheck(bool isWhiteKing) {
    List<int> kingPosition =
        isWhiteKing ? whiteKingPosition : blackKingPosition;

    //check if king is under attack or not
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        //skip empty squares and piece of same color
        if (board[i][j] == null || board[i][j]!.isWhite == isWhiteKing) {
          continue;
        }

        List<List<int>> pieceValidMoves =
            calculateRealValidMoves(i, j, board[i][j], false);

        //kings position is in piece valid moves
        if (pieceValidMoves.any((move) =>
            move[0] == kingPosition[0] && move[1] == kingPosition[1])) {
          return true;
        }
      }
    }
    return false;
  }

  bool simulatedMoveIsSafe(
      ChessPiece piece, int startRow, int startCol, int endRow, int endCol) {
    //save the current board
    ChessPiece? originalDestinationPiece = board[endRow][endCol];

    //if it is king
    List<int>? originalKingPosition;
    if (piece.type == ChessPieceType.king) {
      originalKingPosition =
          piece.isWhite ? whiteKingPosition : blackKingPosition;

      //update the king post
      if (piece.isWhite) {
        whiteKingPosition = [endRow, endCol];
      } else {
        blackKingPosition = [endRow, endCol];
      }
    }

    //simulate the move
    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    //king is under attack or not
    bool kingInCheck = isKingInCheck(piece.isWhite);

    //restore board to original
    board[startRow][startCol] = piece;
    board[endRow][endCol] = originalDestinationPiece;

    //if the king is the piece
    if (piece.type == ChessPieceType.king) {
      if (piece.isWhite) {
        whiteKingPosition = originalKingPosition!;
      } else {
        blackKingPosition = originalKingPosition!;
      }
    }

    return !kingInCheck;
  }

  bool isCheckMate(bool isWhiteKing) {
    //king is not in check, then it's not checkmate
    if (!isKingInCheck(isWhiteKing)) {
      return false;
    }

    //if there is a legal move
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        //skip empty squares and piece of same color
        if (board[i][j] == null || board[i][j]!.isWhite == isWhiteKing) {
          continue;
        }

        List<List<int>> pieceValidMoves =
            calculateRealValidMoves(i, j, board[i][j], true);

        //kings position is in piece valid moves
        if (pieceValidMoves.isNotEmpty) {
          return false;
        }
      }
    }
    //it's checkmate
    return true;
  }

  void resetGame() {
    Navigator.pop(context);
    _initializedBoard();
    checkStatus = false;
    whitePieceTaken.clear();
    blackPieceTaken.clear();
    whiteKingPosition = [7, 4];
    blackKingPosition = [0, 4];
    isWhiteTurn = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          //white piece taken
          Expanded(
            child: GridView.builder(
              itemCount: whitePieceTaken.length,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8),
              itemBuilder: (context, index) => DeadPiece(
                imagePath: whitePieceTaken[index].imagePath,
                isWhite: true,
              ),
            ),
          ),

          //check status
          Text(checkStatus ? "Check!" : ""),

          //chess board
          Expanded(
            flex: 3,
            child: GridView.builder(
              itemCount: 8 * 8,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8),
              itemBuilder: (context, index) {
                int row = index ~/ 8;
                int col = index % 8;

                bool isSelected = selectedRow == row && selectedCol == col;
                bool isValidMove = false;
                for (var position in validMoves) {
                  if (position[0] == row && position[1] == col) {
                    isValidMove = true;
                  }
                }

                return Square(
                  isWhite: isWhite(index),
                  piece: board[row][col],
                  isSelected: isSelected,
                  isValidMove: isValidMove,
                  onTap: () => pieceSelected(row, col),
                );
              },
            ),
          ),

          //black piece taken
          Expanded(
            child: GridView.builder(
              itemCount: blackPieceTaken.length,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8),
              itemBuilder: (context, index) => DeadPiece(
                imagePath: blackPieceTaken[index].imagePath,
                isWhite: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
