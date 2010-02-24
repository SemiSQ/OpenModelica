// name:     Constant11
// keywords: constant, package
// status:   correct
// 
// Constants in packages can lead to infinite recursion in lookup.
// In example below, the package A would be instantiated over and over again unless this is caught by
// investigating current scope. 

model Constant11
  function abc
    output Real r;
  algorithm
    r := def();
  end abc;

  function def
    output Real r;
  algorithm
    r := 1;
  end def;
  
  constant Real x = abc();
end Constant11;

// Result:
// fclass Constant11
// constant Real x = 1.0;
// end Constant11;
