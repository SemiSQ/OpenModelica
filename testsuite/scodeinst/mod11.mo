// name: mod11.mo
// keywords:
// status: incorrect
// cflags:   +d=scodeInst
//
//

model A
  Real x;
end A;

model B
  extends A(final x);
end B;

model C
  B b(x = 3);
end C;

// Result:
// Error processing file: mod11.mo
// [mod11.mo:17:7-17:12:writable] Notification: From here:
// [mod11.mo:13:19-13:20:writable] Error: Trying to override final component x with modifier 3
// 
// Error: Error occurred while flattening model C
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
