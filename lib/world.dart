import 'dart:math';

import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:lebig/op.dart';
import 'package:lebig/organism.dart';

/// Hold world state and resolve timesteps.
/// World is a hex grid that wraps in the x and y direction (torus).
/// Represented by a rectangular grid where even rows are offset by half a cell.
class World {
  final Random rng;
  final int width;
  final int height;

  // might move to dense grid later, but we still need organism->position lookup
  List<Organism> organisms = [];
  List<Cube> positions = [];
  List<Cube> rotations = [];

  // Energy model
  late List<double> energyMap;
  // Under these settings an organism starting with 100 energy runs for
  // ~3300 cycles which feels reasonable.
  // Might need to reduce since they'll get scheduled less often.
  // Maybe make min drain constant so organisms eventually die if they never get scheduled?
  double energyDrainCoeff = 1 / 1000;
  double energyCostFloor = 0.01;

  World({required this.width, required this.height, required this.rng}) {
    // Scatter patches of energy around the map
    energyMap = List.filled(width * height, 0);
    var numPatches = (width / 9).toInt() * (height / 9).toInt();
    for (int i = 0; i < numPatches; i++) {
      // Generate at least 1 away from edges to avoid neighbors going out of bounds
      var offset = GridOffset(1 + rng.nextInt(width - 2), 1 + rng.nextInt(height - 2));
      var patchMid = Hex.fromOffset(offset);
      // add 50 energy to cell
      placeEnergy(patchMid.cube, 50);
      // add 10 energy to neighbors
      patchMid.neighbors().forEach((neighbor) {
        placeEnergy(neighbor.cube, 10);
      });
    }

    var directions = Hex.zero().neighbors().map((e) => e.cube).toList();
    // PLACEHOLDER: Fill world with randomly colored hexes
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        if (rng.nextDouble() > 0.1) {
          continue;
        }
        organisms.add(Organism(
          id: organisms.length,
          color: randRGB(rng),
          energy: 100, // TODO: make initial energy configurable
          program: [Op.move, Op.turnRand], // dummy program. wander randomly
        ));
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
    // stochastic scheduling. no weighting yet
    for (var _ in organisms) {
      var i = rng.nextInt(organisms.length);
      var org = organisms[i];

      if (org.isDead) continue;

      // pay energy cost
      var energyCost = max(org.energy * energyDrainCoeff, energyCostFloor);
      // TODO: Death
      // needs new data structure to decouple ID from list position
      if (energyCost > org.energy) {
        print("Organism ${org.id} ran out of energy");
        org.reduceEnergy(energyCost);
        // organisms.removeAt(i);
        // positions.removeAt(i);
        // rotations.removeAt(i);
        continue;
      }
      org.reduceEnergy(energyCost);

      org.execute(this);

      // TODO: scatter some energy to keep things alive (how much?)
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

  /// Rotate organism clockwise in 60-degree steps
  void requestRotate(int id, int steps) {
    var rotation = rotations[id];
    rotation = Hex.fromCube(rotation).rotateAround(Hex.zero(), steps).cube;
    rotations[id] = rotation;
  }

  void placeEnergy(Cube position, int energy) {
    var offset = position.toGridOffset();
    int i = offset.q + offset.r * width;
    assert(i < energyMap.length);
    energyMap[i] += energy;
  }
}

/// Return int with random RGB hexcode in the lower 24 bits
int randRGB(Random rng) {
  return (rng.nextDouble() * 0xFFFFFF).toInt() | 0xFF000000;
}
