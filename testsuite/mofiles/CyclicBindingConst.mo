// name: CyclicBindingConst
// keywords: cyclic
// status: incorrect
//
// Tests cyclic binding of constants
//

model CyclicBindingConst
  constant Real p = 2*q;
  constant Real q = 2*p;
end CyclicBindingConst;

// Result:
// Error processing file: CyclicBindingConst.mo
// Error: Cyclically dependent constants or parameters found in scope CyclicBindingConst: {q,p}
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
