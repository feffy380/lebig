import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:lebig/ancestor.dart';
import 'package:lebig/op.dart';
import 'package:lebig/organism.dart';

/// Hold world state and resolve timesteps.
/// World is a hex grid that wraps in the x and y direction (torus).
/// Represented by a rectangular grid where even rows are offset by half a cell.
class World {
  // TODO: seeded rng
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
  double energySpawnBudget = 0.0;
  // Under these settings an organism starting with 100 energy runs for
  // ~3300 cycles which feels reasonable.
  // Might need to reduce since they'll get scheduled less often.
  // Maybe make min drain constant so organisms eventually die if they never get scheduled?
  // Could even make min drain controllable by organisms: treat as multiplier added to base of 1 for scheduling priority
  // Ultimately I don't want to incentivize code efficiency at the expense of behavioral complexity
  final double _energyDrainCoeff = 1 / 1000;
  final double _energyCostFloor = 0.01;

  // Mutation rates - based on Avida defaults
  double copyMutProb = 0.0075; // Mutation rate per hCopy
  double divideInsProb = 0.05; // Insertion rate (max one, per divide)
  double divideDelProb = 0.05; // Deletion rate (max one, per divide)

  int timestep = 0;

  World({required this.width, required this.height, required this.rng}) {
    // seed hex_toolkit
    var hexSeed = (rng.nextInt(1<<16) << 16) | rng.nextInt(1<<16); // workaround for web target
    setRandomSeed(hexSeed);

    // Scatter patches of energy around the map
    energyMap = List.filled(width * height, 0);
    var numPatches = (width / 4).toInt() * (height / 4).toInt();
    for (int i = 0; i < numPatches; i++) {
      var offset = GridOffset(rng.nextInt(width), rng.nextInt(height));
      var patchMid = Hex.fromOffset(offset);
      // add 50 energy to cell
      placeEnergy(patchMid.cube, 50);
      // add 10 energy to neighbors
      patchMid.neighbors().forEach((neighbor) {
        var wrappedPos = wrapPosition(neighbor.cube);
        placeEnergy(wrappedPos, 10);
      });
    }

    // Place single Ancestor in the middle
    double initialEnergy = 10_000;
    energySpawnBudget -= initialEnergy;
    var program = List<Op>.from(ancestor);
    var org = Organism(
      color: 0xFFC41321,
      energy: initialEnergy,
      position: GridOffset((width / 2).toInt(), (height / 2).toInt()).toCube(),
      rotation: Hex.zero().randomNeighbor().cube,
      program: program,
    );
    addOrganism(org);
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
    // Scatter energy to keep things going
    // TODO: I'd love to replace this with autotrophs like in the Life Engine
    for (; energySpawnBudget >= 110; energySpawnBudget -= 110) {
      var offset = GridOffset(rng.nextInt(width), rng.nextInt(height));
      var patchMid = Hex.fromOffset(offset);
      // add 50 energy to cell
      placeEnergy(patchMid.cube, 50);
      // add 10 energy to neighbors
      patchMid.neighbors().forEach((neighbor) {
        var wrappedPos = wrapPosition(neighbor.cube);
        placeEnergy(wrappedPos, 10);
      });
    }

    if (organisms.isEmpty) {
      timestep++;
      return;
    }

    // stochastic scheduling
    // weighting based on energy levels. cumulative sum + binary search
    var prefixSum = <double>[];
    prefixSum.add(organisms[0].energy);
    for (int i = 1; i < organisms.length; i++) {
      prefixSum.add(prefixSum[i-1] + organisms[i].energy);
    }

    var updates = organisms.length;
    for (int i = 0; i < updates; i++) {
      var val = rng.nextDouble() * prefixSum.last;
      var idx = binarySearch(prefixSum, val);
      var org = organisms[idx];

      // Pay energy cost
      double energyCost = getExecCost(org);
      bool costPaid = org.reduceEnergy(energyCost);
      if (costPaid) {
        energySpawnBudget += energyCost;
        org.execute(this);
      }

      // Death - cost not paid or energy reached 0
      if (!costPaid || !org.isAlive || org.energy < _energyCostFloor) {
        removeOrganism(org.id);

        // recalc weights
        prefixSum.removeAt(idx);
        if (idx < prefixSum.length) {
          prefixSum[idx] = organisms[idx].energy;
          if (idx > 0) {
            prefixSum[idx] += prefixSum[idx-1];
          }
          for (int j = idx + 1; j < organisms.length; j++) {
            prefixSum[j] = prefixSum[j-1] + organisms[j].energy;
          }
        }

        continue;
      }

      // recalc weights
      if (prefixSum.length < organisms.length) {
        prefixSum.add(0);
      }
      prefixSum[idx] = organisms[idx].energy;
      if (idx > 0) {
        prefixSum[idx] += prefixSum[idx-1];
      }
      for (int j = idx + 1; j < organisms.length; j++) {
        prefixSum[j] = prefixSum[j-1] + organisms[j].energy;
      }
    }
    timestep++;
  }

  double getExecCost(Organism org) {
    var energyCost = _energyCostFloor + org.energy * _energyDrainCoeff;
    return energyCost;
  }

