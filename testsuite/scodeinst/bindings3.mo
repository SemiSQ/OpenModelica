// name: bindings3.mo
// keywords:
// status: correct
// cflags:   +d=scodeInst
//


model A
  Real x;
  Real y;
end A;

model B
  A a[3];
end B;

model C
  B b[2](a.x = {{1, 2, 3}, {4, 5, 6}}, a(each y = 2.0));
end C;

// Result:
// 
// EXPANDED FORM:
// 
// class C
//   Real b[1].a[1].x = 1;
//   Real b[1].a[1].y = 2.0;
//   Real b[1].a[2].x = 2;
//   Real b[1].a[2].y = 2.0;
//   Real b[1].a[3].x = 3;
//   Real b[1].a[3].y = 2.0;
//   Real b[2].a[1].x = 4;
//   Real b[2].a[1].y = 2.0;
//   Real b[2].a[2].x = 5;
//   Real b[2].a[2].y = 2.0;
//   Real b[2].a[3].x = 6;
//   Real b[2].a[3].y = 2.0;
// end C;
// 
// 
// Found 12 components and 0 parameters.
// class C
//   Real b[1].a[1].x = 1.0;
//   Real b[1].a[1].y = 2.0;
//   Real b[1].a[2].x = 2.0;
//   Real b[1].a[2].y = 2.0;
//   Real b[1].a[3].x = 3.0;
//   Real b[1].a[3].y = 2.0;
//   Real b[2].a[1].x = 4.0;
//   Real b[2].a[1].y = 2.0;
//   Real b[2].a[2].x = 5.0;
//   Real b[2].a[2].y = 2.0;
//   Real b[2].a[3].x = 6.0;
//   Real b[2].a[3].y = 2.0;
// end C;
// endResult
