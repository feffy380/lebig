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
  // might move to dense grid later, but we still need organism->position lookup
  List<Organism> organisms = [];
  List<Cube> positions = [];
  List<Cube> rotations = [];

  World({required this.width, required this.height, required this.rng}) {
    var directions = Hex.zero().neighbors().map((e) => e.cube).toList();
    // PLACEHOLDER: Fill world with randomly colored hexes
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        if (rng.nextDouble() > 0.1) {
          continue;
        }
        organisms.add(Organism(id: organisms.length, color: randRGB(rng), program: []));
        positions.add(GridOffset(i, j).toCube());
        rotations.add(directions[rng.nextInt(directions.length)]);
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
      requestMove(organisms[i].id);
      // new random direction
      // TODO: rotate ops
      var directions = Hex.zero().neighbors();
      rotations[i] = directions[rng.nextInt(directions.length)].cube;
    }
  }

  /// Move organism forward in the direction it's facing. Fails if destination is occupied
  void requestMove(int id) {
    var newOffset = (positions[id] + rotations[id]).toGridOffset(); // TODO: helper method to wrap coords
    var newPos = Cube.fromGridOffset(GridOffset(newOffset.q % width, newOffset.r % height));
    // TODO: optimize collision check
    if (positions.any((e) => newPos == e)) {
      // occupied. move fails
      return;
    } else {
      positions[id] = newPos;
    }
  }
}

/// Return int with random RGB hexcode in the lower 24 bits
int randRGB(Random rng) {
  return (rng.nextDouble() * 0xFFFFFF).toInt() | 0xFF000000;
}
