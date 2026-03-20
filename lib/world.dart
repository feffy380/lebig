import 'dart:math';

import 'package:hex_toolkit/hex_toolkit.dart';

/// Hold world state and resolve timesteps.
/// World is a hex grid that wraps in the x and y direction (torus).
/// Represented by a rectangular grid where even rows are offset by half a cell.
class World {
  final int width;
  final int height;
  List<Hex> positions = [];
  List<int> colors = [];

  World(this.width, this.height) {
    // Fill world with randomly colored placeholder hexes
    var rng = Random();
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        if (rng.nextDouble() > 0.1) {
          continue;
        }
        positions.add(Hex.fromOffset(GridOffset(i, j)));
        colors.add((rng.nextDouble() * 0xFFFFFF).toInt() | 0xFF000000);
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

  /// Update simulation state
  void step() {
    // Placeholder: move everything to the right, wrapping around
    for (var i = 0; i < positions.length; i++) {
      var hex = positions[i];
      var pos = hex.toOffset();
      hex = Hex.fromOffset(GridOffset((pos.q + 1) % width, pos.r));
      positions[i] = hex;
    }
  }
}
