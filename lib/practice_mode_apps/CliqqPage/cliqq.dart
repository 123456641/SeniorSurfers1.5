import 'package:flutter/material.dart';

class CliqqPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice: Zoom'),
      ),
      body: Center(
        child: Text(
          'This is the Zoom practice page.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
