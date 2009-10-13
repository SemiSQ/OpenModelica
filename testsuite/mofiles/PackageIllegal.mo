// name: PackageIllegal
// keywords: package
// status: correct
//
// Tests to make sure that a package cannot have non-class components
// THIS TEST SHOULD FAIL
//

package IllegalPackage

class LegalClass
  Integer i;
end LegalClass;

Integer i;

equation
  i = 1;
end IllegalPackage;

model PackageIllegal
  IllegalPackage.LegalClass lc;
equation
  lc.i = 1;
end PackageIllegal;

// fclass PackageIllegal
// Integer lc.i;
// equation
//   lc.i = 1;
// end PackageIllegal;
