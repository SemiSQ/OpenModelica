within Modelica.Blocks;
package Sources "Signal source blocks generating Real and Boolean signals"
  block RealExpression "Set output signal to a time varying Real expression"
    annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html>

</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={210,210,210}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, lineThickness=4, borderPattern=BorderPattern.Raised, extent={{-100,-40},{100,40}}),Text(visible=true, extent={{-96,-15},{96,15}}, textString="%y", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,50},{140,90}}, textString="%name", fontName="Arial")}));
    Blocks.Interfaces.RealOutput y=0.0 "Value of Real output" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
  end RealExpression;

  block IntegerExpression "Set output signal to a time varying Integer expression"
    annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html>

</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={210,210,210}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, lineThickness=4, borderPattern=BorderPattern.Raised, extent={{-100,-40},{100,40}}),Text(visible=true, extent={{-96,-15},{96,15}}, textString="%y", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,50},{140,90}}, textString="%name", fontName="Arial")}));
    Blocks.Interfaces.IntegerOutput y=0 "Value of Integer output" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
  end IntegerExpression;

  block BooleanExpression "Set output signal to a time varying Boolean expression"
    annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="<html>

</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={210,210,210}, pattern=LinePattern.None, fillPattern=FillPattern.Solid, lineThickness=4, borderPattern=BorderPattern.Raised, extent={{-100,-40},{100,40}}),Text(visible=true, extent={{-96,-15},{96,15}}, textString="%y", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,50},{140,90}}, textString="%name", fontName="Arial"),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{100,10},{120,0},{100,-10},{100,10}})}));
    Blocks.Interfaces.BooleanOutput y=false "Value of Boolean output" annotation(Placement(visible=true, transformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={110,0}, extent={{-10,-10},{10,10}}, rotation=0)));
  end BooleanExpression;

  import Modelica.Blocks.Interfaces;
  import Modelica.SIunits;
  extends Modelica.Icons.Library;
  annotation(preferedView="info", Documentation(info="<HTML>
<p>
This package contains <b>source</b> components, i.e., blocks which
have only output signals. These blocks are used as signal generators
for Real, Integer and Boolean signals.
</p>

<p>
All Real source signals (with the exception of the Constant source)
have at least the following two parameters:
</p>

<table border=1 cellspacing=0 cellpadding=2>
  <tr><td><b>offset</b></td>
      <td>Value which is added to the signal</td>
  </tr>
  <tr><td><b>startTime</b></td>
      <td>Start time of signal. For time &lt; startTime,
                the output y is set to offset.</td>
  </tr>
</table>

<p>
The <b>offset</b> parameter is especially useful in order to shift
the corresponding source, such that at initial time the system
is stationary. To determine the corresponding value of offset,
usually requires a trimming calculation.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Integer sources added. Step, TimeTable and BooleanStep slightly changed.</li>
<li><i>Nov. 8, 1999</i>
       by <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
       <A HREF=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</A>,
       <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       New sources: Exponentials, TimeTable. Trapezoid slightly enhanced
       (nperiod=-1 is an infinite number of periods).</li>
<li><i>Oct. 31, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
       <A HREF=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</A>,
       All sources vectorized. New sources: ExpSine, Trapezoid,
       BooleanConstant, BooleanStep, BooleanPulse, SampleTrigger.
       Improved documentation, especially detailed description of
       signals in diagram layer.</li>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{0,0},{430,-442}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  block Clock "Generate actual time signal "
    parameter Real offset=0 "Offset of output signal";
    parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
    extends Interfaces.SO;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={160,160,160}, extent={{-80,-80},{80,80}}),Line(visible=true, points={{0,80},{0,60}}, color={160,160,160}),Line(visible=true, points={{80,0},{60,0}}, color={160,160,160}),Line(visible=true, points={{0,-80},{0,-60}}, color={160,160,160}),Line(visible=true, points={{-80,0},{-60,0}}, color={160,160,160}),Line(visible=true, points={{37,70},{26,50}}, color={160,160,160}),Line(visible=true, points={{70,38},{49,26}}, color={160,160,160}),Line(visible=true, points={{71,-37},{52,-27}}, color={160,160,160}),Line(visible=true, points={{39,-70},{29,-51}}, color={160,160,160}),Line(visible=true, points={{-39,-70},{-29,-52}}, color={160,160,160}),Line(visible=true, points={{-71,-37},{-50,-26}}, color={160,160,160}),Line(visible=true, points={{-71,37},{-54,28}}, color={160,160,160}),Line(visible=true, points={{-38,70},{-28,51}}, color={160,160,160}),Line(visible=true, points={{0,0},{-50,50}}, thickness=0.5),Line(visible=true, points={{0,0},{40,0}}, thickness=0.5),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="startTime=%startTime", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-80,0},{-10,0},{60,70}}, thickness=0.5),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,0},{-37,-13},{-30,-13},{-34,0}}),Line(visible=true, points={{-34,-13},{-34,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,-69},{-37,-56},{-31,-56},{-34,-69},{-34,-69}}),Text(visible=true, fillColor={160,160,160}, extent={{-81,-43},{-35,-25}}, textString="offset", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-33,-89},{13,-71}}, textString="startTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-66,72},{-25,92}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Line(visible=true, points={{-10,0},{-10,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-10,0},{50,0}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{50,0},{50,60}}, color={192,192,192}, pattern=LinePattern.Dash),Text(visible=true, fillColor={160,160,160}, extent={{35,23},{50,33}}, textString="1", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{14,1},{32,13}}, textString="1", fontName="Arial")}), Documentation(info="<html>

</html>"));
  equation 
    y=offset + (if time < startTime then 0 else time - startTime);
  end Clock;

  block Constant "Generate constant signal of type Real"
    parameter Real k=1 "Constant output value";
    extends Interfaces.SO;
    annotation(defaultComponentName="const", Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Line(visible=true, points={{-80,0},{80,0}}),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="k=%k", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-80,0},{80,0}}, thickness=0.5),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Text(visible=true, fillColor={160,160,160}, extent={{-75,76},{-22,94}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-101,-12},{-81,8}}, textString="k", fontName="Arial")}), Documentation(info="<html>

</html>"));
  equation 
    y=k;
  end Constant;

  block Step "Generate step signal of type Real"
    parameter Real height=1 "Height of step";
    extends Interfaces.SignalSource;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Line(visible=true, points={{-80,-70},{0,-70},{0,50},{80,50}}),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="startTime=%startTime", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-80,-18},{0,-18},{0,50},{80,50}}, thickness=0.5),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-21,-90},{25,-72}}, textString="startTime", fontName="Arial"),Line(visible=true, points={{0,-17},{0,-71}}, color={192,192,192}, pattern=LinePattern.Dash),Text(visible=true, fillColor={160,160,160}, extent={{-68,-54},{-22,-36}}, textString="offset", fontName="Arial"),Line(visible=true, points={{-13,50},{-13,-17}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, pattern=LinePattern.Dash, points={{2,50},{-19,50},{2,50}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-13,-17},{-16,-4},{-10,-4},{-13,-17},{-13,-17}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-13,50},{-16,37},{-9,37},{-13,50}}),Text(visible=true, fillColor={160,160,160}, extent={{-68,8},{-22,26}}, textString="height", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-13,-69},{-16,-56},{-10,-56},{-13,-69},{-13,-69}}),Line(visible=true, points={{-13,-18},{-13,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-13,-18},{-16,-31},{-9,-31},{-13,-18}}),Text(visible=true, fillColor={160,160,160}, extent={{-72,80},{-31,100}}, textString="y", fontName="Arial")}), Documentation(info="<html>

</html>"));
  equation 
    y=offset + (if time < startTime then 0 else height);
  end Step;

  block Ramp "Generate ramp signal"
    parameter Real height=1 "Height of ramps";
    parameter Real duration(min=Modelica.Constants.small)=2 "Durations of ramp";
    parameter Real offset=0 "Offset of output signal";
    parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
    extends Interfaces.SO;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Line(visible=true, points={{-80,-70},{-40,-70},{31,38}}),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="duration=%duration", fontName="Arial"),Line(visible=true, points={{31,38},{86,38}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-80,-20},{-20,-20},{50,50}}, thickness=0.5),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-40,-20},{-42,-30},{-37,-30},{-40,-20}}),Line(visible=true, points={{-40,-20},{-40,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-40,-70},{-43,-60},{-38,-60},{-40,-70},{-40,-70}}),Text(visible=true, fillColor={160,160,160}, extent={{-80,-49},{-41,-33}}, textString="offset", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-40,-88},{6,-70}}, textString="startTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-66,72},{-25,92}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Line(visible=true, points={{-20,-20},{-20,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-19,-20},{50,-20}}, color={192,192,192}),Line(visible=true, points={{50,50},{101,50}}, thickness=0.5),Line(visible=true, points={{50,50},{50,-20}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,-20},{42,-18},{42,-22},{50,-20}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-20,-20},{-11,-18},{-11,-22},{-20,-20}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,50},{48,40},{53,40},{50,50}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,-20},{47,-10},{52,-10},{50,-20},{50,-20}}),Text(visible=true, fillColor={160,160,160}, extent={{53,7},{82,25}}, textString="height", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{0,-37},{35,-17}}, textString="duration", fontName="Arial")}), Documentation(info="<html>

