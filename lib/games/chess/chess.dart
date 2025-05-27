import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

void main() {
  runApp(const ChessGame());
}

class ChessGame extends StatelessWidget {
  const ChessGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Chess',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChessHomePage(),
    );
  }
}

class ChessHomePage extends StatefulWidget {
  const ChessHomePage({super.key});

  @override
  State<ChessHomePage> createState() => _ChessHomePageState();
}

class _ChessHomePageState extends State<ChessHomePage> {
  final ChessBoardController controller = ChessBoardController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Chess Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.resetBoard();
            },
          )
        ],
      ),
      body: Center(
        child: ChessBoard(
          controller: controller,
          boardColor: BoardColor.brown,
          boardOrientation: PlayerColor.white,
        ),
      ),
    );
  }
}
