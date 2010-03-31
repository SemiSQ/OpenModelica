// name:     VectorDimension
// keywords: vector dimension
// status:   correct
// 
// This tests checks dimension validation in vector.
// 
model VectorDimension
  Real x[2];
equation
x = vector([1;3]);
end VectorDimension;

// fclass VectorDimension
// Real x[1];
// Real x[2];
// equation
//   x[1] = 1.0;
//   x[2] = 3.0;
// end VectorDimension;
