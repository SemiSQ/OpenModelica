// name: Cos
// keywords: cos
// status: correct
//
// Tests the built-in cos function
//

model Cos
  Real r;
equation
  r = cos(45);
end Cos;

// Result:
// class Cos
// Real r;
// equation
//   r = 0.52532198881773;
// end Cos;
// endResult
