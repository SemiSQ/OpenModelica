// name:     Redeclare1
// keywords: redeclare,type
// status:   correct
// 
// Redeclaration and subtyping.
// 

model A
  Real x;
end A;

model B
  extends A;
  Real z;
end B;

model M
  replaceable A a(x=17);
end M;

model Redeclare1
  M m(redeclare B a);
equation
  m.a.z = m.a.x;
end Redeclare1;

//equation
// m.a.x =17;
// m.a.z = m.a.x;
