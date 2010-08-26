// name:     Enum11
// keywords: enumeration enum
// status:   correct
// 
// Tests integer conversion of enumeration types.
// 

model Enum11
 
type MyEnum=enumeration(A,B,C);
 
MyEnum A=MyEnum.A;
 
Integer i = Integer(A);
end Enum11;
// Result:
// fclass Enum11
//   enumeration(A, B, C) A = MyEnum.A;
//   Integer i = Integer(A);
// end Enum11;
// endResult
