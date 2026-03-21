import 'dart:math';

import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:lebig/organism.dart';

/// Hold world state and resolve timesteps.
/// World is a hex grid that wraps in the x and y direction (torus).
/// Represented by a rectangular grid where even rows are offset by half a cell.
class World {
  late final Random rng;
  final int width;
  final int height;
  // is this worth it? successful organisms will fill the world and grid will become dense anyway
  // 2d List of Organisms would be good enough
  List<Organism> organisms = [];
  List<Hex> positions = [];

  World(this.width, this.height, {Random? rng}) {
    this.rng = rng ?? Random();
    // PLACEHOLDER: Fill world with randomly colored hexes
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        if (this.rng.nextDouble() > 0.1) {
          continue;
        }
        organisms.add(Organism(color: randRGB(this.rng)));
        positions.add(Hex.fromOffset(GridOffset(i, j)));
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
    // PLACEHOLDER: move everything to the right, wrapping around
    // TODO: execute organisms
    // - stochastic scheduling to avoid order bias
    // - execute 1 instruction per organism for now. do multiple to reduce overhead/improve locality later
    // - instructions implemented here or by helper because org has no direct access to world state
    //    - use enhanced enum
    for (var _ in organisms) {
      // stochastic scheduling. no collision yet
      var i = rng.nextInt(organisms.length);
      var hex = positions[i];
      var pos = hex.toOffset();
      hex = Hex.fromOffset(GridOffset((pos.q + 1) % width, pos.r));
      positions[i] = hex;
    }
  }
}

/// Return int with random RGB hexcode in the lower 24 bits
int randRGB(Random rng) {
  return (rng.nextDouble() * 0xFFFFFF).toInt() | 0xFF000000;
}
