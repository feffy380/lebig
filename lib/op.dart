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
  // jump to flow head
  // divide
  ;

  bool isNop() {
    switch (this) {
      case nopA:
      case nopB:
      case nopC:
        return true;
      default:
        return false;
    }
  }

  Op complement() {
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
