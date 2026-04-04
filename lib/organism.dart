import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:lebig/op.dart';
import 'package:lebig/world.dart';

/// Digital organism consisting of virtual hardware and software
class Organism {
  late final int id;
  final int color;
  double energy;
  Cube position;
  Cube rotation;
  // instruction memory: hold instructions
  late List<Op> program;

  // Heads
  int ip = 0; // instruction pointer
  int flowHead = 0; // for jumps
  int readHead = 0;
  int writeHead = 0; // points to start of child buffer

  // memory. 2 stacks for Turing completeness
  List<double> stackA = [];
  List<double> stackB = [];
  bool activeStackA = true;

  // child buffer
  List<Op> childBuf = [];
  // allocation must be increased by grow instruction. Excess allocation is given to the child as energy when it spawns
  int allocated = 0;

  /*
  # Replicator:
  h-search: set flow head
  grow: grow child buffer by 1
  h-copy: copy instruction from read head to write head, advance both
  if-n-label: label not copied
    nop template
    jump to flow head
  divide
  nop template

  Can h-copy and if-label be generalized? feels cheaty that h-copy can read, write, and advance two heads all at once.
  But splitting it up would require storing instructions in regular memory, leading to the potential for writing arbitrary
  values to the child buffer, which would need to be converted to instructions somehow.
  We could just index into list of Ops modulo its length
  */

  Organism({
    required this.color,
    required this.energy,
    required this.position,
    required this.rotation,
    required this.program,
  });

  Op get curInst => program[ip];

  List<double> get activeStack => activeStackA ? stackA : stackB;
  List<double> get inactiveStack => activeStackA ? stackB : stackA;

  void advanceIP([int n = 1]) {
    ip = (ip + n) % program.length;
  }

  void switchStack() {
    activeStackA = !activeStackA;
  }

  /// Execute a single instruction
  void execute(World world) {
    switch (curInst) {
      case Op.nopA:
      case Op.nopB:
      case Op.nopC:
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
      case Op.eat:
        world.requestEat(id);
      case Op.grow:
        world.requestGrow(id);
      case Op.hCopy:
        if (allocated == 0) {
          break;
        }
        // copy instruction
        var copiedOp = program[readHead];
        if (writeHead < childBuf.length) {
          childBuf[writeHead] = copiedOp;
        } else if (writeHead == childBuf.length) {
          childBuf.add(copiedOp);
        } else {
          throw Exception("Invalid writeHead in Organism $id");
        }
        // advance heads
        readHead = (readHead + 1) % program.length;
        writeHead++;
        allocated--;
      case Op.hSearch:
        var (matchPos, templateLen) = findTemplate();
        // Move flow head to the end of the label instead of after it due to the final advanceIP() call after a jump
        flowHead = matchPos;
        // Skip NOPs encountered as a label or modifier. They still consume a cycle when encountered as an instruction
        advanceIP(templateLen);
      case Op.ifNotLabel:
        // Get template length
        int templateStart = (ip + 1) % program.length;
        int len = getTemplateLen(templateStart);

        // Compare templates
        bool match = true;
        if (writeHead - len < 0) {
          match = false;
        } else {
          for (int i = 0; i < len; i++) {
            var label = program[(templateStart + i) % program.length];
            var target = childBuf[(writeHead - len + i) % childBuf.length];
            if (label.complement != target) {
              match = false;
              break;
            }
          }
        }
        advanceIP(len); // skip NOPs
        // if matching label is found, skip the next instruction
        if (match) advanceIP();
      case Op.moveHead:
        ip = flowHead;
      case Op.divide:
        world.createOffspring(this);
        // Reset heads and child buffer
        readHead = 0;
        writeHead = 0;
        childBuf = [];
        allocated = 0;
      case Op.swap:
        switchStack();
      case Op.transfer:
        if (activeStack.isNotEmpty) {
          var a = activeStack.removeLast();
          inactiveStack.add(a);
        }
    }

    advanceIP();
  }

  bool reduceEnergy(double energyCost) {
    if (energyCost < energy) {
      energy -= energyCost;
      return true;
    }
    return false;
  }

  void increaseEnergy(double eaten) {
    energy += eaten;
  }

  /// Increase child buffer max size
  void grow(int amount) {
    allocated += amount;
  }

  /// Find complement of template following IP.
  /// Returns (end of complement, template length).
  /// If no template follows, return IP
  (int, int) findTemplate() {
    int templateStart = (ip + 1) % program.length;
    int len = getTemplateLen(templateStart);
    int i = templateStart;
    int j = (templateStart + len) % program.length;
    while (j != templateStart) {
      var tOp = program[i];
      var cOp = program[j];

      if (cOp == tOp.complement) {
        i = (i + 1) % program.length;
        if (i == templateStart + len) {
          // reached end of template, and therefore found a matching complement
          return (j, len);
        }
      } else {
        i = templateStart;
      }
      j = (j + 1) % program.length;
    }
    // no match found
    return (ip, len);
  }

  /// Measure length of the template at a certain index
  int getTemplateLen(int start) {
    int n = 0;
    int i = start;
    while (program[i].isNop) {
      n++;
      i = (i + 1) % program.length;
      if (i == start) break;
    }
    return n;
  }
}
