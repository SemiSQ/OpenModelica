// name: AssignmentErrorConstant
// status: incorrect

model AssignmentErrorConstant
  constant Real r = 5.0;
algorithm
  r := 3.0;
end AssignmentErrorConstant;

// Result:
// Error processing file: AssignmentErrorConstant.mo
// [AssignmentErrorConstant.mo:7:3-7:11:writable] Error: Trying to assign to constant component 5.0
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
