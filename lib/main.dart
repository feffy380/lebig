import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lebig/sim_controller.dart';
import 'package:lebig/world.dart';

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
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            color: Colors.blueGrey,
            child: SimScreen(),
          ),
        ),
      ),
    );
  }
}

class SimScreen extends StatefulWidget {
  const SimScreen({super.key});

  @override
  State<SimScreen> createState() => _SimScreenState();
}

class _SimScreenState extends State<SimScreen> {
  late final SimController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SimController(world: World(20, 20))..start();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) => CustomPaint(
        painter: HexPainter(_controller.world),
        size: Size.infinite,  // TODO: Use InteractiveViewer for pan and zoom
      ),
    );
  }
}

class HexPainter extends CustomPainter {
  static const hexPadding = 1.0;
  final World world;

  HexPainter(this.world);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // scale grid to fill canvas
    var hexSize = 20.0;
    var (gridW, gridH) = world.gridSize(hexSize);
    hexSize *= min(size.width / gridW, size.height / gridH);
    (gridW, gridH) = world.gridSize(hexSize);

    var xOffset = hexSize + (size.width - gridW) / 2;
    var yOffset = hexSize + (size.height - gridH) / 2;

    canvas.translate(xOffset, yOffset);

    for (var i = 0; i < world.positions.length; i++) {
      final hex = world.positions[i];
      final paint = Paint()..color = Color(world.organisms[i].color);

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
