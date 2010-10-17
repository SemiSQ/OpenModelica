// name: MatchCase14
// cflags: +g=MetaModelica
// status: correct
package MatchCase14

function fn
  input Integer i;
  output Integer outInt;
algorithm
  outInt := match i
    case -3 then -3;
  end match;
end fn;

constant Integer i = fn(-3);

end MatchCase14;
// Result:
// function MatchCase14.fn
//   input Integer i;
//   output Integer outInt;
// algorithm
//   _ := #VALUEBLOCK#;
// end MatchCase14.fn;
// 
// class MatchCase14
//   constant Integer i = -3;
// end MatchCase14;
// endResult
