// name: MatchCase16
// cflags: +g=MetaModelica
// status: correct

package MatchCase16

function fn
  input String str;
  output String outStr;
algorithm
  "" := match str
    case str then str;
  end match;
  outStr := "";
end fn;

constant String str = fn("");

end MatchCase16;

// Result:
// function MatchCase16.fn
//   input String str;
//   output String outStr;
// algorithm
//   "" := match (str) 
//     #cases#
//   end match;
//   outStr := "";
// end MatchCase16.fn;
// 
// class MatchCase16
//   constant String str = "";
// end MatchCase16;
// endResult
