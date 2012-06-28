// name: func1.mo
// keywords:
// status: correct
// cflags:   +d=scodeInst
//


model A
  constant Real z;

  function f
    input Real x;
    output Real y;
  algorithm
    y := x * z;
  end f;

  constant Real w = f(z);
end A;

model B
  A a1(z = 2.0);
  A a2(z = 3.0);
  Real x = a1.w;
  Real y = a2.w;
end B;

// Result:
// SCodeInst.instFunction failed: f
// Error processing file: func1.mo
// Error: Error occurred while flattening model B
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
