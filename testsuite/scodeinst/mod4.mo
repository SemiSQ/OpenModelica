// name: mod4.mo
// keywords:
// status: correct
// cflags:   +d=scodeInst
//


model M
  Real z;
end M;

model A
  Real x;
  M m;
end A;

model B
  Real y;
  A a;
end B;

model C
  B b(a(x = 1.0), y = 2.0, a(m(z = 3.0)));
  //B b(y = 1.0, y = 2.0);
end C;

// Result:
// 
// EXPANDED FORM:
// 
// class C
//   Real b.y = 2.0;
//   Real b.a.x = 1.0;
//   Real b.a.m.z = 3.0;
// end C;
// 
// 
// Found 3 components and 0 parameters.
// class C
//   Real b.y = 2.0;
//   Real b.a.x = 1.0;
//   Real b.a.m.z = 3.0;
// end C;
// endResult
