// This tests basic function functionality

function f
  input Real x;
  output Real r;
algorithm
  r := 2.0 * x;
end f;

model M
  Real x, y, z;
equation
  x = f(z);
  y = f(z);
end M;

// Variables:
//
//   variable real f#1.x
//   variable real f#1.r
//   variable real f#2.x
//   variable real f#2.r
//   variable real x
//   variable real y
//   variable real z
//
// Equations:
//
//   f#1.x = z
//   f#1.r = x
//   f#2.x = z
//   f#2.r = y
//
// Algorithms:
//
//   f#1.r := 2.0 *(Real) f#1.x
//
//   f#2.r := 2.0 *(Real) f#2.x
//
