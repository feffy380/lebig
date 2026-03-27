enum Op {
  nop,
  move, // move forward
  turnLeft, // rotate 60 degrees counterclockwise
  turnRight, // rotate 60 degrees clockwise
  turnRand, // turn left or right at random
  eat, // eat from current cell to gain energy
}
