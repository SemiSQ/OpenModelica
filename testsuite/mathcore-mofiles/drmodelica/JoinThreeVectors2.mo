// name:     joinThreeVectors
// keywords: external functions
// status:   correct
// 
// External C function with column-major arrays
//


function joinThreeVectors2 
  input Real v1[:],v2[:],v3[:];
  output Real vres[size(v1,1)+size(v2,1)+size(v3,1)];
external "C"
  join3vec(v1,v2,v3,vres,size(v1,1),size(v2,1),size(v3,1));
  annotation(arrayLayout = "columnMajor");
end joinThreeVectors2;

model joinThreeVectors
  Real a[2]={1,2};
  Real b[3]={3,4,5};
  Real c[4]={6,7,8,9};
  Real x[9];
algorithm
  x:=joinThreeVectors2(a,b,c);
end joinThreeVectors;

// Result:
// function joinThreeVectors2
// input Real v1;
// input Real v2;
// input Real v3;
// output Real vres;
// 
// external "C";
// end joinThreeVectors2;
// 
// fclass joinThreeVectors
// Real a[1] = 1.0;
// Real a[2] = 2.0;
// Real b[1] = 3.0;
// Real b[2] = 4.0;
// Real b[3] = 5.0;
// Real c[1] = 6.0;
// Real c[2] = 7.0;
// Real c[3] = 8.0;
// Real c[4] = 9.0;
// Real x[1];
// Real x[2];
// Real x[3];
// Real x[4];
// Real x[5];
// Real x[6];
// Real x[7];
// Real x[8];
// Real x[9];
// algorithm
//   x := joinThreeVectors2({a[1],a[2]},{b[1],b[2],b[3]},{c[1],c[2],c[3],c[4]});
// end joinThreeVectors;
// endResult
