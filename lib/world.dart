import 'package:hex_toolkit/hex_toolkit.dart';

/// Manage world state and resolve timesteps.
/// World is a hex grid that wraps in the x and y direction (torus).
/// Represented by a rectangular grid where even rows are offset by half a cell.
class World {
  final int width;
  final int height;
  List<Hex> agents = [];

  World(this.width, this.height) {
    // Fill world with placeholder hexes
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        agents.add(Hex.fromOffset(GridOffset(i, j)));
      }
    }
  }

  /// Calculate grid size in pixels
  (double, double) gridSize(double hexSize) {
    var topLeft = Hex.zero().centerPoint(hexSize);
    var bottomRight = Hex.fromOffset(GridOffset(width-1, height-1)).centerPoint(hexSize);

    return (
      bottomRight.x - topLeft.x + 2 * hexSize,
      bottomRight.y - topLeft.y + 2 * hexSize,
    );
  }
}
