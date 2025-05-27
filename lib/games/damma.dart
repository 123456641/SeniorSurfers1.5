import 'package:flutter/material.dart';

void main() {
  runApp(const DammaGame());
}

class DammaGame extends StatelessWidget {
  const DammaGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dama',
      debugShowCheckedModeBanner: false,
      home: const DamaHomePage(),
    );
  }
}

enum PieceType { none, white, black, whiteKing, blackKing }

class DamaHomePage extends StatefulWidget {
  const DamaHomePage({super.key});

  @override
  State<DamaHomePage> createState() => _DamaHomePageState();
}

class _DamaHomePageState extends State<DamaHomePage> {
  static const int boardSize = 8;
  late List<List<PieceType>> board;
  bool isWhiteTurn = true;
  int? selectedRow;
  int? selectedCol;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    board = List.generate(
      boardSize,
      (row) => List.generate(boardSize, (col) {
        if (row < 3 && (row + col) % 2 == 1) return PieceType.black;
        if (row > 4 && (row + col) % 2 == 1) return PieceType.white;
        return PieceType.none;
      }),
    );
  }

  bool isKing(PieceType type) =>
      type == PieceType.whiteKing || type == PieceType.blackKing;

  void handleTap(int row, int col) {
    final tappedPiece = board[row][col];

    // Selecting a piece
    if (selectedRow == null &&
        tappedPiece != PieceType.none &&
        ((isWhiteTurn &&
                (tappedPiece == PieceType.white ||
                    tappedPiece == PieceType.whiteKing)) ||
            (!isWhiteTurn &&
                (tappedPiece == PieceType.black ||
                    tappedPiece == PieceType.blackKing)))) {
      setState(() {
        selectedRow = row;
        selectedCol = col;
      });
      return;
    }

    // Attempt to move or capture
    if (selectedRow != null && selectedCol != null) {
      if (isValidMove(selectedRow!, selectedCol!, row, col)) {
        performMove(selectedRow!, selectedCol!, row, col);
        setState(() {
          selectedRow = null;
          selectedCol = null;
          isWhiteTurn = !isWhiteTurn;
        });
      } else {
        // Deselect
        setState(() {
          selectedRow = null;
          selectedCol = null;
        });
      }
    }
  }

  bool isValidMove(int fromRow, int fromCol, int toRow, int toCol) {
    final piece = board[fromRow][fromCol];
    final target = board[toRow][toCol];
    if (target != PieceType.none) return false;

    int rowDiff = toRow - fromRow;
    int colDiff = toCol - fromCol;

    bool isWhitePiece =
        piece == PieceType.white || piece == PieceType.whiteKing;
    bool isBlackPiece =
        piece == PieceType.black || piece == PieceType.blackKing;

    // Simple move
    if ((rowDiff.abs() == 1) && (colDiff.abs() == 1)) {
      if (!isKing(piece)) {
        if (isWhitePiece && rowDiff != -1) {
          return false;
        }
        if (isBlackPiece && rowDiff != 1) {
          return false;
        }
      }
      return true;
    }

    // Capture move
    if ((rowDiff.abs() == 2) && (colDiff.abs() == 2)) {
      int midRow = (fromRow + toRow) ~/ 2;
      int midCol = (fromCol + toCol) ~/ 2;
      PieceType middle = board[midRow][midCol];

      if (middle == PieceType.none) {
        return false;
      }
      if (isWhitePiece &&
          (middle == PieceType.white || middle == PieceType.whiteKing)) {
        return false;
      }
      if (isBlackPiece &&
          (middle == PieceType.black || middle == PieceType.blackKing)) {
        return false;
      }

      return true;
    }

    return false;
  }

  void performMove(int fromRow, int fromCol, int toRow, int toCol) {
    final piece = board[fromRow][fromCol];

    // Move piece
    board[toRow][toCol] = piece;
    board[fromRow][fromCol] = PieceType.none;

    // Capture logic
    if ((toRow - fromRow).abs() == 2) {
      int midRow = (fromRow + toRow) ~/ 2;
      int midCol = (fromCol + toCol) ~/ 2;
      board[midRow][midCol] = PieceType.none;
    }

    // King promotion
    if (piece == PieceType.white && toRow == 0) {
      board[toRow][toCol] = PieceType.whiteKing;
    }
    if (piece == PieceType.black && toRow == boardSize - 1) {
      board[toRow][toCol] = PieceType.blackKing;
    }
  }

  Widget buildPiece(PieceType piece) {
    if (piece == PieceType.none) return const SizedBox.shrink();

    Color color = (piece == PieceType.white || piece == PieceType.whiteKing)
        ? Colors.white
        : Colors.black;

    bool king = isKing(piece);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.grey),
      ),
      child: king
          ? const Center(
              child: Text(
                '👑',
                style: TextStyle(fontSize: 18),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[300],
      appBar: AppBar(
        title: Text('Flutter Dama - ${isWhiteTurn ? "White" : "Black"}\'s Turn'),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: Column(
          children: List.generate(boardSize, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(boardSize, (col) {
                final isDark = (row + col) % 2 == 1;
                final isSelected = selectedRow == row && selectedCol == col;

                return GestureDetector(
                  onTap: () => handleTap(row, col),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green
                          : (isDark ? Colors.brown[700] : Colors.brown[200]),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Center(child: buildPiece(board[row][col])),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}