</html>"));
  equation 
    y=offset + (if time < startTime then 0 else if time < startTime + duration then (time - startTime)*height/duration else height);
  end Ramp;

  block Sine "Generate sine signal"
    parameter Real amplitude=1 "Amplitude of sine wave";
    parameter SIunits.Frequency freqHz=1 "Frequency of sine wave";
    parameter SIunits.Angle phase=0 "Phase of sine wave";
    parameter Real offset=0 "Offset of output signal";
    parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
    extends Interfaces.SO;
    annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,-90},{-80,84}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,100},{-86,84},{-74,84},{-80,100}}),Line(visible=true, points={{-99,-40},{85,-40}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{101,-40},{85,-34},{85,-46},{101,-40}}),Line(visible=true, points={{-40,0},{-31.6,34.2},{-26.1,53.1},{-21.3,66.4},{-17.1,74.6},{-12.9,79.1},{-8.64,79.8},{-4.42,76.6},{-0.2,69.7},{4.02,59.4},{8.84,44.1},{14.9,21.2},{27.5,-30.8},{33,-50.2},{37.8,-64.2},{42,-73.1},{46.2,-78.4},{50.5,-80},{54.7,-77.6},{58.9,-71.5},{63.1,-61.9},{67.9,-47.2},{74,-24.8},{80,0}}, thickness=0.5, smooth=Smooth.Bezier),Line(visible=true, points={{-41,-2},{-80,-2}}, thickness=0.5),Text(visible=true, fillColor={160,160,160}, extent={{-128,-11},{-82,7}}, textString="offset", fontName="Arial"),Line(visible=true, points={{-41,-2},{-41,-40}}, color={192,192,192}, pattern=LinePattern.Dot),Text(visible=true, fillColor={160,160,160}, extent={{-60,-61},{-14,-43}}, textString="startTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{84,-72},{108,-52}}, textString="time", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-74,86},{-33,106}}, textString="y", fontName="Arial"),Line(visible=true, points={{-9,79},{43,79}}, color={192,192,192}, pattern=LinePattern.Dot),Line(visible=true, points={{-42,-1},{50,0}}, color={192,192,192}, pattern=LinePattern.Dot),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{33,80},{30,67},{37,67},{33,80}}),Text(visible=true, fillColor={160,160,160}, extent={{37,39},{83,57}}, textString="amplitude", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{33,1},{30,14},{36,14},{33,1},{33,1}}),Line(visible=true, points={{33,79},{33,0}}, color={192,192,192})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-147,-152},{153,-112}}, textString="freqHz=%freqHz", fontName="Arial")}));
  protected 
    constant Real pi=Modelica.Constants.pi;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-90,0},{68,0}}, color={192,192,192}),Polygon(points={{90,0},{68,8},{68,-8},{90,0}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, color={0,0,0}),Text(extent={{-147,-152},{153,-112}}, textString="freqHz=%freqHz", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,-90},{-80,84}}, color={192,192,192}),Polygon(points={{-80,100},{-86,84},{-74,84},{-80,100}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-99,-40},{85,-40}}, color={192,192,192}),Polygon(points={{101,-40},{85,-34},{85,-46},{101,-40}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-40,0},{-31.6,34.2},{-26.1,53.1},{-21.3,66.4},{-17.1,74.6},{-12.9,79.1},{-8.64,79.8},{-4.42,76.6},{-0.201,69.7},{4.02,59.4},{8.84,44.1},{14.9,21.2},{27.5,-30.8},{33,-50.2},{37.8,-64.2},{42,-73.1},{46.2,-78.4},{50.5,-80},{54.7,-77.6},{58.9,-71.5},{63.1,-61.9},{67.9,-47.2},{74,-24.8},{80,0}}, color={0,0,0}, thickness=0.5),Line(points={{-41,-2},{-80,-2}}, color={0,0,0}, thickness=0.5),Text(extent={{-128,7},{-82,-11}}, textString="offset", fillColor={160,160,160}),Line(points={{-41,-2},{-41,-40}}, color={192,192,192}, pattern=LinePattern.Dash),Text(extent={{-60,-43},{-14,-61}}, textString="startTime", fillColor={160,160,160}),Text(extent={{84,-52},{108,-72}}, textString="time", fillColor={160,160,160}),Text(extent={{-74,106},{-33,86}}, textString="y", fillColor={160,160,160}),Line(points={{-9,79},{43,79}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-42,-1},{50,0}}, color={192,192,192}, pattern=LinePattern.Dash),Polygon(points={{33,80},{30,67},{37,67},{33,80}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(extent={{37,57},{83,39}}, textString="amplitude", fillColor={160,160,160}),Polygon(points={{33,1},{30,14},{36,14},{33,1},{33,1}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{33,79},{33,0}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None})}), Documentation(info="<html>

</html>"));
  equation 
    y=offset + (if time < startTime then 0 else amplitude*Modelica.Math.sin(2*pi*freqHz*(time - startTime) + phase));
  end Sine;

  block ExpSine "Generate exponentially damped sine signal"
    parameter Real amplitude=1 "Amplitude of sine wave";
    parameter SIunits.Frequency freqHz=2 "Frequency of sine wave";
    parameter SIunits.Angle phase=0 "Phase of sine wave";
    parameter SIunits.Damping damping=1 "Damping coefficient of sine wave";
    parameter Real offset=0 "Offset of output signal";
    parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
    extends Interfaces.SO;
    annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,-90},{-80,84}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,100},{-86,84},{-74,84},{-80,100}}),Line(visible=true, points={{-99,-40},{85,-40}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{101,-40},{85,-34},{85,-46},{101,-40}}),Line(visible=true, points={{-50,0},{-46.1,28.2},{-43.5,44},{-40.9,56.4},{-38.2,64.9},{-35.6,69.4},{-33,69.6},{-30.4,65.9},{-27.8,58.7},{-24.5,45.7},{-19.9,22.5},{-13.4,-12.2},{-9.5,-29.5},{-6.23,-40.1},{-2.96,-46.5},{0.3,-48.4},{3.57,-45.9},{6.83,-39.6},{10.8,-28.1},{21.9,12},{25.8,23.1},{29.7,30.5},{33,33.3},{36.9,32.5},{40.8,27.8},{46,16.9},{56.5,-9.2},{61.7,-18.6},{66.3,-22.7},{70.9,-22.6},{76.1,-18},{80,-12.1}}, thickness=0.5, smooth=Smooth.Bezier),Text(visible=true, fillColor={160,160,160}, extent={{-106,-10},{-83,10}}, textString="offset", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-72,-54},{-26,-36}}, textString="startTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{84,-72},{108,-52}}, textString="time", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-79,87},{-39,104}}, textString="y", fontName="Arial"),Line(visible=true, points={{-50,0},{18,0}}, color={192,192,192}, pattern=LinePattern.Dot),Line(visible=true, points={{-50,0},{-81,0}}, thickness=0.5),Line(visible=true, points={{-50,77},{-50,0}}, color={192,192,192}, pattern=LinePattern.Dot),Line(visible=true, points={{18,-1},{18,76}}, color={192,192,192}, pattern=LinePattern.Dot),Line(visible=true, points={{18,73},{-50,73}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{-42,74},{9,88}}, textString="1/freqHz", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-49,73},{-40,75},{-40,71},{-49,73}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{18,73},{10,75},{10,71},{18,73}}),Line(visible=true, points={{-50,-61},{-19,-61}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-18,-61},{-26,-59},{-26,-63},{-18,-61}}),Text(visible=true, fillColor={160,160,160}, extent={{-51,-75},{-27,-63}}, textString="t", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-82,-96},{108,-67}}, textString="amplitude*exp(-damping*t)*sin(2*pi*freqHz*t+phase)", fontName="Arial"),Line(visible=true, points={{-50,0},{-50,-40}}, color={192,192,192}, pattern=LinePattern.Dot),Line(visible=true, points={{-50,-54},{-50,-72}}, color={192,192,192}, pattern=LinePattern.Dot),Line(visible=true, points={{-15,-77},{-1,-48}}, color={192,192,192}, pattern=LinePattern.Dot)}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,0},{-75.2,32.3},{-72,50.3},{-68.7,64.5},{-65.5,74.2},{-62.3,79.3},{-59.1,79.6},{-55.9,75.3},{-52.7,67.1},{-48.6,52.2},{-43,25.8},{-35,-13.9},{-30.2,-33.7},{-26.1,-45.9},{-22.1,-53.2},{-18.1,-55.3},{-14.1,-52.5},{-10.1,-45.3},{-5.23,-32.1},{8.44,13.7},{13.3,26.4},{18.1,34.8},{22.1,38},{26.9,37.2},{31.8,31.8},{38.2,19.4},{51.1,-10.5},{57.5,-21.2},{63.1,-25.9},{68.7,-25.9},{75.2,-20.5},{80,-13.8}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-147,-152},{153,-112}}, textString="freqHz=%freqHz", fontName="Arial")}));
  protected 
    constant Real pi=Modelica.Constants.pi;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-90,0},{68,0}}, color={192,192,192}),Polygon(points={{90,0},{68,8},{68,-8},{90,0}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,0},{-75.2,32.3},{-72,50.3},{-68.7,64.5},{-65.5,74.2},{-62.3,79.3},{-59.1,79.6},{-55.9,75.3},{-52.7,67.1},{-48.6,52.2},{-43,25.8},{-35,-13.9},{-30.2,-33.7},{-26.1,-45.9},{-22.1,-53.2},{-18.1,-55.3},{-14.1,-52.5},{-10.1,-45.3},{-5.23,-32.1},{8.44,13.7},{13.3,26.4},{18.1,34.8},{22.1,38},{26.9,37.2},{31.8,31.8},{38.2,19.4},{51.1,-10.5},{57.5,-21.2},{63.1,-25.9},{68.7,-25.9},{75.2,-20.5},{80,-13.8}}, color={0,0,0}),Text(extent={{-147,-152},{153,-112}}, textString="freqHz=%freqHz", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,-90},{-80,84}}, color={192,192,192}),Polygon(points={{-80,100},{-86,84},{-74,84},{-80,100}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-99,-40},{85,-40}}, color={192,192,192}),Polygon(points={{101,-40},{85,-34},{85,-46},{101,-40}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-50,0},{-46.1,28.2},{-43.5,44},{-40.9,56.4},{-38.2,64.9},{-35.6,69.4},{-33,69.6},{-30.4,65.9},{-27.8,58.7},{-24.5,45.7},{-19.9,22.5},{-13.4,-12.2},{-9.5,-29.5},{-6.23,-40.1},{-2.96,-46.5},{0.302,-48.4},{3.57,-45.9},{6.83,-39.6},{10.8,-28.1},{21.9,12},{25.8,23.1},{29.7,30.5},{33,33.3},{36.9,32.5},{40.8,27.8},{46,16.9},{56.5,-9.2},{61.7,-18.6},{66.3,-22.7},{70.9,-22.6},{76.1,-18},{80,-12.1}}, color={0,0,0}, thickness=0.5),Text(extent={{-106,10},{-83,-10}}, textString="offset", fillColor={160,160,160}),Text(extent={{-72,-36},{-26,-54}}, textString="startTime", fillColor={160,160,160}),Text(extent={{84,-52},{108,-72}}, textString="time", fillColor={160,160,160}),Text(extent={{-79,104},{-39,87}}, textString="y", fillColor={160,160,160}),Line(points={{-50,0},{18,0}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-50,0},{-81,0}}, color={0,0,0}, thickness=0.5),Line(points={{-50,77},{-50,0}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{18,-1},{18,76}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{18,73},{-50,73}}, color={192,192,192}),Text(extent={{-42,88},{9,74}}, textString="1/freqHz", fillColor={160,160,160}),Polygon(points={{-49,73},{-40,75},{-40,71},{-49,73}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{18,73},{10,75},{10,71},{18,73}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-50,-61},{-19,-61}}, color={192,192,192}),Polygon(points={{-18,-61},{-26,-59},{-26,-63},{-18,-61}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(extent={{-51,-63},{-27,-75}}, textString="t", fillColor={160,160,160}),Text(extent={{-82,-67},{108,-96}}, textString="amplitude*exp(-damping*t)*sin(2*pi*freqHz*t+phase)", fillColor={160,160,160}),Line(points={{-50,0},{-50,-40}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-50,-54},{-50,-72}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-15,-77},{-1,-48}}, color={192,192,192}, pattern=LinePattern.Dash)}), Documentation(info="<html>

</html>"));
  equation 
    y=offset + (if time < startTime then 0 else amplitude*Modelica.Math.exp(-(time - startTime)*damping)*Modelica.Math.sin(2*pi*freqHz*(time - startTime) + phase));
  end ExpSine;

  model Exponentials "Generate a rising and falling exponential signal"
    parameter Real outMax=1 "Height of output for infinite riseTime";
    parameter SIunits.Time riseTime(min=0)=0.5 "Rise time";
    parameter SIunits.Time riseTimeConst(min=Modelica.Constants.small)=0.1 "Rise time constant";
    parameter SIunits.Time fallTimeConst(min=Modelica.Constants.small)=riseTimeConst "Fall time constant";
    parameter Real offset=0 "Offset of output signal";
    parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
    extends Interfaces.SO;
    annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,-70},{84,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,-70},{84,-64},{84,-76},{100,-70}}),Line(visible=true, points={{-40,-30},{-37.2,-15.3},{-34.3,-2.1},{-30.8,12.4},{-27.3,25},{-23.7,35.92},{-19.5,47.18},{-15.3,56.7},{-10.3,66},{-4.6,74.5},{1.7,82.1},{8.8,88.6},{17.3,94.3},{30,100},{30,100},{32.12,87.5},{34.95,72.7},{37.78,59.8},{40.61,48.45},{44.14,36.3},{47.68,26},{51.9,15.8},{56.2,7.4},{61.1,-0.5},{66.8,-7.4},{73.1,-13.3},{80.9,-18.5},{90.8,-22.8},{100,-25.4}}, thickness=0.5, smooth=Smooth.Bezier),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{-70,71},{-29,91}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-78,-56},{-46,-43}}, textString="offset", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-40,-70},{-43,-60},{-38,-60},{-40,-70},{-40,-70}}),Line(visible=true, points={{-40,-29},{-40,-60}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-40,-30},{-42,-40},{-37,-40},{-40,-30}}),Line(visible=true, points={{-39,-30},{-80,-30}}, thickness=0.5),Text(visible=true, fillColor={160,160,160}, extent={{-59,-89},{-13,-71}}, textString="startTime", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-41,-30},{-32,-28},{-32,-32},{-41,-30}}),Line(visible=true, points={{-40,-30},{29,-30}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{29,-30},{21,-28},{21,-32},{29,-30}}),Text(visible=true, fillColor={160,160,160}, extent={{-26,-28},{19,-12}}, textString="riseTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{78,-96},{102,-76}}, textString="time", fontName="Arial"),Line(visible=true, points={{30,100},{30,-34}}, color={192,192,192}, pattern=LinePattern.Dot)}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,-70},{68,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Line(visible=true, points={{-80,-70},{-77.2,-55.3},{-74.3,-42.1},{-70.8,-27.6},{-67.3,-15},{-63.7,-4.08},{-59.5,7.18},{-55.3,16.7},{-50.3,26},{-44.6,34.5},{-38.3,42.1},{-31.2,48.6},{-22.7,54.3},{-10,60},{-10,60},{-7.88,47.5},{-5.05,32.7},{-2.22,19.8},{0.61,8.45},{4.14,-3.7},{7.68,-14},{11.9,-24.2},{16.2,-32.6},{21.1,-40.5},{26.8,-47.4},{33.1,-53.3},{40.9,-58.5},{50.8,-62.8},{60,-65.4}}, smooth=Smooth.Bezier),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="riseTime=%riseTime", fontName="Arial")}));
  protected 
    Real y_riseTime;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-90,-70},{68,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,-70},{-77.2,-55.3},{-74.3,-42.1},{-70.8,-27.6},{-67.3,-15},{-63.7,-4.08},{-59.5,7.18},{-55.3,16.7},{-50.3,26},{-44.6,34.5},{-38.3,42.1},{-31.2,48.6},{-22.7,54.3},{-12.1,59.2},{-10,60},{-7.88,47.5},{-5.05,32.7},{-2.22,19.8},{0.606,8.45},{4.14,-3.7},{7.68,-14},{11.9,-24.2},{16.2,-32.6},{21.1,-40.5},{26.8,-47.4},{33.1,-53.3},{40.9,-58.5},{50.8,-62.8},{60,-65.4}}, color={0,0,0}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Text(extent={{-150,-150},{150,-110}}, textString="riseTime=%riseTime", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-100,-70},{84,-70}}, color={192,192,192}),Polygon(points={{100,-70},{84,-64},{84,-76},{100,-70}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-40,-30},{-37.2,-15.3},{-34.3,-2.1},{-30.8,12.4},{-27.3,25},{-23.7,35.92},{-19.5,47.18},{-15.3,56.7},{-10.3,66},{-4.6,74.5},{1.7,82.1},{8.8,88.6},{17.3,94.3},{27.9,99.2},{30,100},{32.12,87.5},{34.95,72.7},{37.78,59.8},{40.606,48.45},{44.14,36.3},{47.68,26},{51.9,15.8},{56.2,7.4},{61.1,-0.5},{66.8,-7.4},{73.1,-13.3},{80.9,-18.5},{90.8,-22.8},{100,-25.4}}, color={0,0,0}, thickness=0.5),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Text(extent={{-70,91},{-29,71}}, textString="y", fillColor={160,160,160}),Text(extent={{-78,-43},{-46,-56}}, textString="offset", fillColor={160,160,160}),Polygon(points={{-40,-70},{-43,-60},{-38,-60},{-40,-70},{-40,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-40,-29},{-40,-60}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Polygon(points={{-40,-30},{-42,-40},{-37,-40},{-40,-30}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-39,-30},{-80,-30}}, color={0,0,0}, thickness=0.5),Text(extent={{-59,-71},{-13,-89}}, textString="startTime", fillColor={160,160,160}),Polygon(points={{-41,-30},{-32,-28},{-32,-32},{-41,-30}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-40,-30},{29,-30}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Polygon(points={{29,-30},{21,-28},{21,-32},{29,-30}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(extent={{-26,-12},{19,-28}}, textString="riseTime", fillColor={160,160,160}),Text(extent={{78,-76},{102,-96}}, textString="time", fillColor={160,160,160}),Line(points={{30,100},{30,-34}}, color={192,192,192}, pattern=LinePattern.Dash)}), Documentation(info="<html>

</html>"));
  equation 
    y_riseTime=outMax*(1 - Modelica.Math.exp(-riseTime/riseTimeConst));
    y=offset + (if time < startTime then 0 else if time < startTime + riseTime then outMax*(1 - Modelica.Math.exp(-(time - startTime)/riseTimeConst)) else y_riseTime*Modelica.Math.exp(-(time - startTime - riseTime)/fallTimeConst));
  end Exponentials;

  block Pulse "Generate pulse signal of type Real"
    parameter Real amplitude=1 "Amplitude of pulse";
    parameter Real width(final min=Modelica.Constants.small, final max=100)=50 "Width of pulse in % of periods";
    parameter Modelica.SIunits.Time period(final min=Modelica.Constants.small)=1 "Time for one period";
    parameter Real offset=0 "Offset of output signals";
    parameter Modelica.SIunits.Time startTime=0 "Output = offset for time < startTime";
    extends Modelica.Blocks.Interfaces.SO;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Line(visible=true, points={{-80,-70},{-40,-70},{-40,44},{0,44},{0,-70},{40,-70},{40,44},{79,44}}),Text(visible=true, extent={{-147,-152},{153,-112}}, textString="period=%period", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,1},{-37,-12},{-30,-12},{-34,1}}),Line(visible=true, points={{-34,-1},{-34,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-33,-70},{-36,-57},{-30,-57},{-33,-70},{-33,-70}}),Text(visible=true, fillColor={160,160,160}, extent={{-78,-36},{-35,-24}}, textString="offset", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-31,-87},{15,-69}}, textString="startTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-76,79},{-35,99}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Line(visible=true, points={{-10,0},{-10,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-80,0},{-10,0},{-10,50},{30,50},{30,0},{50,0},{50,50},{90,50}}, thickness=0.5),Line(visible=true, points={{-10,88},{-10,49}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{30,74},{30,50}}, color={160,160,160}, pattern=LinePattern.Dash),Line(visible=true, points={{50,88},{50,50}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-10,83},{51,83}}, color={192,192,192}),Line(visible=true, points={{-10,69},{30,69}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{0,85},{46,97}}, textString="period", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-9,69},{30,81}}, textString="width", fontName="Arial"),Line(visible=true, points={{-43,50},{-10,50}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-34,50},{-34,1}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{-78,20},{-37,34}}, textString="amplitude", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,49},{-37,36},{-30,36},{-34,49}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,1},{-37,14},{-31,14},{-34,1},{-34,1}}),Line(visible=true, points={{90,50},{90,0},{100,0}}, thickness=0.5),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-10,69},{-1,71},{-1,67},{-10,69}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{30,69},{22,71},{22,67},{30,69}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-10,83},{-1,85},{-1,81},{-10,83}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,83},{42,85},{42,81},{50,83}})}), Documentation(info="<html>

