// name:     tupleSubset
// keywords: function call returning tuples, which are not matched on left side.
// status:   correct
// 
// test to expand tuple, size 2,  and non tuple into tuples of size 3.

function fooTuple
input Real x;
output Real y;
output Real y2;
output Real y3;
algorithm 
  y := (x)*2;
  y2 := (y)*2;
  y3 := (y2)*2;
end fooTuple;

model mo
Real x;
Real y;
Real z;
Real xvar(start=100);
equation 
 xvar = der(xvar);
 (x,z) = fooTuple(xvar);
 y = fooTuple(der(xvar)); 
end mo;
// fclass mo
// Real x;
// Real y;
// Real z;
// Real xvar(start = 100.0);
// equation
//   xvar = der(xvar);
//   (x,z,_) = fooTuple(xvar);
//   (y,_,_) = fooTuple(der(xvar));
// end mo;
