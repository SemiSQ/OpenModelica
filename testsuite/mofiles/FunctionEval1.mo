// name:     FunctionEval1
// keywords: function,constant propagation
// status:   correct
// 
// Constant evaluation of function calls. Result of a function call with 
// constant arguments is inserted into flat modelica.
// 

function f
  input  Real x;
  output Real y;
algorithm
  y := x + 1;
end test;

model FunctionEval1
  Real x;
equation
  x = f(1);
end FunctionEval1;

// function f
// input Real x;
// output Real y;
// algorithm
//   y := x + 1.0;
// end f;
// 
// fclass FunctionEval1
// Real x;
// equation
//   x = 2.0;
// end FunctionEval1;


