// name:     ConditionalArrayExpression2
// keywords: equation,array
// status:   correct
// 
// The sizes must fit in array expressions and equations.

model ConditionalArrayExpression2
  Real a=time*4, b=2.0, c[2], d, e;
equation
  {d, e} = if a > b then c else {e, d*2+1};
  if time < 0.5 then
     c = {1,0};
  else
     c[1] = 2;
     c[2] = 4;
  end if;
end ConditionalArrayExpression2;

// fclass ConditionalArrayExpression2
//   Real a;
//   Real b;
//   Real c[2];
//   Real d;
//   Real e;
// equation
//   a = time
//   b = Real(2);
//   d = if a > b then c[1] else e;
//   e = if a > b then c[2] else d*2+1;
//  if time < 0.5 then
//     c = {1,0};
//  else
//     c[1] = 2;
//     c[2] = 4;
//  end if;
// end ConditionalArrayExpression2;
