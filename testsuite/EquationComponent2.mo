// name:     EquationComponent2
// keywords: equation
// status:   correct
// 
// When an equation is between to complex types, the equation is split
// into separate equations for the components.
// 

class EquationComponent2
  record R
    Real x,y;
  end R;
  R a,b,c;
equation
  a = if true then b else c;
end EquationComponent2;

// fclass EquationComponent2
// 	       Real    a.x;
// 	       Real    a.y;
// 	       Real    b.x;
// 	       Real    b.y;
// 	       Real    c.x;
// 	       Real    c.y;
// equation
//   __TMP__0 ::= if true then b else c;
//   a.x = __TMP__0.x;
//   a.y = __TMP__0.y;
// end EquationComponent2;
