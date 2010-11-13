// name:     PartialFn15
// keywords: PartialFn
// status:  correct
// cflags: +g=MetaModelica +d=noevalfunc
//
// Using lists of function pointers
//

package PartialFn15

function elabRealBinOps
  input Real r1;
  input Real r2;
  output list<Real> lst;
protected
  partial function RealBinOp
    input Real r1;
    input Real r2;
    output Real r;
  end RealBinOp;
  list<RealBinOp> binops;
  RealBinOp binop;
algorithm
  lst := {};
  binops := {realAdd,realSub,realMul,realDiv,realPow,realMax,realMin};
  while not listEmpty(binops) loop
    lst := match binops
      local
        Real r;
      case binop::binops
        equation
          r = binop(r1,r2);
        then r::lst;
    end match;
  end while;
  lst := listReverse(lst); // Easier to read the results this way...
end elabRealBinOps;

constant list<Real> rs = elabRealBinOps(8.0, 3.0);

end PartialFn15;
// Result:
// function PartialFn15.elabRealBinOps
//   input Real r1;
//   input Real r2;
//   output list<Real> lst;
//   protected list<function(r1:#Real, r2:#Real) => #Real> binops;
//   protected function(r1:#Real, r2:#Real) => #Real binop;
// algorithm
//   lst := List();
//   binops := List(realAdd,realSub,realMul,realDiv,realPow,realMax,realMin);
//   while  NOT listEmpty(binops) loop
//     lst := match (binops) 
//     #cases#
//   end match;
//   end while;
//   lst := listReverse(lst);
// end PartialFn15.elabRealBinOps;
// 
// class PartialFn15
//   constant list<Real> rs = List(11.0,5.0,24.0,2.66666666666667,512.0,8.0,3.0);
// end PartialFn15;
// endResult
