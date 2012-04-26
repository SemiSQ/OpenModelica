within ThermoSysPro.WaterSteam.PressureLosses;
model NonBoilingValve "Non boiling valve" 
  parameter ThermoSysPro.Units.DifferentialPressure Psecu=1.e4 
    "Security margin to avoid boiling";
  parameter ThermoSysPro.Units.SpecificEnthalpy Hmax=5.e6 
    "Fluid maximum specific enthalpy";
  parameter ThermoSysPro.Units.SpecificEnthalpy Hmin=6.e4 
    "Fluid minimum specific enthalpy";
  parameter Boolean continuous_flow_reversal=false 
    "true: continuous flow reversal - false: discontinuous flow reversal";
  
protected 
  constant ThermoSysPro.Units.AbsolutePressure Pcrit=220.64e5 
    "Critical pressure";
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Modelica.SIunits.MassFlowRate Qeps=1.e-3 
    "Small mass flow for continuous flow reversal";
  
public 
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate";
  ThermoSysPro.Units.AbsolutePressure Pebul(start=1.e5) 
    "Fluid saturation pressure corresponding to Pec";
  ThermoSysPro.Units.AbsolutePressure Pec(start=5.e5) "Pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Psc(start=5.e5) "Pressure at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hec(start=50.e4) 
    "Specific fluid enthalpy at the inlet";
  
  annotation (
    Coordsys(
      extent=[-100, -100; 100, 100],
      grid=[2, 2],
      component=[20, 20]),
    Diagram(Polygon(points=[-100, -60; 0, 0; -100, 60; -100, -42; -100, -60],
          style(fillColor=53, fillPattern=1)), Polygon(points=[86, -52; 0, 0;
            100, 60; 100, -60; 86, -52], style(fillColor=53, fillPattern=1))),
    Icon(Polygon(points=[-90, -54; 0, 0; -100, 60; -100, -60; -90, -54], style(
            fillColor=53, fillPattern=1)), Polygon(points=[100, -60; 0, 0; 100,
             60; 100, -42; 100, -60], style(fillColor=53, fillPattern=1))),
    Window(
      x=0.09,
      y=0.08,
      width=0.81,
      height=0.85),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
public 
  Connectors.FluidInlet C1 
    annotation (extent=[-110, -12; -90, 8]);
  Connectors.FluidOutlet C2                annotation (extent=[90, -12; 110, 8]);
equation 
  
  Pec = C1.P;
  Psc = C2.P;
  Hec = C1.h;
  
  C1.h = C2.h;
  C1.Q = C2.Q;
  
  Q = C1.Q;
  
  if continuous_flow_reversal then
    0 = noEvent(if (Q > Qeps) then C1.h - C1.h_vol else if (Q < -Qeps) then 
      C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi
      *Q/2/Qeps) + C1.h_vol + C2.h_vol));
  else
    0 = if (Q > 0) then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;
  
  /* The pressure at the inlet is increased if it is not high enough to avoid boiling */
  if (Psc < Pcrit) then
    Pebul = ThermoSysPro.Properties.WaterSteam.IF97.Pressure_sat_hl(Hec);
    Pec = if ((Psc - Psecu) < Pebul) then Pebul + Psecu else Psc;
  else
    Pebul = Psc;
    Pec = Psc + Psecu;
  end if;
  
end NonBoilingValve;
