// name:     Real2Integer3
// keywords: type
// status:   correct
// 
// No implicit conversion from Real to Integer. Division via 'div' 
// gives integer output with integer input.
// 

class Real2Integer3
  Integer n1, n2;
algorithm
  n1 := integer(6.6);
  n2 := div(n1,2);
end Real2Integer3;
