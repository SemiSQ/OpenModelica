// name:     Faculty3
// keywords: algorithm
// status:   correct
// 
// Definition of faculty using a while loop. The while loop can not be
// unrolled.
//

function Faculty3
  input Integer x;
  output Integer y;
protected
  Integer i;
algorithm
  y := 1;
  i := 2;
  while (i <= x) loop
    y := i * y;
    i := i + 1;
  end while;
end Faculty3;

model Faculty3Model
  Integer x;
  Integer y;
equation
  y = Faculty3(x);
end Faculty3Model;

// function Faculty3
// input Integer x;
// output Integer y;
// Integer i;
// algorithm
//   y := 1;
//   i := 2;
//   while i <= x loop
//     y := i * y;
//     i := i + 1;
//   end while;
// end Faculty3;
// 
// Result:
// fclass Faculty3Model
// Integer x;
// Integer y;
// equation
//   y = Faculty3(x);
// end Faculty3Model;
// endResult
