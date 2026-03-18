import 'dart:math';
import 'dart:ui';

import 'package:hex_toolkit/hex_toolkit.dart';

/// Manage world state and resolve timesteps.
/// World is a hex grid that wraps in the x and y direction (torus).
/// Represented by a rectangular grid where even rows are offset by half a cell.
class World {
  final int width;
  final int height;
  List<Hex> positions = [];
  List<Color> colors = [];

  World(this.width, this.height) {
    // Fill world with randomly colored placeholder hexes
    var rng = Random();
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        positions.add(Hex.fromOffset(GridOffset(i, j)));
        colors.add(Color((rng.nextDouble() * 0xFFFFFF).toInt() | 0xFF000000));
      }
    }
  }

  /// Calculate grid size in pixels (w,h)
  (double, double) gridSize(double hexSize) {
    var topLeft = Hex.zero().centerPoint(hexSize);
    // calculate right edge from offset row (row 1)
    var right = Hex.fromOffset(GridOffset(width-1, 1)).centerPoint(hexSize);
    var bottom = Hex.fromOffset(GridOffset(0, height-1)).centerPoint(hexSize);

    return (
      right.x - topLeft.x + 2 * hexSize,
      bottom.y - topLeft.y + 2 * hexSize,
    );
  }
}
