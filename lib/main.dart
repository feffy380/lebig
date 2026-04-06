import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hex_toolkit/hex_toolkit.dart';
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
          child: SimScreen(),
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
    _controller = SimController(world: World(width: 60*10, height: 40*10, rng: Random()))..start();
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
    final stopwatch = Stopwatch()..start();

    canvas.save();

    // scale grid to fill canvas
    var hexSize = 20.0;
    var (gridW, gridH) = world.gridSize(hexSize);
    hexSize *= min(size.width / gridW, size.height / gridH);
    (gridW, gridH) = world.gridSize(hexSize);

    var xOffset = hexSize + (size.width - gridW) / 2;
    var yOffset = hexSize + (size.height - gridH) / 2;

    canvas.translate(xOffset, yOffset);

    // Set background
    canvas.drawRect(Rect.fromLTWH(-hexSize, -hexSize, gridW, gridH), Paint()..color = Colors.blueGrey);

    // TODO: eventually convert to atlas
    // Preallocate buffers
    const int maxHexesPerBatch = 10_000; // safely below 2**16 vertices
    final int maxVertices = maxHexesPerBatch * 6;
    final int maxIndices = maxHexesPerBatch * 12; // 4 triangles x 3 vertices

    var positions = Float32List(maxVertices * 2); // x, y per vertex
    var colors = Int32List(maxVertices);
    var indices = Uint16List(maxIndices);

    const indexOffsets = [
      0, 1, 2,
      0, 2, 3,
      0, 3, 4,
      0, 4, 5,
    ];

    int currentHexes = 0;

    Paint p = Paint();
    void flushBatch(canvas) {
      canvas.drawVertices(
        Vertices.raw(
          VertexMode.triangles,
          positions.sublist(0, currentHexes * 6 * 2),
          colors: colors.sublist(0, currentHexes * 6),
          indices: indices.sublist(0, currentHexes * 12),
        ),
        BlendMode.dst,
        p,
      );
      currentHexes = 0;
    }

    for (int i = 0; i < world.energyMap.length; i++) {
      double energy = world.energyMap[i];
      double alpha = min(energy / 100, 1.0);
      if (alpha < 0.05) continue;

      // vertex buffer can only hold 2**16 entries. flush when full
      if (currentHexes >= maxHexesPerBatch) {
        flushBatch(canvas);
      }

      int x = i % world.width;
      int y = (i / world.width).toInt();
      Hex pos = Hex.fromOffset(GridOffset(x, y));

      final color = Color.fromARGB((alpha * 255).toInt(), 0, 255, 0).toARGB32();
      final vertices = pos.vertices(hexSize);

      int vBase = currentHexes * 6;
      int pBase = vBase * 2;
      int iBase = currentHexes * 12;
      for (int j = 0; j < 6; j++) {
        positions[pBase + (j * 2)] = vertices[j].x;
        positions[pBase + (j * 2) + 1] = vertices[j].y;
        colors[vBase + j] = color;

      }
      for (int j = 0; j < indexOffsets.length; j++) {
        indices[iBase + j] = vBase + indexOffsets[j];
      }

      currentHexes++;
    }

    for (int i = 0; i < world.organisms.length; i++) {
      // vertex buffer can only hold 2**16 entries. flush when full
      if (currentHexes >= maxHexesPerBatch) {
        flushBatch(canvas);
      }

      var org = world.organisms[i];

      final color = world.organisms[i].color;
      final vertices = Hex.fromCube(org.position).vertices(hexSize);

      int vBase = currentHexes * 6;
      int pBase = vBase * 2;
      int iBase = currentHexes * 12;
      for (int j = 0; j < 6; j++) {
        positions[pBase + (j * 2)] = vertices[j].x;
        positions[pBase + (j * 2) + 1] = vertices[j].y;
        colors[vBase + j] = color;

      }
      for (int j = 0; j < indexOffsets.length; j++) {
        indices[iBase + j] = vBase + indexOffsets[j];
      }

      currentHexes++;
    }
    // TODO: some way to indicate rotation. maybe 2 dots to represent eyes?
    flushBatch(canvas);

    canvas.restore();

    // Rate limit
    final elapsed = stopwatch.elapsedMilliseconds;
    if (kDebugMode) {
      print("${elapsed}ms");
    }
    // base: ~105ms
    // Vertices.raw: ~20ms
    // hardcoded indexOffsets: ~15ms
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
