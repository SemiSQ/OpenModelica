within ThermoSysPro.WaterSolution.Machines;
model StaticCentrifugalPump "Water solution static centrifugal pump" 
  parameter ThermoSysPro.Units.RotationVelocity VRot=
                                                    1400 "Rotational speed";
  parameter ThermoSysPro.Units.RotationVelocity VRotn=
                                                     1400 
    "Nominal rotational speed";
  parameter Real rm=0.85 
    "Product of the pump mechanical and electrical efficiencies";
  parameter Boolean adiabatic_compression=false 
    "true: adiabatic compression - false: non adiabatic compression";
  parameter Modelica.SIunits.Density rho=1000 "Fluid density";
  
  parameter Real a1=-88.67 
    "x^2 coef. of the pump characteristics hn = f(vol_flow) (s2/m5)";
  parameter Real a2=0 
    "x coef. of the pump characteristics hn = f(vol_flow) (s/m2)";
  parameter Real a3=43.15 
    "Constant coef. of the pump characteristics hn = f(vol_flow) (m)";
  
  parameter Real b1=-3.7751 
    "x^2 coef. of the pump efficiency characteristics rh = f(vol_flow) (s2/m6)";
  parameter Real b2=3.61 
    "x coef. of the pump efficiency characteristics rh = f(vol_flow) (s/m3)";
  parameter Real b3=-0.0075464 
    "Constant coef. of the pump efficiency characteristics rh = f(vol_flow) (s.u.)";
  
protected 
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n 
    "Gravity constant";
  parameter Real eps=1.e-6 "Small number";
  parameter Real rhmin=0.05 "Minimum efficiency to avoid zero crossings";
  
public 
  Real rh "Hydraulic efficiency";
  Modelica.SIunits.Length hn(start=10) "Pump head";
  Real R "Ratio VRot/VRotn (s.u.)";
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow";
  Modelica.SIunits.VolumeFlowRate Qv(start=0.5) "Volumetric flow";
  Modelica.SIunits.Power Wh "Hydraulic power";
  Modelica.SIunits.Power Wm "Motor power";
  ThermoSysPro.Units.AbsolutePressure deltaP 
    "Pressure difference between the outlet and the inlet";
  ThermoSysPro.Units.SpecificEnthalpy h1 "Fluid specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy h2 
    "Fluid specific enthalpy at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy deltaH 
    "Specific enthalpy variation between the outlet and the inlet";
  annotation (
    Coordsys(
      extent=[-100, -100; 100, 100],
      grid=[2, 2],
      component=[20, 20]),
    Diagram(
      Ellipse(extent=[-100,100; 100,-100], style(
          gradient=0,
          fillColor=44,
          rgbfillColor={255,170,170},
          fillPattern=1)),
      Line(points=[-80,0; 80,0]),
      Line(points=[80,0; 2,60]),
      Line(points=[80,0; 0,-60])),
    Icon(
      Ellipse(extent=[-100,100; 100,-100], style(
          gradient=0,
          fillColor=44,
          rgbfillColor={255,170,170},
          fillPattern=1)),
      Line(points=[-80,0; 80,0]),
      Line(points=[80,0; 2,60]),
      Line(points=[80,0; 0,-60])),
    Window(
      x=0.09,
      y=0.2,
      width=0.66,
      height=0.69),
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
    Daniel Bouskela</li>
</html>
"));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionInlet C1 
    annotation (extent=[-110,-10; -90,10]);
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionOutlet C2 
    annotation (extent=[90,-10; 110,10]);
public 
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical commandePompe 
    annotation(extent=[-10,100; 10,120],  rotation=-90);
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal VRotation 
    annotation (extent=[-10,-120; 10,-100],
                                          rotation=90);
equation 
  if (cardinality(commandePompe) == 0) then
    commandePompe.signal = true;
  end if;
  
  if (cardinality(VRotation) == 0) then
    VRotation.signal = VRot;
  end if;
  
  deltaP = C2.P - C1.P;
  deltaH = h2 - h1;
  
  deltaP = rho*g*hn;
  
  if adiabatic_compression then
    deltaH = 0;
  else
    deltaH = g*hn/rh;
  end if;
  
  C1.Xh2o = C2.Xh2o;
  
  C1.Q = C2.Q;
  Q = C1.Q;
  Q = Qv*rho;
  
  /* Pump position (started or stopped) */
  R = if commandePompe.signal then VRotation.signal/VRotn else 0;
  
  /* Pump characteristics */
  hn = noEvent(a1*Qv*abs(Qv) + a2*Qv*R + a3*R^2);
  rh = noEvent(max(if (abs(R) > eps) then b1*Qv^2/R^2 + b2*Qv/R + b3 else b3, rhmin));
  
  /* Mechanical power */
  Wm = Q*deltaH/rm;
  
  /* Hydraulic power */
  Wh = Qv*deltaP/rh;
  
  /* Computation of the fluid specific enthalpy at the inlet and at the outlet */
  h1 = ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(C1.T, C1.Xh2o);
  h2 = ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(C2.T, C2.Xh2o);
  
end StaticCentrifugalPump;
