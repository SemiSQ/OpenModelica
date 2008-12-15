// name:     SimpleIntegrator3
// keywords: declaration,equation
// status:   incorrect
// 
// Cannot specify predefined attribute in an equation section,
// since parameters must be bound by modifiers.

model SimpleIntegrator3
  Real u = 1.0;
  Real x;
equation
  x.start = 2.0;
  der(x) = u;
end SimpleIntegrator3;

