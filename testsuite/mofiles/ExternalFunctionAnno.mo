// name:     Derivative Annotation
// keywords: functions, index reduction
// status:   correct
// 

function f1
  annotation(derivative=df1);
  input Real a;
  output Real b;
  external b = myfoo(a) annotation(derivative=df1,Library="foo.o",Include="#include \"myfoo.h\"");
end f1;

function df1
  input Real a;
  input Real b;
  output Real c;
  external c = dmyfoo(a,b) annotation(Library="foo.o",Include="#include \"myfoo.h\"");
end df1;  

package FooFunctions
function foo0 
  input Real x;
  output Real y;
  external "C" y=sin(x) annotation(derivative=foo1); 
end foo0;

function foo1
  input Real x;
  input Real der_x;
  output Real der_y;
  external "C" der_y=cos(x) annotation(derivative=foo2); 
end foo1;

function foo2
  input Real x;
  input Real der_x;
  input Real derder_x;
  input Real derderder_x;
  output Real der_der_y;
  external "C" der_der_y=sin(x); 
end foo2;

end FooFunctions;

model extfunction
  Real y1,y2;
  Real t;
  Real x(start=1);
  Real z[3];
  Real u[3](each fixed=false);  
equation
 t = time -x;
 y1 = f1(t);
 y2 = der(y1);
 der(x) = y1 + y2;
 z[1]=FooFunctions.foo0(exp(time));
 der(z[1:2])=z[2:3];
 z[3]=u[3];
 der(u[1:2])=u[2:3]; 
end extfunction;

// Result:
// function FooFunctions.foo0
//   input Real x;
//   output Real y;
// 
// external "C";
// end FooFunctions.foo0;
// 
// function FooFunctions.foo1
//   input Real x;
//   input Real der_x;
//   output Real der_y;
// 
// external "C";
// end FooFunctions.foo1;
// 
// function FooFunctions.foo2
//   input Real x;
//   input Real der_x;
//   input Real derder_x;
//   input Real derderder_x;
//   output Real der_der_y;
// 
// external "C";
// end FooFunctions.foo2;
// 
// function df1
//   input Real a;
//   input Real b;
//   output Real c;
// 
// external "C";
// end df1;
// 
// function f1
//   input Real a;
//   output Real b;
// 
// external "C";
// end f1;
// 
// class extfunction
//   Real y1;
//   Real y2;
//   Real t;
//   Real x(start = 1.0);
//   Real z[1];
//   Real z[2];
//   Real z[3];
//   Real u[1](fixed = false);
//   Real u[2](fixed = false);
//   Real u[3](fixed = false);
// equation
//   t = time - x;
//   y1 = f1(t);
//   y2 = der(y1);
//   der(x) = y1 + y2;
//   z[1] = FooFunctions.foo0(exp(time));
//   der(z[1]) = z[2];
//   der(z[2]) = z[3];
//   z[3] = u[3];
//   der(u[1]) = u[2];
//   der(u[2]) = u[3];
// end extfunction;
// endResult
