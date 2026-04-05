enum Op {
  nopA, nopB, nopC,
  move, // Move forward
  turnLeft, // Rotate 60 degrees counterclockwise
  turnRight, // Rotate 60 degrees clockwise
  turnRand, // Turn left or right at random
  eat, // Eat from current cell to gain energy
  grow, // Use energy to increase child buffer size
  hCopy, // Copy instruction under read head to write head in child, advance both heads
  hSearch, // Search for complement of the template following this instruction and place the flow head after it
  ifNotLabel, // Reads label and tests if its complement was just written. If so, skip the next instruction. We use the negation because unlike avida we don't reset on divide
  moveHead, // Move instruction pointer to flow head
  divide, // Split off child buffer into a new organism. Excess buffer capacity is given to the child as energy.
  swap, // Swap between stacks
  transfer, // Move top of active stack to inactive stack
  genomeSize, // Push the program length to the stack
  energy, // Push current stored energy amount to the stack
  ifLess, // Pop two values A and B from the stack. Run the next instruction if B is less than A
  // TODO: separate comparisons from conditional jump. ifLess could be implemented as two instructions
  // TODO: constants 0-4
  // TODO: arithmetic
  // TODO: logical
  ;

  bool get isNop {
    switch (this) {
      case nopA:
      case nopB:
      case nopC:
        return true;
      default:
        return false;
    }
  }

  Op get complement {
    switch (this) {
      case nopA:
        return nopB;
      case nopB:
        return nopC;
      case nopC:
        return nopA;
      default:
        return this;
    }
  }
}
