// name: BlockComponents
// keywords: block
// status: correct
//
// Tests declaration and instantiation of a block with components in it
//

block TestBlock
  input Integer inInt;
  output Integer outInt;
equation
  outInt / 2 = inInt;
end TestBlock;

model BlockComponents
  Integer i;
  TestBlock tb;
equation
  tb.inInt = 3;
  i = tb.outInt;
end BlockComponents;

// Result:
// fclass BlockComponents
// Integer i;
// input Integer tb.inInt;
// output Integer tb.outInt;
// equation
//   Real(tb.outInt) / 2.0 = Real(tb.inInt);
//   tb.inInt = 3;
//   i = tb.outInt;
// end BlockComponents;
// endResult
