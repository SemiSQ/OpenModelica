// name:     FiveForEquations
// keywords: for
// status:   correct
// 

class FiveForEquations 
  Real[5] x;
equation
  for i in 1:5 loop
    x[i] = i + 1;
  end for;
end FiveForEquations;

// Result:
// fclass FiveForEquations
// Real x[1];
// Real x[2];
// Real x[3];
// Real x[4];
// Real x[5];
// equation
//   x[1] = 2.0;
//   x[2] = 3.0;
//   x[3] = 4.0;
//   x[4] = 5.0;
//   x[5] = 6.0;
// end FiveForEquations;
// endResult
