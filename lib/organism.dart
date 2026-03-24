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
      // TODO: movement instruction
      // - needs access to world and own ID. could pass world and store own ID,
      // or pass an execution context object?
      // - only moves forward for now, which means we need rotate ops
      // world.requestMove(id)
    }

    ip = (ip + 1) % program.length;
  }
}
