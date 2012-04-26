within ThermoSysPro.WaterSteam.Volumes;
model DegasifierVolume "Degazifier volume" 
  parameter Modelica.SIunits.Volume V=160 "Degazifier volume";
  parameter Modelica.SIunits.Volume Vmax=10 
    "Maximum volume of the liquid in the basins";
  parameter Modelica.SIunits.SpecificHeatCapacity Cpmetal=460 
    "Metal specific heat";
  parameter Modelica.SIunits.Mass Mmetal=10869 "Metal mass";
  parameter ThermoSysPro.Units.AbsolutePressure P0=1e5 
    "Initial fluid pressure (active if steady_state=false)";
  parameter ThermoSysPro.Units.SpecificEnthalpy h0=1e5 
    "Initial fluid specific enthalpy (active if steady_state=false)";
  parameter Boolean steady_state=true 
    "true: start from steady state - false: start from (P0, h0)";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 
    "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  
public 
  Modelica.SIunits.Power W 
    "Thermal power exchanged between the liquid and the basins";
  ThermoSysPro.Units.AbsoluteTemperature Tl 
    "Saturation temperature of the liquid in the basins";
  Real x "Vapor mass fraction";
  ThermoSysPro.Units.AbsolutePressure P(start=1.e5) "Average fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  Modelica.SIunits.MassFlowRate BQ 
    "Right hand side of the mass balance equation";
  Modelica.SIunits.Power BH "Right hand side of the energy balance equation";
  Real rhols;
  
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro 
    "Propri�t�s de l'eau" 
    annotation (extent=[-100,80; -80,100]);
  annotation (
    Coordsys(
      extent=[-100, -100; 100, 100],
      grid=[2, 2],
      component=[20, 20]),
    Diagram(Ellipse(extent=[-102,60; 100,-60], style(
          pattern=0,
          fillColor=71,
          rgbfillColor={85,170,255}))),
    Icon(   Ellipse(extent=[-102,60; 100,-60], style(
          color=3,
          rgbcolor={0,0,255},
          fillColor=71,
          rgbfillColor={85,170,255}))),
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
    Baligh El Hefni</li>
</ul>
</html>
"));
public 
  Connectors.FluidInlet Ce1 
                           annotation (extent=[-110,-10; -90,10]);
  Connectors.FluidInlet Ce2 
                           annotation (extent=[-50,50; -30,70]);
  Connectors.FluidOutlet Cs 
                          annotation (extent=[-50,-70; -30,-50]);
  Connectors.FluidInlet Ce3 
                           annotation (extent=[30,50; 50,70]);
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat 
    annotation (extent=[-60,80; -40,100]);
  Connectors.FluidInlet Ce4 
                           annotation (extent=[30,-68; 50,-48]);
initial equation 
  if steady_state then
    der(P) = 0;
    der(h) = 0;
  else
    P = P0;
    h = h0;
  end if;
  
equation 
  assert(V > 0, "Volume non strictement positif");
  
  /* Unconnected connectors */
  if (cardinality(Ce1) == 0) then
    Ce1.Q = 0;
    Ce1.h = 1.e5;
    Ce1.b = true;
  end if;
  
  if (cardinality(Ce2) == 0) then
    Ce2.Q = 0;
    Ce2.h = 1.e5;
    Ce2.b = true;
  end if;
  
  if (cardinality(Ce3) == 0) then
    Ce3.Q = 0;
    Ce3.h = 1.e5;
    Ce3.b = true;
  end if;
  
  if (cardinality(Ce4) == 0) then
    Ce4.Q = 0;
    Ce4.h = 1.e5;
    Ce4.b = true;
  end if;
  
  if (cardinality(Cs) == 0) then
    Cs.Q = 0;
    Cs.h = 1.e5;
    Cs.a = true;
  end if;
  
  P = Ce1.P;
  P = Ce2.P;
  P = Ce3.P;
  P = Ce4.P;
  P = Cs.P;
  
  /* Mass balance equation */
  BQ = Ce1.Q + Ce2.Q + Ce3.Q + Ce4.Q - Cs.Q;
  V*(pro.ddph*der(P) + pro.ddhp*der(h)) = BQ;
  
  /* Energy balance equation */
  BH = Ce1.Q*Ce1.h + Ce2.Q*Ce2.h + Ce3.Q*Ce3.h + Ce4.Q*Ce4.h - Cs.Q*Cs.h - W;
  V*((h*pro.ddph - 1)*der(P) + (h*pro.ddhp + rho)*der(h)) = BH;
  
  Ce1.h_vol = h;
  Ce2.h_vol = h;
  Ce3.h_vol = h;
  Ce4.h_vol = h;
  Cs.h_vol = h;
  
  /* Thermal power exchanged between the basins wall and the liquid */
  W = Mmetal*Cpmetal*der(P)/lsat.pt;
  
  /* Fluid thermodynamic properties */
  pro = ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, h, mode);
  x=pro.x;
  
  if (p_rho > 0) then
    rho = p_rho;
  else
    rho = pro.d;
  end if;
  
  (lsat) = ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(P);
  
  rhols = lsat.rho;
  Tl = lsat.T;
  
end DegasifierVolume;
