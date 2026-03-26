import 'dart:math';

import 'package:lebig/op.dart';
import 'package:lebig/world.dart';

/// Digital organism consisting of virtual hardware and software
class Organism {
  final int id;
  final int color;
  double energy;
  // instruction memory: hold instructions
  late List<Op> program;
  // instruction pointer
  int ip = 0;
  // memory. registers or a stack or both
  // child buffer?

  Organism({
    required this.id,
    required this.color,
    required this.energy,
    required this.program,
  });

  Op get curInst => program[ip];
  bool get isDead => energy == 0;

  void advanceIP() {
    ip = (ip + 1) % program.length;
  }

  /// Execute a single instruction
  void execute(World world) {
    switch (curInst) {
      case Op.nop:
        break;
      case Op.move:
        world.requestMove(id);
      case Op.turnLeft:
        world.requestRotate(id, -1);
      case Op.turnRight:
        world.requestRotate(id, 1);
      case Op.turnRand:
        if (world.rng.nextDouble() < 0.5) {
          world.requestRotate(id, 1);
        } else {
          world.requestRotate(id, -1);
        }
    }

    advanceIP();
  }

  void reduceEnergy(double energyCost) {
    energy -= min(energyCost, energy);
  }
}
