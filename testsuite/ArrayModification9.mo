// name:     ArrayModification9
// keywords: array,modification
// status:   correct
// 
// Full indexing of a multidimensional array.
// 

class ArrayModification9
  class A
    Real x[2,2];
  end A;
  A a(x[1,2] = 2.0);
end ArrayModification9;

// fclass ArrayModification9
//   Real a.x[1,1];
//   Real a.x[1,2];
//   Real a.x[2,1];
//   Real a.x[2,2];
// equation
//   a.x[1,2] = 2.0;
// end ArrayModification9;
