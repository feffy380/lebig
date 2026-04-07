import 'package:lebig/op.dart';

// Ancestral replicator
const List<Op> ancestor = [
  // search for food
  Op.move,
  Op.eat,
  Op.eat,
  Op.turnRand,

  // padding to give evolution something to work with
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,
  Op.nopC,

  // check if enough energy
  Op.genomeSize,
  Op.n3,
  Op.mul,
  Op.energy,
  Op.hSearch,
    Op.nopC,
    Op.nopA,
  Op.ifGreater, // if 3*genomeSize > energy, skip replication loop
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