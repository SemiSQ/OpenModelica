// name:     Integer2Real
// keywords: type
// status:   correct
// 
// Automatic conversion from Integer to Real.
//

class Integer2Real
  Integer n;
  Real a;
equation
  n = 5;
  a = n / 2;
end Integer2Real;

// fclass Integer2Real
// Integer n;
// Real a;
// equation
//   n = 5;
//   a = Real(n) * 1.0 / 2.0;
// end Integer2Real;
