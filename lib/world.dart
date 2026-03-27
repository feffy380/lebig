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
  Map<int, int> orgIndex = {}; // id -> list index
  int nextID = 0;
  Map<Cube, Organism> positions = {};

  // Energy model
  late List<double> energyMap;
  // Under these settings an organism starting with 100 energy runs for
  // ~3300 cycles which feels reasonable.
  // Might need to reduce since they'll get scheduled less often.
  // Maybe make min drain constant so organisms eventually die if they never get scheduled?
  // Could even make min drain controllable by organisms: treat as multiplier added to base of 1 for scheduling priority
  double energyDrainCoeff = 1 / 1000;
  double energyCostFloor = 0.01;
  double eatCoeff = 10;

  int timestep = 0;

  World({required this.width, required this.height, required this.rng}) {
    // Scatter patches of energy around the map
    energyMap = List.filled(width * height, 0);
    var numPatches = (width / 4).toInt() * (height / 4).toInt();
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
        var id = genID();

        // generate random program of length 10
        var program = List.generate(10, (_) => Op.values[rng.nextInt(Op.values.length)]);
        var org = Organism(
          id: id,
          color: randRGB(rng),
          energy: 100, // TODO: make initial energy configurable
          position: GridOffset(i, j).toCube(),
          rotation: directions[rng.nextInt(directions.length)],
          program: program,
        );
        organisms.add(org);
        orgIndex[id] = organisms.length - 1;
        positions[org.position] = org;
      }
    }
  }

  int genID() {
    return nextID++;
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
    // stochastic scheduling
    // TODO: weighting based on energy levels. stochastic acceptance
    var updates = organisms.length;
    for (int i = 0; i < updates; i++) {
      var idx = rng.nextInt(organisms.length);
      var org = organisms[idx];

      // Pay energy cost
      double energyCost = getExecCost(org);
      // Death
      if (energyCost > org.energy) {
        print("($timestep) Organism ${org.id} ran out of energy");
        removeOrganism(org.id);
        continue;
      }
      org.reduceEnergy(energyCost);

      org.execute(this);

      // TODO: scatter some energy to keep things alive (how much?)
    }
    timestep++;
  }

  double getExecCost(Organism org) {
    var energyCost = energyCostFloor + org.energy * energyDrainCoeff;
    return energyCost;
  }

  /// Move organism forward in the direction it's facing. Fails if destination is occupied
  void requestMove(int id) {
    var org = organisms[orgIndex[id]!];
    var newOffset = (org.position + org.rotation).toGridOffset(); // TODO: helper method to wrap coords
    var newPos = Cube.fromGridOffset(GridOffset(newOffset.q % width, newOffset.r % height));
    // TODO: optimize collision check
    if (positions.containsKey(newPos)) {
      // occupied. move fails
      return;
    } else {
      positions.remove(org.position);
      org.position = newPos;
      positions[newPos] = org;
    }
  }

  /// Rotate organism clockwise in 60-degree steps
  void requestRotate(int id, int steps) {
    var org = organisms[orgIndex[id]!];
    org.rotation = Hex.fromCube(org.rotation).rotateAround(Hex.zero(), steps).cube;
  }

  void requestEat(int id) {
    var org = organisms[orgIndex[id]!];
    var eatAmount = getExecCost(org) * eatCoeff;
    var eaten = reduceEnergy(org.position, eatAmount);
    org.increaseEnergy(eaten);
  }

  double readEnergy(Cube position) {
    return energyMap[posToIndex(position)];
  }

  double reduceEnergy(Cube position, double amount) {
    var eaten = min(amount, readEnergy(position));
    energyMap[posToIndex(position)] -= eaten;
    return eaten;
  }

  void placeEnergy(Cube position, int energy) {
    var i = posToIndex(position);
    energyMap[i] += energy;
  }

  int posToIndex(Cube position) {
    var offset = position.toGridOffset();
    int i = offset.q + offset.r * width;
    assert(i < energyMap.length);
    return i;
  }

  void removeOrganism(int id) {
    // swap and pop
    int index = orgIndex[id]!;
    int last = organisms.length - 1;
    Organism org = organisms[index];
    Organism other = organisms[last];
    organisms[last] = org;
    organisms[index] = other;
    organisms.removeLast();

    // update id -> index mapping
    orgIndex[other.id] = index;
    orgIndex.remove(id);

    // clear position
    positions.remove(org.position);
  }
}

/// Return int with random RGB hexcode in the lower 24 bits
int randRGB(Random rng) {
  return (rng.nextDouble() * 0xFFFFFF).toInt() | 0xFF000000;
}
