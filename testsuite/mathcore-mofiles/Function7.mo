// name:     Function7
// keywords: function
// status:   incorrect
// 
// This tests basic function functionality
//

function f
  input Real x;
  output Real r;
algorithm
  r := 2.0 * x;
end f;

model Function7
  String x;
  Real z;
equation
  x = f(z);
end Function7;
// Result:
// Error processing file: Function7.mo
// Error: Type mismatch in equation x=f(z) of type String=Real
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
