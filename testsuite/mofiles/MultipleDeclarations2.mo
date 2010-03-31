// name:     MultipleDeclarations2
// keywords: declaration
// status:   correct
// 
// Multiple declarations must be identical and should only generate one instance.
//


model MultipleDeclarations2
  Real x;
  Real x;
end MultipleDeclarations2;

// Result:
// fclass MultipleDeclarations2
//   Real x;
// end MultipleDeclarations2;
// endResult
