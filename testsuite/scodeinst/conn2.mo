// name: conn2.mo
// keywords:
// status: incorrect
// cflags:   +d=scodeInst
//

model A
  connector C
    Real e;
    flow Real f;
  end C;

  C c1, c2;
algorithm
  connect(c1, c2);
end A;

// Result:
// Error processing file: conn2.mo
// [conn2.mo:15:3-15:9:writable] Error: No viable alternative near token: connect
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
