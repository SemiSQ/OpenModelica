// name: func6.mo
// keywords:
// status: incorrect
// cflags:   +d=scodeInst
//

model A
  Real x;
end A;

function f
  input A a;
  output Real x;
algorithm
  x := a.x;
end f;

model M
  A a;
  Real x = f(a);
end M;

// Result:
// SCodeInst.instFunction failed: f
// Error processing file: func6.mo
// [func6.mo:12:3-12:12:writable] Error: Invalid type A for function component a.
// Error: Error occurred while flattening model M
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
