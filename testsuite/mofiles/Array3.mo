// name:     Array3
// keywords: array
// status:   correct
// 
// This is a simple test of basic matrix handling.
// 

model Array3
  Integer x[2,3] = [ 1,2,3 ; 4,5,6 ] ;
end Array3;


// Result:
// fclass Array3
//   Integer x[1,1];
//   Integer x[1,2];
//   Integer x[1,3];
//   Integer x[2,1];
//   Integer x[2,2];
//   Integer x[2,3];
// equation
//   x[1,1] = 1;
//   x[1,2] = 2;
//   x[1,3] = 3;
//   x[2,1] = 4;
//   x[2,2] = 5;
//   x[2,3] = 6;
// end Array3;

// origfclass Array3
//   Integer x[1,1];
//   Integer x[1,2];
//   Integer x[1,3];
//   Integer x[2,1];
//   Integer x[2,2];
//   Integer x[2,3];
// equation
//   x[1,1] = [1,2,3;4,5,6][1][1];
//   x[1,2] = [1,2,3;4,5,6][1][2];
//   x[1,3] = [1,2,3;4,5,6][1][3];
//   x[2,1] = [1,2,3;4,5,6][2][1];
//   x[2,2] = [1,2,3;4,5,6][2][2];
//   x[2,3] = [1,2,3;4,5,6][2][3];
// origend Array3;
// endResult
