import 'package:flutter/material.dart';

void main() {
  runApp(const SolitaireGame());
}

class SolitaireGame extends StatelessWidget {
  const SolitaireGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Solitaire',
      home: const SolitaireHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SolitaireHome extends StatefulWidget {
  const SolitaireHome({super.key});

  @override
  State<SolitaireHome> createState() => _SolitaireHomeState();
}

class _SolitaireHomeState extends State<SolitaireHome> {
  List<String> stack1 = ["A♠", "2♠", "3♠"];
  List<String> stack2 = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solitaire Demo')),
      backgroundColor: const Color(0xFF0B6623),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(child: buildCardColumn(stack1, onCardMoved: (card) {
              setState(() {
                stack1.remove(card);
                stack2.add(card);
              });
            })),
            const SizedBox(width: 16),
            Expanded(child: buildCardColumn(stack2)),
          ],
        ),
      ),
    );
  }

  Widget buildCardColumn(List<String> cards, {Function(String card)? onCardMoved}) {
    return DragTarget<String>(
      onWillAccept: (_) => true,
      onAccept: (card) {
        if (onCardMoved != null) {
          onCardMoved(card);
        } else {
          setState(() {
            cards.add(card);
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.green[700],
          ),
          padding: const EdgeInsets.all(8),
          height: double.infinity,
          child: Stack(
            children: [
              for (int i = 0; i < cards.length; i++)
                Positioned(
                  top: i * 30.0,
                  child: Draggable<String>(
                    data: cards[i],
                    childWhenDragging: const SizedBox.shrink(),
                    feedback: buildCard(cards[i]),
                    child: buildCard(cards[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildCard(String cardText) {
    bool isRed = cardText.contains("♥") || cardText.contains("♦");
    return Container(
      width: 60,
      height: 80,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(2, 2))
        ],
      ),
      child: Text(
        cardText,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isRed ? Colors.red : Colors.black,
        ),
      ),
    );
  }
}
