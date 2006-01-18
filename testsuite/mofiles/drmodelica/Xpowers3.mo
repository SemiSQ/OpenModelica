// name:     Xpowers3
// keywords: equation,array
// status:   correct
// 
// <decription>
//

model Xpowers3
  parameter Real x=10;
  Real xpowers[n+1];
  parameter Integer n = 5;
equation
  xpowers[1]=1;
  xpowers[2:n+1] = xpowers[1:n]*x;
end Xpowers3;

// fclass Xpowers3
// parameter Real x = 10;
// Real xpowers[1];
// Real xpowers[2];
// Real xpowers[3];
// Real xpowers[4];
// Real xpowers[5];
// Real xpowers[6];
// parameter Integer n = 5;
// equation
//   xpowers[1] = 1.0;
//  xpowers[2:(1 + n)] = xpowers[1:n] * x;
// end Xpowers3;
