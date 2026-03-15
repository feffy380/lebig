import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hex_toolkit/hex_toolkit.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'lebig',
      home: Scaffold(
        body: Center(
          // Placeholder hexes in the middle
          child: CustomPaint(
            painter: HexPainter(Hex.zero().ring(1).toList()),
            // child: Container(),
          ),
          // child: Text('Hello World!'),
        ),
      ),
    );
  }
}

class HexPainter extends CustomPainter {
  static const hexSize = 20.0;
  static const hexPadding = 1.0;
  final List<Hex> hexes;

  HexPainter(this.hexes);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Zero in the center
    canvas.translate(size.width / 2, size.height / 2);
    // canvas.translate(hexSize, hexSize);

    final paint = Paint()..color = Colors.blue;
    for (var hex in hexes) {

      // Get vertices ...
      var vertices = hex.vertices(hexSize, padding: hexPadding).map((e) => Offset(e.x, e.y)).toList();

      // ... and draw them
      canvas.drawVertices(Vertices(VertexMode.triangleFan, vertices), BlendMode.srcOver, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// TODO: Simulation engine class