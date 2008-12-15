// name:     FunctionEval9
// keywords: function,constant propagation
// status:   correct
// 
// Constant evaluation of function calls. Result of a function call with 
// constant arguments is inserted into flat modelica. 


function test2
  input Real a[3];
  output Real b[4];
algorithm
  for i in 1:3 loop
    b[i] := a[i]*2;
  end for;
  b[4]:=3;
end test2;

function test3
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 7;
end test3;

function test
  input  Real x;
  output Real y;
protected
algorithm
  y := cos(x) + 4;
end test;

model FunctionEval9
  parameter Real a=5;
  parameter Real b[3]={1,2,3};
  Real x1=test(a);
  parameter Real x2=size(test2(b),1);
  Real y;
  Real z;
equation
  y = test3(x1+x2);
  z = test(y);
end FunctionEval9;



// function test2
// input Real a;
// output Real b;
// algorithm
//   for i in 1:3 loop
//     b[i] := a[i] * 2.0;
//   end for;
//   b[4] := 3.0;
// end test2;
// 
// function test3
// input Real x;
// output Real y;
// algorithm
//   y := x + 7.0;
// end test3;
// 
// function test
// input Real x;
// output Real y;
// algorithm
//   y := cos(x) + 4.0;
// end test;
// 
// fclass FunctionEval9
// parameter Real a = 5;
// parameter Real b[1] = 1;
// parameter Real b[2] = 2;
// parameter Real b[3] = 3;
// Real x1 = test(a);
// parameter Real x2 = 4;
// Real y;
// Real z;
// equation
//   y = test3(x1 + x2);
//   z = test(y);
// end FunctionEval9;
