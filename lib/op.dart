enum Op {
  nopA, nopB, nopC,
  move, // move forward
  turnLeft, // rotate 60 degrees counterclockwise
  turnRight, // rotate 60 degrees clockwise
  turnRand, // turn left or right at random
  eat, // eat from current cell to gain energy
  grow, // use energy to increase child buffer size
  hCopy, // copy instruction under read head to write head in child, advance both heads
}
