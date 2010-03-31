// name:     VectorizeSeveralArguments
// keywords: array
// status:   incorrect

class SeveralArguments

	Real a = 1, b = 0, c = 1, d = 0, e = 1, f = 0;

	Real at[3] = atan2({a, b, c}, {d, e, f}); 
	// Result: {atan2(a, d), atan2(b, e), atan2(c, f)}

	Real atAdd[2] = atan2Add(2, {a, b}, {d, e}); 
	// Result: {2 + atan2(a, d), 2 + atan2(b, e)}

end SeveralArguments;
// Result:
// Error processing file: VectorizeSeveralArguments.mo
// Error: Class atan2Add (its type)  not found in scope SeveralArguments.
// Error: No matching function found for atan2Add
// Error: Class atan2Add not found in scope SeveralArguments.
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
