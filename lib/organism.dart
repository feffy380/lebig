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

  // Memory. 2 stacks for Turing completeness
  // Popping from empty stack returns 0
  List<double> stackA = [];
  List<double> stackB = [];
  bool useStackB = false;

  // child buffer
  List<Op> childBuf = [];
  // allocation must be increased by grow instruction. Excess allocation is given to the child as energy when it spawns
  int allocated = 0;

  Organism({
    required this.color,
    required this.energy,
    required this.position,
    required this.rotation,
    required this.program,
  });

  Op get curInst => program[ip];

  List<double> get activeStack => useStackB ? stackB : stackA;
  set activeStack(List<double> newStack) {
    if (useStackB) {
      stackB = newStack;
    } else {
      stackA = newStack;
    }
  }
  List<double> get inactiveStack => useStackB ? stackA : stackB;

  double get deathValue => energy + program.length + childBuf.length + allocated;

  bool get isAlive => energy > 0;

  void advanceIP([int n = 1]) {
    ip = (ip + n) % program.length;
  }

  void switchStack() {
    useStackB = !useStackB;
  }

  void push(double a) {
    activeStack.add(a);
    if (activeStack.length > 128) {
      activeStack = activeStack.sublist(activeStack.length ~/ 2);
    }
  }

  double pop() {
    if (activeStack.isEmpty) {
      return 0.0;
    } else {
      return activeStack.removeLast();
    }
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
          throw StateError("Invalid writeHead in Organism $id");
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
        inactiveStack.add(pop());
      case Op.genomeSize:
        push(program.length.toDouble());
      case Op.energy:
        push(energy);
      case Op.ifLess:
        // N1 N2 ifLess: 1 < 2 ? run next instruction
        var a = pop();
        var b = pop();
        if (b >= a) { // condition false
          advanceIP(); // skip instruction
        }
      case Op.ifGreater:
        // N1 N2 ifGreater: 1 > 2 ? run next instruction
        var a = pop();
        var b = pop();
        if (b <= a) { // condition false
          advanceIP(); // skip instruction
        }
      case Op.add:
        var a = pop();
        var b = pop();
        push(a + b);
      case Op.sub:
        var a = pop();
        var b = pop();
        push(b - a);
      case Op.mul:
        var a = pop();
        var b = pop();
        push(a * b);
      case Op.div:
        var a = pop();
        var b = pop();
        if (a == 0) {
          push(1e6);
        } else {
          push(b / a);
        }
      case Op.n0:
        push(0);
      case Op.n1:
        push(1);
      case Op.n2:
        push(2);
      case Op.n3:
        push(3);
      case Op.n4:
        push(4);
    }

    advanceIP();
  }

  bool reduceEnergy(double energyCost) {
    if (energyCost > energy) {
      return false;
    }
    energy -= energyCost;
    return true;
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