  /// Move organism forward in the direction it's facing. Fails if destination is occupied
  void requestMove(int id) {
    var org = organisms[orgIndex[id]!];
    var newPos = wrapPosition(org.position + org.rotation);
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

  Cube wrapPosition(Cube position) {
    var offset = position.toGridOffset();
    var newPos = Cube.fromGridOffset(GridOffset(offset.q % width, offset.r % height));
    return newPos;
  }

  /// Rotate organism clockwise in 60-degree steps
  void requestRotate(int id, int steps) {
    var org = organisms[orgIndex[id]!];
    org.rotation = Hex.fromCube(org.rotation).rotateAround(Hex.zero(), steps).cube;
  }

  void requestEat(int id) {
    var org = organisms[orgIndex[id]!];
    var eatAmount = max(readEnergy(org.position) / 2, getExecCost(org) * 2);
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

  void placeEnergy(Cube position, double energy) {
    var i = posToIndex(position);
    energyMap[i] += energy;
  }

  int posToIndex(Cube position) {
    var offset = position.toGridOffset();
    int i = offset.q + offset.r * width;
    assert(i < energyMap.length);
    return i;
  }

  void addOrganism(Organism org) {
    org.id = genID();
    organisms.add(org);
    orgIndex[org.id] = organisms.length - 1;
    positions[org.position] = org;
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

    // Drop energy on death
    placeEnergy(org.position, org.deathValue);
  }

  void requestGrow(int id) {
    var org = organisms[orgIndex[id]!];
    if (org.reduceEnergy(1)) {
      org.grow(1);
    }
  }

  void createOffspring(Organism parent) {
    // Convert excess buffer to child's initial energy
    double energy = parent.allocated.toDouble();
    // Stillbirth if no energy allocated or program is empty. Drop as energy on the parent's position
    if (energy == 0 || parent.childBuf.isEmpty) {
      placeEnergy(parent.position, energy + parent.childBuf.length);
      return;
    }

    // Create mutated copy of child buffer
    List<Op> childProgram = [];
    bool mutated = false;
    // copy mutation
    for (final op in parent.childBuf) {
      if (rng.nextDouble() < copyMutProb) {
        childProgram.add(Op.values[rng.nextInt(Op.values.length)]);
        mutated = true;
      } else {
        childProgram.add(op);
      }
    }
    // Insert mutation - insert 1 new instruction at random
    if (rng.nextDouble() < divideInsProb) {
      Op op = Op.values[rng.nextInt(Op.values.length)];
      int pos = rng.nextInt(childProgram.length + 1);
      childProgram.insert(pos, op);
    }
    // Delete mutation - delete 1 instruction at random
    if (childProgram.isNotEmpty && (rng.nextDouble() < divideDelProb)) {
      childProgram.removeAt(rng.nextInt(childProgram.length));
      // Empty program is lethal
      if (childProgram.isEmpty) {
        placeEnergy(parent.position, energy);
        return;
      }
    }

    // Tweak color after mutation. Clones get same color
    var color = Color(parent.color);
    if (mutated) {
      var hsv = HSVColor.fromColor(color);
      // hue: 0-360
      double hue = (hsv.hue + rng.nextDouble() * 20 - 10) % 360.0;
      // sat: 0.4-1.0
      double saturation = hsv.saturation + rng.nextDouble() * 0.2 - 0.1;
      saturation = saturation > 1.0 ? 1.0 - (saturation - 1.0) : saturation;
      saturation = saturation < 0.4 ? 0.4 + (0.4 - saturation) : saturation;
      // val: 0.6-1.0
      double value = hsv.value + rng.nextDouble() * 0.2 - 0.1;
      value = value > 1.0 ? 1.0 - (value - 1.0) : value;
      value = value < 0.4 ? 0.4 + (0.4 - value) : value;

      color = HSVColor.fromAHSV(1, hue, saturation, value).toColor();
    }

    // Find random empty neighbor cell to place child
    var neighbors = Hex.fromCube(parent.position).neighbors();
    neighbors.shuffle(rng);
    var dest = wrapPosition(
      neighbors
          .firstWhere(
            (hex) => !positions.containsKey(wrapPosition(hex.cube)),
            orElse: () => neighbors[0],
          )
          .cube,
    );
    // Forcibly replace a neighbor if we can't find an empty adjacent cell
    if (positions.containsKey(dest)) {
      removeOrganism(positions[dest]!.id);
    }

    var child = Organism(
      color: color.toARGB32(),
      energy: energy,
      position: dest,
      rotation: Hex.zero().randomNeighbor().cube,
      program: childProgram,
    );
    addOrganism(child);
  }
}

/// Return int with random RGB hexcode in the lower 24 bits
int randRGB(Random rng) {
  return (rng.nextDouble() * 0xFFFFFF).toInt() | 0xFF000000;
}

/// Find index of next largest value in sorted list
int binarySearch(List<double> data, double val) {
  int lo = 0;
  int hi = data.length - 1;
  while (lo < hi) {
    int mid = (lo + hi) ~/ 2;
    if (val > data[mid]) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  assert(lo < data.length);
  return lo;
}