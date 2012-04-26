within ThermoSysPro.InstrumentationAndControl.Blocks.NonLineaire;
block Selecteur 
  parameter Real C1=-1 "Valeur de la sortie pour uCond=true si u1 non connect�";
  parameter Real C2=+1 
    "Valeur de la sortie pour uCond=false si u2 non connect�";
  annotation (
    Coordsys(
      extent=[-100, -100; 100, 100],
      grid=[2, 2],
      component=[20, 20]),
    Icon(
      Rectangle(extent=[-100, -100; 100, 100], style(
          color=3,
          pattern=1,
          thickness=1,
          arrow=0,
          fillPattern=0)),
      Line(points=[12, 0; 100, 0], style(
          color=0,
          pattern=1,
          thickness=1,
          arrow=0)),
      Line(points=[-100, 0; -40, 0], style(
          color=0,
          pattern=1,
          thickness=1,
          arrow=0)),
      Line(points=[-98, -80; -40, -80], style(
          color=0,
          pattern=1,
          thickness=1,
          arrow=0)),
      Line(points=[-40, 10; -40, -10], style(color=0)),
      Line(points=[-98, 80; -40, 80], style(color=0)),
      Line(points=[-40, 80; 10, 0], style(color=0)),
      Ellipse(extent=[2, 8; 18, -8], style(
          color=9,
          fillColor=9,
          fillPattern=1)),
      Text(extent=[-150, 150; 150, 110], string="%name"),
      Line(points=[-40, 70; -40, 80], style(color=0)),
      Line(points=[-40, 80; -30, 76], style(color=0)),
      Text(
        extent=[-100,80; -38,48],
        style(color=3, rgbcolor={0,0,255}),
        string="C1"),
      Text(
        extent=[-100,-48; -38,-80],
        style(color=3, rgbcolor={0,0,255}),
        string="C2")),
    Diagram(
      Rectangle(extent=[-100, -100; 100, 100], style(
          color=3,
          pattern=1,
          thickness=1,
          arrow=0,
          fillPattern=0)),
      Line(points=[12, 0; 100, 0], style(
          color=0,
          pattern=1,
          thickness=1,
          arrow=0)),
      Line(points=[-100, 0; -40, 0], style(
          color=0,
          pattern=1,
          thickness=1,
          arrow=0)),
      Line(points=[-98, -80; -40, -80], style(
          color=0,
          pattern=1,
          thickness=1,
          arrow=0)),
      Line(points=[-40, 10; -40, -10], style(color=0)),
      Line(points=[-98, 80; -40, 80], style(color=0)),
      Line(points=[-40, 80; 10, 0], style(color=0)),
      Ellipse(extent=[2, 8; 18, -8], style(
          color=9,
          fillColor=9,
          fillPattern=1)),
      Line(points=[-40, 70; -40, 80], style(color=0)),
      Line(points=[-40, 80; -30, 76], style(color=0)),
      Text(
        extent=[-102,78; -40,46],
        style(color=3, rgbcolor={0,0,255}),
        string="C1"),
      Text(
        extent=[-102,-50; -40,-82],
        style(color=3, rgbcolor={0,0,255}),
        string="C2")),
    Window(
      x=0.35,
      y=0.11,
      width=0.6,
      height=0.6),
    Documentation(info="<html>
<p><b>Version 1.6</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical uCond 
    annotation (extent=[-120, -10; -100, 10]);
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u1 
                                       annotation (extent=[-120, 70; -100, 90]);
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u2 
                                       annotation (extent=[-120, -90; -100, -70]);
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y 
                                       annotation (extent=[100, -10; 120, 10]);
equation 
  
  if (cardinality(u1) == 0) then
    u1.signal = C1;
  end if;
  
  if (cardinality(u2) == 0) then
    u2.signal = C2;
  end if;
  
  y.signal = if uCond.signal then u1.signal else u2.signal;
end Selecteur;
