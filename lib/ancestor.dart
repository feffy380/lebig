import 'package:lebig/op.dart';

// Ancestral replicator
const List<Op> ancestor = [
  // search for food
  Op.move,
  Op.eat,
  Op.eat,
  Op.eat,
  Op.turnRand,

  // check if enough energy
  Op.energy,
  Op.genomeSize,
  Op.genomeSize,
  Op.add,
  Op.hSearch,
    Op.nopC,
    Op.nopA,
  Op.ifLess, // if energy < genomeSize + genomeSize, skip replication loop
    Op.moveHead,

  // replication loop
  Op.hSearch, // mark start of copy loop
  Op.grow, // allocate space for copying
  Op.grow, // extra allocation for initial child energy
  Op.hCopy,
  Op.ifNotLabel, // if we didn't copy the "end of program" label...
    Op.nopC,
    Op.nopA,
    Op.moveHead, // ...jump back to start of copy loop
  Op.divide, // split off child organism
  Op.nopA, // label end of program
  Op.nopB,
];