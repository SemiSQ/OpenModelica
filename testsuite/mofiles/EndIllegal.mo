// name: EndIllegal
// status: incorrect

model M
  Real r = end;
end M;

// Result:
// Error processing file: EndIllegal.mo
// [EndIllegal.mo:5:3-5:15:writable] Error: 'end' can not be used outside array subscripts.
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
