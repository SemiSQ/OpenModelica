// name:     Modification4
// keywords: modification
// status:   incorrect
//
// Error since no p inside A.

class A
  Integer x = 1;
end A;

class B
  A a;
end B;

class Modification4
  B b(a(p=2));
end Modification4;

// Result:
// Error processing file: Modification4.mo
// [Modification4.mo:12:3-12:6:readonly] Error: Variable b.a: In modifier (p = 2), class or component p not found in <A>
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
