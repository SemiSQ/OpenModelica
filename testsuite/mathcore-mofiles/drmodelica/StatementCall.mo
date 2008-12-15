// name:     StatementCall
// keywords: multiple results, algorithm
// status:   correct
// 
// Computes cartesian coordinates of a point
//

function PointOnCircle 
  input Real angle "Angle in radians";
  input Real radius;
  output Real x; // 1:st result formal parameter
  output Real y; // 2:nd result formal parameter
algorithm
  x := radius*Modelica.Math.cos(angle);
  y := radius*Modelica.Math.sin(angle);
end PointOnCircle;

class StatementCall
  Real px, py;
algorithm
  (px, py) := PointOnCircle(1.2, 2);
end StatementCall;

// fclass StatementCall
// Real px;
// Real py;
// algorithm
//   (px, py) := PointOnCircle(1.2,2.0);
// end StatementCall;
