// name:     Lookup6
// keywords: scoping
// status:   correct
// 
// The constant 'a' is hidden in class 'B' after the declaration 
// of 'B.a'.
//

class Lookup6
  constant Real a = 3.0;
  class B
    Real a;
  equation
    a = -a;
  end B;
  B b;
end Lookup6;

// fclass Lookup6
//   constant Real a;
//   Real b.a;
// equation
//   a = 3.0;
//   b.a = -b.a;
// end Lookup6;

