// name: ComponentNames2
// keywords: component
// status: correct
//
// Tests whether or not a component can have the same name as the last ident of its type specifier
//

package P
  record R
    Real x;
  end R;
end P;    
    
model ComponentNames
  P.R R;
end ComponentNames;

// Result:
// class ComponentNames
//   Real R.x;
// end ComponentNames;
// [ComponentNames2.mo:15:3-15:8:writable] Warning: Component R has the same name as its type ComponentNames.P.R.
// 	This is forbidden by Modelica specifications and may lead to lookup errors.
// 
// endResult
