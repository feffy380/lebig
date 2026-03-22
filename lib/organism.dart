import 'package:lebig/op.dart';

/// Memory and processor state of a digital organism
class Organism {
  final int color;
  // instruction memory: hold instructions
  late List<Op> program = [];
  // instruction pointer
  int ip = 0;
  // memory. registers or a stack or both
  // child buffer?

  Organism({required this.color, required this.program});

  void execute() {
    var opcode = program[ip];

    switch (opcode) {
      case Op.nop:
        break;
      // TODO: movement instruction
      // - needs access to world and own ID. could pass world and store own ID,
      // or pass an execution context object?
      // - only moves forward, which means we need rotate ops
      // world.requestMove(id)
    }

    ip = (ip + 1) % program.length;
  }
}
