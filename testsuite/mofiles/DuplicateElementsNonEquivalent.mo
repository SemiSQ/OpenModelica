// name:     DuplicateElementsNonEquivalent
// keywords: check if duplicate elements are the same! even if they (in the end, via X, Y) point to the same class Real, they are not the same
// status:   incorrect

package Crap
  type X = Real;
  type Y = Real;
end Crap;

model DuplicateElementsNonEquivalent
 Crap.Y x;
 Crap.X x;
end DuplicateElementsNonEquivalent;

// Result:
// Error processing file: DuplicateElementsNonEquivalent.mo
// [DuplicateElementsNonEquivalent.mo:12:2-12:10:writable] Error: An element with name x is already declared in this scope.
// Error: Error occurred while flattening model DuplicateElementsNonEquivalent
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
