// name: mod5.mo
// keywords:
// status: incorrect
// cflags:   +d=scodeInst
//


model A
  Real x;
end A;

model B
  A a(y = 2.0);
end B;

// Result:
// Error processing file: mod5.mo
// [mod5.mo:13:7-13:14:writable] Error: Modified element y not found in class a
// 
// Error: Error occurred while flattening model B
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
