// name:     Enumeration6
// keywords: enumeration enum
// status:   correct
// 
// 
// 

package P

type EE = 
     enumeration(world "Resolve in world frame", 
                 frame_a "Resolve in frame_a", 
                 frame_resolve "Resolve in frame_resolve (frame_resolve must be connected)");

 type E = enumeration(a,b,c);
 
 model h
  // Types.Color axisColor_x=Types.FrameColor; 
  replaceable type E=enumeration(j, l, k);
  Real hh[E];  
 equation
  hh[E.j] = 1.0;
  hh[E.l] = 2.0;
  hh[E.k] = 3.0;
 end h;
   

end P;

model Enumeration6   
   
   P.h t; //(redeclare type E=enumeration(a1, b2, c1));
   import P.EE;
   import P.E;
   parameter EE frame_r_in = EE.frame_a;
   parameter EE frame_r_out = frame_r_in;
   Real x(stateSelect=StateSelect.default);
   Real[EE] z;
   EE ee(start = EE.world);
   E f(quantity="quant_str_enumeration",min = E.a,max = E.b,fixed = true,start = E.c);
equation
   x = if frame_r_out == EE.frame_a then 0.0 else 1.0;
   for e in EE loop
     z[e] = if frame_r_out <= EE.frame_a then 0.0 else 1.0;
   end for;
   ee = EE.frame_a;
   f = E.b;
end Enumeration6;

// Result:
// class Enumeration6
// Real t.hh[1];
// Real t.hh[2];
// Real t.hh[3];
// parameter enumeration(world, frame_a, frame_resolve) frame_r_in = EE.frame_a;
// parameter enumeration(world, frame_a, frame_resolve) frame_r_out = frame_r_in;
// Real x(StateSelect = StateSelect.default);
// Real z[1];
// Real z[2];
// Real z[3];
// enumeration(world, frame_a, frame_resolve) ee(start = EE.world);
// enumeration(a, b, c) f(quantity = "quant_str_enumeration", min = E.a, max = E.b, start = E.c, fixed = true);
// equation
//   t.hh[E.j] = 1.0;
//   t.hh[E.l] = 2.0;
//   t.hh[E.k] = 3.0;
//   x = if frame_r_out == EE.frame_a then 0.0 else 1.0;
//   z[1] = if frame_r_out <= EE.frame_a then 0.0 else 1.0;
//   z[2] = if frame_r_out <= EE.frame_a then 0.0 else 1.0;
//   z[3] = if frame_r_out <= EE.frame_a then 0.0 else 1.0;
//   ee = EE.frame_a;
//   f = E.b;
// end Enumeration6;
// endResult
