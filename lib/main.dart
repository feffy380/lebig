import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lebig/world.dart';

// TODO: stateful widget to hold this
final world = World(10, 10);

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
        // Placeholder hexes in the middle
        // TODO: centered canvas, padding around edges
        body: CustomPaint(
            painter: HexPainter(world),
            child: Container(),
        ),
      ),
    );
  }
}

class HexPainter extends CustomPainter {
  static const hexSize = 20.0;
  static const hexPadding = 1.0;
  final World world;

  HexPainter(this.world);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    var (gridW, gridH) = world.gridSize(hexSize);
    var xOffset = hexSize + (size.width - gridW) / 2;
    var yOffset = hexSize + (size.height - gridH) / 2;

    canvas.translate(xOffset, yOffset);

    final paint = Paint()..color = Colors.blue;
    for (var hex in world.agents) {

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
