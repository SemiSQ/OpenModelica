// name: mod1.mo
// keywords:
// status: correct
// cflags:   +d=scodeInst
//

model M
  Real z;
end M;

model A
  extends M;
  Real x;
end A;

model B
  extends A;
  Real y;
end B;

model C
  B b(x = 1.0, y = 2.0, z = 4.0);
end C;

// Result:
// 
// EXPANDED FORM:
// 
// class C
//   Real b.z = 4.0;
//   Real b.x = 1.0;
//   Real b.y = 2.0;
// end C;
// 
// 
// Found 3 components and 0 parameters.
// class C
//   Real b.z = 4.0;
//   Real b.x = 1.0;
//   Real b.y = 2.0;
// end C;
// endResult
