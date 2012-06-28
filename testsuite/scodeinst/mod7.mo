// name: mod7.mo
// keywords:
// status: correct
//

model A
  Real x;
end A;

model B
  A a[3];
end B;

model C
  B b3[2](each a(x = {1, 2, 3}));
  B b4[2](each a.x = 1);
end C;

// Result:
// 
// EXPANDED FORM:
// 
// class C
//   Real b3[1].a[1].x = 1;
//   Real b3[1].a[2].x = 2;
//   Real b3[1].a[3].x = 3;
//   Real b3[2].a[1].x = 1;
//   Real b3[2].a[2].x = 2;
//   Real b3[2].a[3].x = 3;
//   Real b4[1].a[1].x = 1;
//   Real b4[1].a[2].x = 1;
//   Real b4[1].a[3].x = 1;
//   Real b4[2].a[1].x = 1;
//   Real b4[2].a[2].x = 1;
//   Real b4[2].a[3].x = 1;
// end C;
// 
// 
// Found 12 components and 0 parameters.
// class C
//   Real b3[1].a[1].x = 1.0;
//   Real b3[1].a[2].x = 2.0;
//   Real b3[1].a[3].x = 3.0;
//   Real b3[2].a[1].x = 1.0;
//   Real b3[2].a[2].x = 2.0;
//   Real b3[2].a[3].x = 3.0;
//   Real b4[1].a[1].x = 1.0;
//   Real b4[1].a[2].x = 1.0;
//   Real b4[1].a[3].x = 1.0;
//   Real b4[2].a[1].x = 1.0;
//   Real b4[2].a[2].x = 1.0;
//   Real b4[2].a[3].x = 1.0;
// end C;
// endResult
