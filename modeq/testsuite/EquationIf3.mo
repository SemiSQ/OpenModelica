// name:     EquationIf3
// keywords: equation
// status:   correct
// 
// Testing `if' clauses in equations.
// 

class EquationIf3
  parameter Boolean b = false;
  Real x;
equation
  if b then
    x = 1.0;
  elseif not b then
    x = 2.0;
  else
    x = 3.0;
  end if;
end EquationIf3;

// fclass EquationIf3
//   parameter Boolean b;
//   Real x;
// equation
//   b = false;
//   x = 2.0;
// end EquationIf3;
