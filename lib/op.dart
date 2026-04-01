enum Op {
  nopA, nopB, nopC,
  move, // move forward
  turnLeft, // rotate 60 degrees counterclockwise
  turnRight, // rotate 60 degrees clockwise
  turnRand, // turn left or right at random
  eat, // eat from current cell to gain energy
  grow, // use energy to increase child buffer size
  hCopy, // copy instruction under read head to write head in child, advance both heads
  hSearch, // search for complement of the template following this instruction and place the flow head after it
  // if-not-label
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
