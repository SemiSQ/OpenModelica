// name:     Array10
// keywords: array
// status:   correct
// 
// An array of mixed integer and reals is automatically cast to an 
// array of Reals. Fixes bug #37
// 

model Array10
  Real x[5] = {1.,2,3.0,4,5.0};
  Real y[:,:] = {{1,2.},{3.,4}};
end Array10;


// fclass Array10
// Real x[1] = 1.0;
// Real x[2] = 2.0;
// Real x[3] = 3.0;
// Real x[4] = 4.0;
// Real x[5] = 5.0;
// Real y[1,1] = 1.0;
// Real y[1,2] = 2.0;
// Real y[2,1] = 3.0;
// Real y[2,2] = 4.0;
// end Array10;