</html>"));
  protected 
    Modelica.SIunits.Time T0(final start=startTime) "Start time of current period";
    Modelica.SIunits.Time T_width=period*width/100;
  equation 
    when sample(startTime, period) then
      T0=time;
    end when;
    y=offset + (if time < startTime or time >= T0 + T_width then 0 else amplitude);
  end Pulse;

  block SawTooth "Generate saw tooth signal"
    parameter Real amplitude=1 "Amplitude of saw tooth";
    parameter SIunits.Time period(final min=Modelica.Constants.small)=1 "Time for one period";
    parameter Real offset=0 "Offset of output signals";
    parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
    extends Interfaces.SO;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Line(visible=true, points={{-80,-70},{-60,-70},{0,40},{0,-70},{60,41},{60,-70}}),Text(visible=true, extent={{-147,-152},{153,-112}}, textString="period=%period", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,-19},{-37,-32},{-30,-32},{-34,-19}}),Line(visible=true, points={{-34,-20},{-34,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,-70},{-37,-57},{-31,-57},{-34,-70},{-34,-70}}),Text(visible=true, fillColor={160,160,160}, extent={{-78,-36},{-35,-24}}, textString="offset", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-31,-87},{15,-69}}, textString="startTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-76,79},{-35,99}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Line(visible=true, points={{-10,-20},{-10,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-10,88},{-10,-20}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{30,88},{30,59}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-10,83},{30,83}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{-12,85},{34,97}}, textString="period", fontName="Arial"),Line(visible=true, points={{-44,60},{30,60}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-34,47},{-34,-7}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{-78,20},{-37,34}}, textString="amplitude", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,60},{-37,47},{-30,47},{-34,60}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-34,-20},{-37,-7},{-31,-7},{-34,-20},{-34,-20}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-10,83},{-1,85},{-1,81},{-10,83}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{30,83},{22,85},{22,81},{30,83}}),Line(visible=true, points={{-80,-20},{-10,-20},{30,60},{30,-20},{72,60},{72,-20}}, thickness=0.5)}));
  protected 
    SIunits.Time T0(final start=startTime) "Start time of current period";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-80,-70},{-60,-70},{0,40},{0,-70},{60,41},{60,-70}}, color={0,0,0}),Text(extent={{-147,-152},{153,-112}}, textString="period=%period", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-34,-19},{-37,-32},{-30,-32},{-34,-19}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-34,-20},{-34,-70}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Polygon(points={{-34,-70},{-37,-57},{-31,-57},{-34,-70},{-34,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(extent={{-78,-24},{-35,-36}}, textString="offset", fillColor={160,160,160}),Text(extent={{-31,-69},{15,-87}}, textString="startTime", fillColor={160,160,160}),Text(extent={{-76,99},{-35,79}}, textString="y", fillColor={160,160,160}),Text(extent={{70,-80},{94,-100}}, textString="time", fillColor={160,160,160}),Line(points={{-10,-20},{-10,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-10,88},{-10,-20}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{30,88},{30,59}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-10,83},{30,83}}, color={192,192,192}),Text(extent={{-12,97},{34,85}}, textString="period", fillColor={160,160,160}),Line(points={{-44,60},{30,60}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-34,47},{-34,-7}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Text(extent={{-78,34},{-37,20}}, textString="amplitude", fillColor={160,160,160}),Polygon(points={{-34,60},{-37,47},{-30,47},{-34,60}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-34,-20},{-37,-7},{-31,-7},{-34,-20},{-34,-20}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-10,83},{-1,85},{-1,81},{-10,83}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{30,83},{22,85},{22,81},{30,83}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-80,-20},{-10,-20},{30,60},{30,-20},{72,60},{72,-20}}, color={0,0,0}, thickness=0.5)}), Documentation(info="<html>

</html>"));
  equation 
    when sample(startTime, period) then
      T0=time;
    end when;
    y=offset + (if time < startTime then 0 else amplitude/period*(time - T0));
  end SawTooth;

  block Trapezoid "Generate trapezoidal signal of type Real"
    parameter Real amplitude=1 "Amplitude of trapezoid";
    parameter SIunits.Time rising(final min=0)=0 "Rising duration of trapezoid";
    parameter SIunits.Time width(final min=0)=0.5 "Width duration of trapezoid";
    parameter SIunits.Time falling(final min=0)=0 "Falling duration of trapezoid";
    parameter SIunits.Time period(final min=Modelica.Constants.small)=1 "Time for one period";
    parameter Integer nperiod=-1 "Number of periods (< 0 means infinite number of periods)";
    parameter Real offset=0 "Offset of output signal";
    parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
    extends Interfaces.SO;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Text(visible=true, extent={{-147,-152},{153,-112}}, textString="period=%period", fontName="Arial"),Line(visible=true, points={{-81,-70},{-60,-70},{-30,40},{9,40},{39,-70},{61,-70},{90,40}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-45,-30},{-47,-41},{-43,-41},{-45,-30}}),Line(visible=true, points={{-45,-31},{-45,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-45,-70},{-47,-60},{-43,-60},{-45,-70},{-45,-70}}),Text(visible=true, fillColor={160,160,160}, extent={{-86,-55},{-43,-43}}, textString="offset", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-47,-87},{-1,-69}}, textString="startTime", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-76,79},{-35,99}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Line(visible=true, points={{-29,82},{-30,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-10,59},{-10,40}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{20,59},{20,39}}, color={160,160,160}, pattern=LinePattern.Dash),Line(visible=true, points={{40,59},{40,-30}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-20,76},{61,76}}, color={192,192,192}),Line(visible=true, points={{-29,56},{40,56}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{-2,77},{25,86}}, textString="period", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-8,60},{21,70}}, textString="width", fontName="Arial"),Line(visible=true, points={{-42,40},{-10,40}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-39,40},{-39,-19}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{-77,0},{-40,14}}, textString="amplitude", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-29,56},{-22,58},{-22,54},{-29,56}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-10,56},{-17,58},{-17,54},{-10,56}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-29,76},{-20,78},{-20,74},{-29,76}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{61,76},{53,78},{53,74},{61,76}}),Line(visible=true, points={{-80,-30},{-30,-30},{-10,40},{20,40},{40,-30},{60,-30},{80,40},{100,40}}, thickness=0.5),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-39,40},{-41,29},{-37,29},{-39,40}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-39,-29},{-41,-19},{-37,-19},{-39,-29},{-39,-29}}),Line(visible=true, points={{61,84},{60,-30}}, color={192,192,192}, pattern=LinePattern.Dash),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{39,56},{32,58},{32,54},{39,56}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{20,56},{27,58},{27,54},{20,56}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{20,56},{13,58},{13,54},{20,56}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-12,56},{-5,58},{-5,54},{-12,56}}),Text(visible=true, fillColor={160,160,160}, extent={{-34,60},{-5,70}}, textString="rising", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{16,60},{45,70}}, textString="falling", fontName="Arial")}));
  protected 
    parameter SIunits.Time T_rising=rising "End time of rising phase within one period";
    parameter SIunits.Time T_width=T_rising + width "End time of width phase within one period";
    parameter SIunits.Time T_falling=T_width + falling "End time of falling phase within one period";
    SIunits.Time T0(final start=startTime) "Start time of current period";
    Integer counter(start=nperiod) "Period counter";
    Integer counter2(start=nperiod);
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(extent={{-147,-152},{153,-112}}, textString="period=%period", fillColor={0,0,0}),Line(points={{-81,-70},{-60,-70},{-30,40},{9,40},{39,-70},{61,-70},{90,40}}, color={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-45,-30},{-47,-41},{-43,-41},{-45,-30}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-45,-31},{-45,-70}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Polygon(points={{-45,-70},{-47,-60},{-43,-60},{-45,-70},{-45,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(extent={{-86,-43},{-43,-55}}, textString="offset", fillColor={160,160,160}),Text(extent={{-47,-69},{-1,-87}}, textString="startTime", fillColor={160,160,160}),Text(extent={{-76,99},{-35,79}}, textString="y", fillColor={160,160,160}),Text(extent={{70,-80},{94,-100}}, textString="time", fillColor={160,160,160}),Line(points={{-29,82},{-30,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-10,59},{-10,40}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{20,59},{20,39}}, color={160,160,160}, pattern=LinePattern.Dash),Line(points={{40,59},{40,-30}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-20,76},{61,76}}, color={192,192,192}),Line(points={{-29,56},{40,56}}, color={192,192,192}),Text(extent={{-2,86},{25,77}}, textString="period", fillColor={160,160,160}),Text(extent={{-8,70},{21,60}}, textString="width", fillColor={160,160,160}),Line(points={{-42,40},{-10,40}}, color={192,192,192}, pattern=LinePattern.Dash),Line(points={{-39,40},{-39,-19}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Text(extent={{-77,14},{-40,0}}, textString="amplitude", fillColor={160,160,160}),Polygon(points={{-29,56},{-22,58},{-22,54},{-29,56}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-10,56},{-17,58},{-17,54},{-10,56}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-29,76},{-20,78},{-20,74},{-29,76}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{61,76},{53,78},{53,74},{61,76}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-80,-30},{-30,-30},{-10,40},{20,40},{40,-30},{60,-30},{80,40},{100,40}}, color={0,0,0}, thickness=0.5),Polygon(points={{-39,40},{-41,29},{-37,29},{-39,40}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-39,-29},{-41,-19},{-37,-19},{-39,-29},{-39,-29}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{61,84},{60,-30}}, color={192,192,192}, pattern=LinePattern.Dash),Polygon(points={{39,56},{32,58},{32,54},{39,56}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{20,56},{27,58},{27,54},{20,56}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{20,56},{13,58},{13,54},{20,56}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-12,56},{-5,58},{-5,54},{-12,56}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Text(extent={{-34,70},{-5,60}}, textString="rising", fillColor={160,160,160}),Text(extent={{16,70},{45,60}}, textString="falling", fillColor={160,160,160})}), Documentation(info="<html>

</html>"));
  equation 
    when pre(counter2) <> 0 and sample(startTime, period) then
      T0=time;
      counter2=pre(counter);
      counter=pre(counter) - (if pre(counter) > 0 then 1 else 0);
    end when;
    y=offset + (if time < startTime or counter2 == 0 or time >= T0 + T_falling then 0 else if time < T0 + T_rising then (time - T0)*amplitude/T_rising else if time < T0 + T_width then amplitude else (T0 + T_falling - time)*amplitude/(T_falling - T_width));
  end Trapezoid;

  block KinematicPTP "Move as fast as possible along a distance within given kinematic constraints"
    parameter Real deltaq[:]={1} "Distance to move";
    parameter Real qd_max[:](final min=Modelica.Constants.small)={1} "Maximum velocities der(q)";
    parameter Real qdd_max[:](final min=Modelica.Constants.small)={1} "Maximum accelerations der(qd)";
    parameter SIunits.Time startTime=0 "Time instant at which movement starts";
    extends Interfaces.MO(final nout=max([size(deltaq, 1);size(qd_max, 1);size(qdd_max, 1)]));
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,78},{-80,-82}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,88},{-80,90}}),Line(visible=true, points={{-90,0},{82,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,0},{-70,0},{-70,70},{-30,70},{-30,0},{20,0},{20,-70},{60,-70},{60,0},{68,0}}),Text(visible=true, fillColor={192,192,192}, extent={{2,20},{80,80}}, textString="acc", fontName="Arial"),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="deltaq=%deltaq", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, extent={{-100,-100},{100,100}}),Line(visible=true, points={{-80,78},{-80,-82}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,88},{-80,90}}),Line(visible=true, points={{-90,0},{82,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,0},{-70,0},{-70,70},{-30,70},{-30,0},{20,0},{20,-70},{60,-70},{60,0},{68,0}}, thickness=0.5),Text(visible=true, fillColor={192,192,192}, extent={{-76,83},{-19,98}}, textString="acceleration", fontName="Arial"),Text(visible=true, fillColor={192,192,192}, extent={{69,12},{91,24}}, textString="time", fontName="Arial")}));
  protected 
    parameter Real p_deltaq[nout]=if size(deltaq, 1) == 1 then ones(nout)*deltaq[1] else deltaq;
    parameter Real p_qd_max[nout]=if size(qd_max, 1) == 1 then ones(nout)*qd_max[1] else qd_max;
    parameter Real p_qdd_max[nout]=if size(qdd_max, 1) == 1 then ones(nout)*qdd_max[1] else qdd_max;
    Real sd_max;
    Real sdd_max;
    Real sdd;
    Real aux1[nout];
    Real aux2[nout];
    SIunits.Time Ta1;
    SIunits.Time Ta2;
    SIunits.Time Tv;
    SIunits.Time Te;
    Boolean noWphase;
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,78},{-80,-82}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,88},{-80,90}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-90,0},{82,0}}, color={192,192,192}),Polygon(points={{90,0},{68,8},{68,-8},{90,0}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-80,0},{-70,0},{-70,70},{-30,70},{-30,0},{20,0},{20,-70},{60,-70},{60,0},{68,0}}, color={0,0,0}, thickness=0.25),Text(extent={{2,80},{80,20}}, textString="acc", fillColor={192,192,192}),Text(extent={{-150,-150},{150,-110}}, textString="deltaq=%deltaq", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, fillColor={0,0,0}, fillPattern=FillPattern.None),Line(points={{-80,78},{-80,-82}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,88},{-80,90}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-90,0},{82,0}}, color={192,192,192}),Polygon(points={{90,0},{68,8},{68,-8},{90,0}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-80,0},{-70,0},{-70,70},{-30,70},{-30,0},{20,0},{20,-70},{60,-70},{60,0},{68,0}}, color={0,0,0}, thickness=0.5),Text(extent={{-76,98},{-19,83}}, textString="acceleration", fillColor={192,192,192}),Text(extent={{69,24},{91,12}}, textString="time", fillColor={192,192,192})}), Documentation(info="<HTML>
<p>
The goal is to move as <b>fast</b> as possible along a distance
<b>deltaq</b>
under given <b>kinematical constraints</b>. The distance can be a positional or
angular range. In robotics such a movement is called <b>PTP</b> (Point-To-Point).
This source block generates the <b>acceleration</b> qdd of this signal
as output. After integrating the output two times, the position q is
obtained. The signal is constructed in such a way that it is not possible
to move faster, given the <b>maximally</b> allowed <b>velocity</b> qd_max and
the <b>maximally</b> allowed <b>acceleration</b> qdd_max.
</p>
<p>
If several distances are given (vector deltaq has more than 1 element),
an acceleration output vector is constructed such that all signals
are in the same periods in the acceleration, constant velocity
and deceleration phase. This means that only one of the signals
is at its limits whereas the others are sychnronized in such a way
that the end point is reached at the same time instant.
</p>
<p>
This element is useful to generate a reference signal for a controller
which controls a drive train or in combination with model
Modelica.Mechanics.Rotational.<b>Accelerate</b> to drive
a flange according to a given acceleration.
</p>

</HTML>
", revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>June 27, 2001</i>
       by Bernhard Bachmann.<br>
       Bug fixed that element is also correct if startTime is not zero.</li>
<li><i>Nov. 3, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Vectorized and moved from Rotational to Blocks.Sources.</li>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       realized.</li>
</ul>
</html>"));
  equation 
    for i in 1:nout loop
      aux1[i]=p_deltaq[i]/p_qd_max[i];
      aux2[i]=p_deltaq[i]/p_qdd_max[i];
    end for;
    sd_max=1/max(abs(aux1));
    sdd_max=1/max(abs(aux2));
    Ta1=sqrt(1/sdd_max);
    Ta2=sd_max/sdd_max;
    noWphase=Ta2 >= Ta1;
    Tv=if noWphase then Ta1 else 1/sd_max;
    Te=if noWphase then Ta1 + Ta1 else Tv + Ta2;
    sdd=if time < startTime then 0 else if noWphase then if time < Ta1 + startTime then sdd_max else if time < Te + startTime then -sdd_max else 0 else if time < Ta2 + startTime then sdd_max else if time < Tv + startTime then 0 else if time < Te + startTime then -sdd_max else 0;
    y=p_deltaq*sdd;
  end KinematicPTP;

  block TimeTable "Generate a (possibly discontinuous) signal by linear interpolation in a table"
    parameter Real table[:,2]=[0,0;1,1;2,4] "Table matrix (time = first column)";
    parameter Real offset=0 "Offset of output signal";
    parameter SIunits.Time startTime=0 "Output = offset for time < startTime";
    extends Interfaces.SO;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-48,-50},{2,70}}),Line(visible=true, points={{-48,-50},{-48,70},{52,70},{52,-50},{-48,-50},{-48,-20},{52,-20},{52,10},{-48,10},{-48,40},{52,40},{52,70},{2,70},{2,-51}}),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="offset=%offset", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-20,-30},{30,90}}),Line(visible=true, points={{-20,-30},{-20,90},{80,90},{80,-30},{-20,-30},{-20,0},{80,0},{80,30},{-20,30},{-20,60},{80,60},{80,90},{30,90},{30,-31}}),Text(visible=true, fillColor={160,160,160}, extent={{-77,-58},{-38,-42}}, textString="offset", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-31,-30},{-33,-40},{-28,-40},{-31,-30}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-30,-70},{-33,-60},{-28,-60},{-30,-70},{-30,-70}}),Line(visible=true, points={{-31,-31},{-31,-70}}, color={192,192,192}),Line(visible=true, points={{-20,-20},{-20,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Text(visible=true, fillColor={160,160,160}, extent={{-38,-88},{8,-70}}, textString="startTime", fontName="Arial"),Line(visible=true, points={{-20,-30},{-80,-30}}, color={192,192,192}, pattern=LinePattern.Dash),Text(visible=true, fillColor={160,160,160}, extent={{-73,78},{-41,93}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{66,-93},{91,-81}}, textString="time", fontName="Arial"),Text(visible=true, extent={{-15,68},{24,83}}, textString="time", fontName="Arial"),Text(visible=true, extent={{33,67},{76,83}}, textString="y", fontName="Arial")}));
  protected 
    Real a "Interpolation coefficients a of actual interval (y=a*x+b)";
    Real b "Interpolation coefficients b of actual interval (y=a*x+b)";
    Integer last(start=1) "Last used lower grid index";
    SIunits.Time nextEvent(start=0) "Next event instant";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Rectangle(extent={{-48,70},{2,-50}}, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-48,-50},{-48,70},{52,70},{52,-50},{-48,-50},{-48,-20},{52,-20},{52,10},{-48,10},{-48,40},{52,40},{52,70},{2,70},{2,-51}}, color={0,0,0}),Text(extent={{-150,-150},{150,-110}}, textString="offset=%offset", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Rectangle(extent={{-20,90},{30,-30}}, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-20,-30},{-20,90},{80,90},{80,-30},{-20,-30},{-20,0},{80,0},{80,30},{-20,30},{-20,60},{80,60},{80,90},{30,90},{30,-31}}, color={0,0,0}),Text(extent={{-77,-42},{-38,-58}}, textString="offset", fillColor={160,160,160}),Polygon(points={{-31,-30},{-33,-40},{-28,-40},{-31,-30}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-30,-70},{-33,-60},{-28,-60},{-30,-70},{-30,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-31,-31},{-31,-70}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Line(points={{-20,-20},{-20,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Text(extent={{-38,-70},{8,-88}}, textString="startTime", fillColor={160,160,160}),Line(points={{-20,-30},{-80,-30}}, color={192,192,192}, pattern=LinePattern.Dash),Text(extent={{-73,93},{-41,78}}, textString="y", fillColor={160,160,160}),Text(extent={{66,-81},{91,-93}}, textString="time", fillColor={160,160,160}),Text(extent={{-15,83},{24,68}}, textString="time", fillColor={0,0,0}),Text(extent={{33,83},{76,67}}, textString="y", fillColor={0,0,0})}), Documentation(info="<HTML>
<p>
This block generates an output signal by <b>linear interpolation</b> in
a table. The time points and function values are stored in a matrix
<b>table[i,j]</b>, where the first column table[:,1] contains the
time points and the second column contains the data to be interpolated.
The table interpolation has the following proporties:
</p>
<ul>
<li>The time points need to be <b>monotonically increasing</b>. </li>
<li><b>Discontinuities</b> are allowed, by providing the same
    time point twice in the table. </li>
<li>Values <b>outside</b> of the table range, are computed by
    <b>extrapolation</b> through the last or first two points of the
    table.</li>
<li>If the table has only <b>one row</b>, no interpolation is performed and
    the function value is just returned independantly of the
    actual time instant.</li>
<li>Via parameters <b>startTime</b> and <b>offset</b> the curve defined
    by the table can be shifted both in time and in the ordinate value.
<li>The table is implemented in a numerically sound way by
    generating <b>time events</b> at interval boundaries,
    in order to not integrate over a discontinuous or not differentiable
    points.
</li>
</ul>
<p>
Example:
</p>
<pre>
   table = [0  0
            1  0
            1  1
            2  4
            3  9
            4 16]
If, e.g., time = 1.0, the output y =  0.0 (before event), 1.0 (after event)
    e.g., time = 1.5, the output y =  2.5,
    e.g., time = 2.0, the output y =  4.0,
    e.g., time = 5.0, the output y = 23.0 (i.e. extrapolation).
</pre>

</HTML>
", revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>Oct. 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Corrected interface from
<pre>
    parameter Real table[:, :]=[0, 0; 1, 1; 2, 4];
</pre>
       to
<pre>
    parameter Real table[:, <b>2</b>]=[0, 0; 1, 1; 2, 4];
</pre>
       </li>
<li><i>Nov. 7, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
</html>"));
    function getInterpolationCoefficients "Determine interpolation coefficients and next time event"
      input Real table[:,2] "Table for interpolation";
      input Real offset "y-offset";
      input Real startTime "time-offset";
      input Real t "Actual time instant";
      input Integer last "Last used lower grid index";
      input Real TimeEps "Relative epsilon to check for identical time instants";
      output Real a "Interpolation coefficients a (y=a*x + b)";
      output Real b "Interpolation coefficients b (y=a*x + b)";
      output Real nextEvent "Next event instant";
      output Integer next "New lower grid index";
    protected 
      Integer columns=2 "Column to be interpolated";
      Integer ncol=2 "Number of columns to be interpolated";
      Integer nrow=size(table, 1) "Number of table rows";
      Integer next0;
      Real tp;
      Real dt;
    algorithm 
      next:=last;
      nextEvent:=t - TimeEps*abs(t);
      tp:=t + TimeEps*abs(t) - startTime;
      if tp < 0.0 then 
        nextEvent:=startTime;
        a:=0;
        b:=offset;
      elseif nrow < 2 then
        a:=0;
        b:=offset + table[1,columns];
      else
        while (next < nrow and tp >= table[next,1]) loop
          next:=next + 1;
        end while;
        if next < nrow then 
          nextEvent:=startTime + table[next,1];
        end if;
        next0:=next - 1;
        dt:=table[next,1] - table[next0,1];
        if dt <= TimeEps*abs(table[next,1]) then 
          a:=0;
          b:=offset + table[next,columns];
        else
          a:=(table[next,columns] - table[next0,columns])/dt;
          b:=offset + table[next0,columns] - a*table[next0,1];
        end if;
      end if;
      b:=b - a*startTime;
    end getInterpolationCoefficients;

  algorithm 
    when {time >= pre(nextEvent),initial()} then
          (a,b,nextEvent,last):=getInterpolationCoefficients(table, offset, startTime, time, last, 100*Modelica.Constants.eps);
    end when;
  equation 
    y=a*time + b;
  end TimeTable;

  model CombiTimeTable "Table look-up with respect to time and linear/perodic extrapolation methods (data from matrix/file)"
    parameter Boolean tableOnFile=false "true, if table is defined on file or in function usertab" annotation(Dialog(group="table data definition"));
    parameter Real table[:,:]=fill(0.0, 0, 2) "table matrix (time = first column)" annotation(Dialog(group="table data definition", enable=not tableOnFile));
    parameter String tableName="NoName" "table name on file or in function usertab (see docu)" annotation(Dialog(group="table data definition", enable=tableOnFile));
    parameter String fileName="NoName" "file where matrix is stored" annotation(Dialog(group="table data definition", enable=tableOnFile));
    parameter Integer columns[:]=2:size(table, 2) "columns of table to be interpolated" annotation(Dialog(group="table data interpretation"));
    parameter Blocks.Types.Smoothness.Temp smoothness=Blocks.Types.Smoothness.LinearSegments "smoothness of table interpolation" annotation(Dialog(group="table data interpretation"));
    parameter Blocks.Types.Extrapolation.Temp extrapolation=Blocks.Types.Extrapolation.LastTwoPoints "extrapolation of data outside the definition range" annotation(Dialog(group="table data interpretation"));
    parameter Real offset[:]={0} "Offsets of output signals" annotation(Dialog(group="table data interpretation"));
    parameter SI.Time startTime=0 "Output = offset for time < startTime" annotation(Dialog(group="table data interpretation"));
    extends Modelica.Blocks.Interfaces.MO(final nout=max([size(columns, 1);size(offset, 1)]));
    final parameter Real t_min(fixed=false);
    final parameter Real t_max(fixed=false);
    annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-20,-30},{20,90}}),Line(visible=true, points={{-20,-30},{-20,90},{80,90},{80,-30},{-20,-30},{-20,0},{80,0},{80,30},{-20,30},{-20,60},{80,60},{80,90},{20,90},{20,-30}}),Text(visible=true, fillColor={160,160,160}, extent={{-77,-58},{-38,-42}}, textString="offset", fontName="Arial"),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-31,-30},{-33,-40},{-28,-40},{-31,-30}}),Polygon(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-30,-70},{-33,-60},{-28,-60},{-30,-70},{-30,-70}}),Line(visible=true, points={{-31,-31},{-31,-70}}, color={192,192,192}),Line(visible=true, points={{-20,-30},{-20,-70}}, color={192,192,192}, pattern=LinePattern.Dot),Text(visible=true, fillColor={160,160,160}, extent={{-38,-88},{8,-70}}, textString="startTime", fontName="Arial"),Line(visible=true, points={{-20,-30},{-80,-30}}, color={192,192,192}, pattern=LinePattern.Dot),Text(visible=true, fillColor={160,160,160}, extent={{-73,78},{-41,93}}, textString="y", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{66,-93},{91,-81}}, textString="time", fontName="Arial"),Text(visible=true, extent={{-19,68},{20,83}}, textString="time", fontName="Arial"),Text(visible=true, extent={{21,68},{50,82}}, textString="y[1]", fontName="Arial"),Line(visible=true, points={{50,90},{50,-30}}),Line(visible=true, points={{80,0},{100,0}}),Text(visible=true, extent={{34,-42},{71,-30}}, textString="columns", fontName="Arial"),Text(visible=true, extent={{51,68},{80,82}}, textString="y[2]", fontName="Arial")}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Rectangle(visible=true, lineColor={255,255,255}, fillColor={255,255,0}, fillPattern=FillPattern.Solid, extent={{-48,-50},{2,70}}),Line(visible=true, points={{-48,-50},{-48,70},{52,70},{52,-50},{-48,-50},{-48,-20},{52,-20},{52,10},{-48,10},{-48,40},{52,40},{52,70},{2,70},{2,-51}})}));
  protected 
    final parameter Real p_offset[nout]=if size(offset, 1) == 1 then ones(nout)*offset[1] else offset;
    Integer tableID;
    function tableTimeInit
      input Real timeIn;
      input Real startTime;
      input Integer ipoType;
      input Integer expoType;
      input String tableName;
      input String fileName;
      input Real table[:,:];
      input Integer colWise;
      output Integer tableID;

      external "C" tableID=omcTableTimeIni(timeIn,startTime,ipoType,expoType,tableName,fileName,table,size(table, 1),size(table, 2),colWise) ;

    end tableTimeInit;

    function tableTimeIpo
      input Integer tableID;
      input Integer icol;
      input Real timeIn;
      output Real value;

      external "C" value=omcTableTimeIpo(tableID,icol,timeIn) ;

    end tableTimeIpo;

    function tableTimeTmin
      input Integer tableID;
      output Real Tmin "minimum time value in table";

      external "C" Tmin=omcTableTimeTmin(tableID) ;

    end tableTimeTmin;

    function tableTimeTmax
      input Integer tableID;
      output Real Tmax "maximum time value in table";

      external "C" Tmax=omcTableTimeTmax(tableID) ;

    end tableTimeTmax;

    annotation(Documentation(info="<HTML>
<p>
This block generates an output signal y[:] by <b>linear interpolation</b> in
a table. The time points and function values are stored in a matrix
<b>table[i,j]</b>, where the first column table[:,1] contains the
time points and the other columns contain the data to be interpolated.
Via parameter <b>columns</b> it can be defined which columns of the
table are interpolated. If, e.g., columns={2,4}, it is assumed that
2 output signals are present and that the first output is computed
by interpolation of column 2 and the second output is computed
by interpolation of column 4 of the table matrix.
The table interpolation has the following properties:
</p>
<ul>
<li>The time points need to be <b>monotonically increasing</b>. </li>
<li><b>Discontinuities</b> are allowed, by providing the same
    time point twice in the table. </li>
<li>Values <b>outside</b> of the table range, are computed by
    extrapolation according to the setting of parameter
    <b>extrapolation</b>:
<pre>
  extrapolation = 0: hold the first or last value of the table,
                     if outside of the range.
                = 1: extrapolate through the last or first two
                     points of the table.
                = 2: periodically repeat the table data
                     (periodical function).
</pre></li>
<li>Via parameter <b>smoothness</b> it is defined how the data is interpolated:
<pre>
  smoothness = 0: linear interpolation
             = 1: smooth interpolation with Akima Splines such
                  that der(y) is continuous.
</pre></li>
<li>If the table has only <b>one row</b>, no interpolation is performed and
    the table values of this row are just returned.</li>
<li>Via parameters <b>startTime</b> and <b>offset</b> the curve defined
    by the table can be shifted both in time and in the ordinate value.
    The time instants stored in the table are therefore <b>relative</b>
    to <b>startTime</b>.
    If time &lt; startTime, no interpolation is performed and the offset
    is used as ordinate value for all outputs.
<li>The table is implemented in a numerically sound way by
    generating <b>time events</b> at interval boundaries,
    in order to not integrate over a discontinuous or not differentiable
    points.
<li>For special applications it is sometimes needed to know the minimum
    and maximum time instant defined in the table as a parameter. For this
    reason parameters <b>t_min</b> and <b>t_max</b> are provided and can be access from
    the outside of the table object.
</li>
</ul>
<p>
Example:
</p>
<pre>
   table = [0  0
            1  0
            1  1
            2  4
            3  9
            4 16]; extrapolation = 1 (default)
If, e.g., time = 1.0, the output y =  0.0 (before event), 1.0 (after event)
    e.g., time = 1.5, the output y =  2.5,
    e.g., time = 2.0, the output y =  4.0,
    e.g., time = 5.0, the output y = 23.0 (i.e. extrapolation via last 2 points).
</pre>
<p>
The table matrix can be defined in the following ways:
</p>
<ol>
<li> Explicitly supplied as <b>parameter matrix</b> \"table\",
     and the other parameters have the following values:
<pre>
   tableName is \"NoName\" or has only blanks,
   fileName  is \"NoName\" or has only blanks.
</pre></li>
<li> <b>Read</b> from a <b>file</b> \"fileName\" where the matrix is stored as
      \"tableName\". Both ASCII and binary file format is possible.
      (the ASCII format is described below).
      It is most convenient to generate the binary file from Matlab
      (Matlab 4 storage format), e.g., by command
<pre>
   save tables.mat tab1 tab2 tab3 -V4
</pre>
      when the three tables tab1, tab2, tab3 should be
      used from the model.</li>
<li>  Statically stored in function \"usertab\" in file \"usertab.c\".
      The matrix is identified by \"tableName\". Parameter
      fileName = \"NoName\" or has only blanks.</li>
</ol>
<p>
Table definition methods (1) and (3) do <b>not</b> allocate dynamic memory,
and do not access files, whereas method (2) does. Therefore (1) and (3)
are suited for hardware-in-the-loop simulation (e.g. with dSpace hardware).
When the constant \"NO_FILE\" is defined in \"usertab.c\", all parts of the
source code of method (2) are removed by the C-preprocessor, such that
no dynamic memory allocation and no access to files takes place.
</p>
<p>
If tables are read from an ASCII-file, the file need to have the
following structure (\"-----\" is not part of the file content):
</p>
<pre>
-----------------------------------------------------
#1
double tab1(6,2)   # comment line
  0   0
  1   0
  1   1
  2   4
  3   9
  4  16
double tab2(6,2)   # another comment line
  0   0
  2   0
  2   2
  4   8
  6  18
  8  32
-----------------------------------------------------
</pre>
<p>
Note, that the first two characters in the file need to be
\"#1\". Afterwards, the corresponding matrix has to be declared
with type, name and actual dimensions. Finally, in successive
rows of the file, the elements of the matrix have to be given.
Several matrices may be defined one after another.
</p>

</HTML>
", revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>March 31, 2001</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Used CombiTableTime as a basis and added the
       arguments <b>extrapolation, columns, startTime</b>.
       This allows periodic function definitions. </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Rectangle(extent={{-48,70},{2,-50}}, lineColor={255,255,255}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Line(points={{-48,-50},{-48,70},{52,70},{52,-50},{-48,-50},{-48,-20},{52,-20},{52,10},{-48,10},{-48,40},{52,40},{52,70},{2,70},{2,-51}}, color={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Rectangle(extent={{-20,90},{20,-30}}, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-20,-30},{-20,90},{80,90},{80,-30},{-20,-30},{-20,0},{80,0},{80,30},{-20,30},{-20,60},{80,60},{80,90},{20,90},{20,-30}}, color={0,0,0}),Text(extent={{-77,-42},{-38,-58}}, textString="offset", fillColor={160,160,160}),Polygon(points={{-31,-30},{-33,-40},{-28,-40},{-31,-30}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Polygon(points={{-30,-70},{-33,-60},{-28,-60},{-30,-70},{-30,-70}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(points={{-31,-31},{-31,-70}}, color={192,192,192}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Line(points={{-20,-30},{-20,-70}}, color={192,192,192}, pattern=LinePattern.Dash),Text(extent={{-38,-70},{8,-88}}, textString="startTime", fillColor={160,160,160}),Line(points={{-20,-30},{-80,-30}}, color={192,192,192}, pattern=LinePattern.Dash),Text(extent={{-73,93},{-41,78}}, fillColor={160,160,160}, textString="y"),Text(extent={{66,-81},{91,-93}}, textString="time", fillColor={160,160,160}),Text(extent={{-19,83},{20,68}}, textString="time", fillColor={0,0,0}),Text(extent={{21,82},{50,68}}, fillColor={0,0,0}, textString="y[1]"),Line(points={{50,90},{50,-30}}, color={0,0,0}),Line(points={{80,0},{100,0}}),Text(extent={{34,-30},{71,-42}}, textString="columns"),Text(extent={{51,82},{80,68}}, fillColor={0,0,0}, textString="y[2]")}));
  equation 
    if tableOnFile then
      assert(tableName <> "NoName", "tableOnFile = true and no table name given");
    end if;
    if not tableOnFile then
      assert(size(table, 1) > 0 and size(table, 2) > 0, "tableOnFile = false and parameter table is an empty matrix");
    end if;
    for i in 1:nout loop
      y[i]=p_offset[i] + tableTimeIpo(tableID, columns[i], time);
    end for;
    when initial() then
      tableID=tableTimeInit(0.0, startTime, smoothness, extrapolation, if not tableOnFile then "NoName" else tableName, if not tableOnFile then "NoName" else fileName, table, 0);
    end when;
  initial equation 
    t_min=tableTimeTmin(tableID);
    t_max=tableTimeTmax(tableID);
  end CombiTimeTable;

  block BooleanConstant "Generate constant signal of type Boolean"
    parameter Boolean k=true "Constant output value";
    extends Interfaces.partialBooleanSource;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,0},{80,0}}),Text(visible=true, extent={{-150,-140},{150,-110}}, textString="%k", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,0},{80,0}}, thickness=0.5),Text(visible=true, fillColor={160,160,160}, extent={{-83,0},{-63,20}}, textString="k", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-100,-6},{-80,6}}, textString="true", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-104,-70},{-78,-58}}, textString="false", fontName="Arial")}), Documentation(info="<html>

</html>"));
  equation 
    y=k;
  end BooleanConstant;

  block BooleanStep "Generate step signal of type Boolean"
    parameter Modelica.SIunits.Time startTime=0 "Time instant of step start";
    parameter Boolean startValue=false "Output before startTime";
    extends Interfaces.partialBooleanSource;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,-70},{0,-70},{0,50},{80,50}}),Text(visible=true, extent={{-150,-140},{150,-110}}, textString="%startTime", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,-70},{0,-70},{0,50},{80,50}}, thickness=0.5),Text(visible=true, extent={{-25,-94},{21,-76}}, textString="startTime", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, pattern=LinePattern.Dash, points={{2,50},{-80,50},{2,50}}),Text(visible=true, extent={{-130,42},{-86,56}}, textString="not startValue", fontName="Arial"),Text(visible=true, extent={{-126,-78},{-94,-64}}, textString="startValue", fontName="Arial")}), Documentation(info="<html>

</html>"));
  equation 
    y=if time >= startTime then not startValue else startValue;
  end BooleanStep;

  block BooleanPulse "Generate pulse signal of type Boolean"
    parameter Real width(final min=Modelica.Constants.small, final max=100)=50 "Width of pulse in % of period";
    parameter Modelica.SIunits.Time period(final min=Modelica.Constants.small)=1 "Time for one period";
    parameter Modelica.SIunits.Time startTime=0 "Time instant of first pulse";
    extends Modelica.Blocks.Interfaces.partialBooleanSource;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-150,-140},{150,-110}}, textString="%period", fontName="Arial"),Line(visible=true, points={{-80,-70},{-40,-70},{-40,44},{0,44},{0,-70},{40,-70},{40,44},{79,44}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-60,-90},{-14,-72}}, textString="startTime", fontName="Arial"),Line(visible=true, points={{-78,-70},{-40,-70},{-40,20},{20,20},{20,-70},{50,-70},{50,20},{100,20}}, thickness=0.5),Line(visible=true, points={{-40,61},{-40,21}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{20,44},{20,20}}, color={160,160,160}, pattern=LinePattern.Dash),Line(visible=true, points={{50,58},{50,20}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-40,53},{50,53}}, color={192,192,192}),Line(visible=true, points={{-40,35},{20,35}}, color={192,192,192}),Text(visible=true, extent={{-30,55},{16,67}}, textString="period", fontName="Arial"),Text(visible=true, extent={{-35,37},{14,49}}, textString="width", fontName="Arial"),Line(visible=true, points={{-80,20},{-41,20}}, color={192,192,192}, pattern=LinePattern.Dash),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-40,35},{-31,37},{-31,33},{-40,35}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{20,35},{12,37},{12,33},{20,35}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-40,53},{-31,55},{-31,51},{-40,53}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{50,53},{42,55},{42,51},{50,53}}),Text(visible=true, extent={{-109,14},{-77,28}}, textString="true", fontName="Arial"),Text(visible=true, extent={{-101,-71},{-80,-56}}, textString="false", fontName="Arial")}), Documentation(info="<html>

</html>"));
  protected 
    parameter Modelica.SIunits.Time Twidth=period*width/100 "width of one pulse" annotation(Hide=true);
    discrete Modelica.SIunits.Time pulsStart "Start time of pulse" annotation(Hide=true);
  initial equation 
    pulsStart=startTime;
  equation 
    when sample(startTime, period) then
      pulsStart=time;
    end when;
    y=time >= pulsStart and time < pulsStart + Twidth;
  end BooleanPulse;

  block SampleTrigger "Generate sample trigger signal"
    parameter Modelica.SIunits.Time period(final min=Modelica.Constants.small)=0.01 "Sample period";
    parameter Modelica.SIunits.Time startTime=0 "Time instant of first sample trigger";
    extends Interfaces.partialBooleanSource;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-60,-70},{-60,70}}),Line(visible=true, points={{-20,-70},{-20,70}}),Line(visible=true, points={{20,-70},{20,70}}),Line(visible=true, points={{60,-70},{60,70}}),Text(visible=true, extent={{-150,-140},{150,-110}}, textString="%period", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-53,-89},{-7,-71}}, textString="startTime", fontName="Arial"),Line(visible=true, points={{-30,47},{-30,19}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{0,47},{0,18}}, color={192,192,192}, pattern=LinePattern.Dash),Line(visible=true, points={{-30,41},{0,41}}, color={192,192,192}),Text(visible=true, extent={{-37,49},{9,61}}, textString="period", fontName="Arial"),Line(visible=true, points={{-80,19},{-30,19}}, color={192,192,192}, pattern=LinePattern.Dash),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-30,41},{-21,43},{-21,39},{-30,41}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{0,41},{-8,43},{-8,39},{0,41}}),Text(visible=true, extent={{-100,13},{-80,28}}, textString="true", fontName="Arial"),Text(visible=true, extent={{-100,-71},{-80,-56}}, textString="false", fontName="Arial"),Line(visible=true, points={{0,-70},{0,19}}, thickness=0.5),Line(visible=true, points={{-30,-70},{-30,19}}, thickness=0.5),Line(visible=true, points={{30,-70},{30,19}}, thickness=0.5),Line(visible=true, points={{60,-70},{60,19}}, thickness=0.5)}), Documentation(info="<html>

</html>"));
  equation 
    y=sample(startTime, period);
  end SampleTrigger;

  block BooleanTable "Generate a Boolean output signal based on a vector of time instants"
    parameter Boolean startValue=false "Start value of y. At time = table[1], y changes to 'not startValue'";
    parameter Modelica.SIunits.Time table[:] "Vector of time points. At every time point, the output y gets its opposite value";
    extends Interfaces.partialBooleanSource;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-18,-50},{32,70}}),Line(visible=true, points={{-18,-50},{-18,70},{32,70},{32,-50},{-18,-50},{-18,-20},{32,-20},{32,10},{-18,10},{-18,40},{32,40},{32,70},{32,70},{32,-51}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={255,255,255}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-34,-54},{16,66}}),Line(visible=true, points={{-34,-54},{-34,66},{16,66},{16,-54},{-34,-54},{-34,-24},{16,-24},{16,6},{-34,6},{-34,36},{16,36},{16,66},{16,66},{16,-55}}),Text(visible=true, extent={{-29,44},{10,59}}, textString="time", fontName="Arial")}), Documentation(info="<html>

</html>"));
  protected 
    function getFirstIndex "Get first index of table and check table"
      input Real table[:] "Vector of time instants";
      input Modelica.SIunits.Time simulationStartTime "Simulation start time";
      input Boolean startValue "Value of y for y < table[1]";
      output Integer index "First index to be used";
      output Modelica.SIunits.Time nextTime "Time instant of first event";
      output Boolean y "Value of y at simulationStartTime";
    protected 
      Modelica.SIunits.Time t_last;
      Integer j;
      Integer n=size(table, 1) "Number of table points";
    algorithm 
      if size(table, 1) == 0 then 
        index:=0;
        nextTime:=-Modelica.Constants.inf;
        y:=startValue;
      elseif size(table, 1) == 1 then
        index:=1;
        if table[1] > simulationStartTime then 
          nextTime:=table[1];
          y:=startValue;
        else
          nextTime:=simulationStartTime;
          y:=startValue;
        end if;
      else
        t_last:=table[1];
        for i in 2:n loop
          assert(table[i] > t_last, "Time values of table not strict monotonically increasing: table[" + String(i - 1) + "] = " + String(table[i - 1]) + "table[" + String(i) + "] = " + String(table[i]));
        end for;
        j:=1;
        y:=startValue;
        while (j < n and table[j] <= simulationStartTime) loop
          y:=not y;
          j:=j + 1;
        end while;
        if j == 1 then 
          nextTime:=table[1];
          y:=startValue;
        elseif j == n and table[n] <= simulationStartTime then
          nextTime:=simulationStartTime - 1;
          y:=not y;
        else
          nextTime:=table[j];
        end if;
        index:=j;
      end if;
    end getFirstIndex;

    parameter Integer n=size(table, 1) "Number of table points";
    Modelica.SIunits.Time nextTime;
    Integer index "Index of actual table entry";
  initial algorithm 
    (index,nextTime,y):=getFirstIndex(table, time, startValue);
  algorithm 
    when time >= pre(nextTime) and n > 0 then
          if index < n then 
        index:=index + 1;
        nextTime:=table[index];
        y:=not y;
      elseif index == n then
        index:=index + 1;
        y:=not y;
      end if;
    end when;
  end BooleanTable;

  block IntegerConstant "Generate constant signal of type Integer"
    parameter Integer k=1 "Constant output value";
    extends Interfaces.IntegerSO;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Line(visible=true, points={{-80,0},{80,0}}),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="k=%k", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-80,0},{80,0}}, thickness=0.5),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Text(visible=true, fillColor={160,160,160}, extent={{-75,76},{-22,94}}, textString="outPort", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-101,-12},{-81,8}}, textString="k", fontName="Arial")}), Documentation(info="<html>

</html>"));
  equation 
    y=k;
  end IntegerConstant;

  block IntegerStep "Generate step signal of type Integer"
    parameter Integer height=1 "Height of step";
    extends Interfaces.IntegerSignalSource;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Line(visible=true, points={{-80,-70},{0,-70},{0,50},{80,50}}),Text(visible=true, extent={{-150,-150},{150,-110}}, textString="startTime=%startTime", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Line(visible=true, points={{-80,68},{-80,-80}}, color={192,192,192}),Line(visible=true, points={{-80,-18},{0,-18},{0,50},{80,50}}, thickness=0.5),Line(visible=true, points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-70},{68,-62},{68,-78},{90,-70}}),Text(visible=true, fillColor={160,160,160}, extent={{70,-100},{94,-80}}, textString="time", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-21,-90},{25,-72}}, textString="startTime", fontName="Arial"),Line(visible=true, points={{0,-17},{0,-71}}, color={192,192,192}, pattern=LinePattern.Dash),Text(visible=true, fillColor={160,160,160}, extent={{-68,-54},{-22,-36}}, textString="offset", fontName="Arial"),Line(visible=true, points={{-13,50},{-13,-17}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, pattern=LinePattern.Dash, points={{2,50},{-19,50},{2,50}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-13,-17},{-16,-4},{-10,-4},{-13,-17},{-13,-17}}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-13,50},{-16,37},{-9,37},{-13,50}}),Text(visible=true, fillColor={160,160,160}, extent={{-68,8},{-22,26}}, textString="height", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-13,-69},{-16,-56},{-10,-56},{-13,-69},{-13,-69}}),Line(visible=true, points={{-13,-18},{-13,-70}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-13,-18},{-16,-31},{-9,-31},{-13,-18}}),Text(visible=true, fillColor={160,160,160}, extent={{-72,80},{-31,100}}, textString="outPort", fontName="Arial")}), Documentation(info="<html>

</html>"));
  equation 
    y=offset + (if time < startTime then 0 else height);
  end IntegerStep;

end Sources;
