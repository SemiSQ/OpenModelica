// name:     Equations
// keywords: equation
// status:   correct


class Equations
  Real x(start = 2);				// Modification equation
  constant Integer one = 1;			// Declaration equation
equation
  x = 3*one;						// Normal equation 
end Equations;


// fclass Equations
// Real x(start=2.0);
// constant Integer one = 1;
// equation
//   x = 3.0;
// end Equations;
