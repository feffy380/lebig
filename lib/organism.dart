import 'package:lebig/op.dart';
import 'package:lebig/world.dart';

/// Memory and processor state of a digital organism
class Organism {
  final int id;
  final int color;
  // instruction memory: hold instructions
  late List<Op> program = [];
  // instruction pointer
  int ip = 0;
  // memory. registers or a stack or both
  // child buffer?

  Organism({required this.id, required this.color, required this.program});

  /// Execute a single instruction
  void execute(World world) {
    var opcode = program[ip];

    switch (opcode) {
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

    ip = (ip + 1) % program.length;
  }
}
