within Modelica.Electrical.Analog;
package Basic "Basic electrical components such as resistor, capacitor, transformer"
  extends Modelica.Icons.Library;
  annotation(preferedView="info", Documentation(info="<HTML>
<p>
This package contains basic analog electrical components.
</p>

</HTML>
", revisions="<html>
<dl>
<dt>
<b>Main Authors:</b>
<dd>
<a href=\"http://people.eas.iis.fhg.de/Christoph.Clauss/\">Christoph Clau&szlig;</a>
    &lt;<a href=\"mailto:clauss@eas.iis.fhg.de\">clauss@eas.iis.fhg.de</a>&gt;<br>
    <a href=\"http://people.eas.iis.fhg.de/Andre.Schneider/\">Andr&eacute; Schneider</a>
    &lt;<a href=\"mailto:schneider@eas.iis.fhg.de\">schneider@eas.iis.fhg.de</a>&gt;<br>
    Fraunhofer Institute for Integrated Circuits<br>
    Design Automation Department<br>
    Zeunerstra&szlig;e 38<br>
    D-01069 Dresden<br>
<p>
</dl>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  model Ground "Ground node"
    annotation(Documentation(info="<HTML>
<P>
Ground of an electrical circuit. The potential at the
ground node is zero. Every electrical circuit has to contain
at least one ground object.
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-60,50},{60,50}}, color={0,0,255}),Line(visible=true, points={{-40,30},{40,30}}, color={0,0,255}),Line(visible=true, points={{-20,10},{20,10}}, color={0,0,255}),Line(visible=true, points={{0,90},{0,50}}, color={0,0,255}),Text(visible=true, fillColor={0,0,255}, extent={{-144,-60},{138,0}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-60,50},{60,50}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{-40,30},{40,30}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{-20,10},{20,10}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{0,96},{0,50}}, color={0,0,255}, thickness=0.5),Text(visible=true, extent={{-24,-38},{22,-6}}, textString="p.v=0", fontName="Arial")}));
    Interfaces.Pin p annotation(Placement(visible=true, transformation(origin={0,100}, extent={{-10,10},{10,-10}}, rotation=90), iconTransformation(origin={0,100}, extent={{-10,10},{10,-10}}, rotation=90)));
  equation 
    p.v=0;
  end Ground;

  model Resistor "Ideal linear electrical resistor"
    extends Interfaces.OnePort;
    parameter SI.Resistance R=1 "Resistance";
    annotation(Documentation(info="<HTML>
<P>
The linear resistor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by <i>i*R = v</i>.
The Resistance <i>R</i> is allowed to be positive, zero, or negative.
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-30},{70,30}}),Line(visible=true, points={{-90,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{70,0},{90,0}}, color={0,0,255}),Text(visible=true, extent={{-144,-100},{144,-60}}, textString="R=%R", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, extent={{-144,40},{144,100}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, extent={{-70,-30},{70,30}}),Line(visible=true, points={{-96,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{70,0},{96,0}}, color={0,0,255})}));
  equation 
    R*i=v;
  end Resistor;

  model HeatingResistor "Temperature dependent electrical resistor"
    extends Modelica.Electrical.Analog.Interfaces.OnePort;
    parameter SI.Resistance R_ref=1 "Resistance at temperature T_ref";
    parameter SI.Temperature T_ref=300 "Reference temperature";
    parameter Real alpha(unit="1/K")=0 "Temperature coefficient of resistance";
    SI.Resistance R "Resistance = R_ref*(1 + alpha*(heatPort.T - T_ref));";
    annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-110,20},{-85,20}}, color={160,160,160}),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-95,23},{-85,20},{-95,17},{-95,23}}),Line(visible=true, points={{90,20},{115,20}}, color={160,160,160}),Line(visible=true, points={{-125,0},{-115,0}}, color={160,160,160}),Line(visible=true, points={{-120,-5},{-120,5}}, color={160,160,160}),Text(visible=true, fillColor={160,160,160}, extent={{-110,25},{-90,45}}, textString="i", fontName="Arial"),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{105,23},{115,20},{105,17},{105,23}}),Line(visible=true, points={{115,0},{125,0}}, color={160,160,160}),Text(visible=true, fillColor={160,160,160}, extent={{90,25},{110,45}}, textString="i", fontName="Arial"),Rectangle(visible=true, lineColor={0,0,255}, extent={{-70,-30},{70,30}}),Line(visible=true, points={{-96,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{70,0},{96,0}}, color={0,0,255}),Line(visible=true, points={{0,-30},{0,-90}}, color={191,0,0}),Line(visible=true, points={{-52,-50},{48,50}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{40,52},{50,42},{54,56},{40,52}})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,0,255}, extent={{-142,60},{143,118}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-90,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{70,0},{90,0}}, color={0,0,255}),Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-30},{70,30}}),Line(visible=true, points={{0,-30},{0,-91}}, color={191,0,0}),Line(visible=true, points={{-52,-50},{48,50}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{40,52},{50,42},{54,56},{40,52}})}), Documentation(info="<HTML>
<p>This is a model for an electrical resistor where the generated heat
is dissipated to the environment via connector <b>heatPort</b> and where
the resistance R is temperature dependent according to the following
equation:</p>
<pre>    R = R_ref*(1 + alpha*(heatPort.T - T_ref))
</pre>
<p><b>alpha</b> is the <b>temperature coefficient of resistance</b>, which
is often abbreviated as <b>TCR</b>. In resistor catalogues, it is usually
defined as <b>X [ppm/K]</b> (parts per million, similarly to per centage)
meaning <b>X*1.e-6 [1/K]</b>. Resistors are available for 1 .. 7000 ppm/K,
i.e., alpha = 1e-6 .. 7e-3 1/K;</p>
<p>When connector <b>heatPort</b> is <b>not</b> connected, the temperature
dependent behaviour is switched off by setting heatPort.T = T_ref.
Additionally, the equation <tt>heatPort.Q_flow = 0</tt> is implicitly present
due to a special rule in Modelica that flow variables of not connected
connectors are set to zero.</p>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 2002   </i>
       by Anton Haumer<br> initially implemented<br>
       </li>
</ul>
</html>"));
    Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort annotation(Placement(visible=true, transformation(origin={0,-99.53}, extent={{-10,-10},{10,10}}, rotation=-90), iconTransformation(origin={-0.63,-99.53}, extent={{-10,-10},{10,10}}, rotation=-90)));
  equation 
    v=R*i;
    if cardinality(heatPort) > 0 then
      R=R_ref*(1 + alpha*(heatPort.T - T_ref));
      heatPort.Q_flow=-v*i;
    else
      R=R_ref;
      heatPort.T=T_ref;
    end if;
  end HeatingResistor;

  model Conductor "Ideal linear electrical conductor"
    extends Interfaces.OnePort;
    parameter SI.Conductance G=1 "Conductance";
    annotation(Documentation(info="<HTML>
<P>
The linear conductor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by <i>i = v*G</i>.
The Conductance <i>G</i> is allowed to be positive, zero, or negative.
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-30},{70,30}}),Rectangle(visible=true, lineColor={0,0,255}, extent={{-70,-30},{70,30}}),Line(visible=true, points={{-90,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{70,0},{90,0}}, color={0,0,255}),Text(visible=true, extent={{-138,-100},{140,-60}}, textString="G=%G", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, extent={{-140,40},{142,100}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-96,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{70,0},{96,0}}, color={0,0,255}),Rectangle(visible=true, lineColor={0,0,255}, extent={{-70,-30},{70,30}})}));
  equation 
    i=G*v;
  end Conductor;

  model Capacitor "Ideal linear electrical capacitor"
    extends Interfaces.OnePort;
    parameter SI.Capacitance C=1 "Capacitance";
    annotation(Documentation(info="<HTML>
<p>
The linear capacitor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by <i>i = C * dv/dt</i>.
The Capacitance <i>C</i> is allowed to be positive, zero, or negative.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-14,28},{-14,-28}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{14,28},{14,-28}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{-90,0},{-14,0}}, color={0,0,255}),Line(visible=true, points={{14,0},{90,0}}, color={0,0,255}),Text(visible=true, extent={{-136,-100},{136,-60}}, textString="C=%C", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, extent={{-142,40},{140,100}}, textString="%name", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-20,40},{-20,-40}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{20,40},{20,-40}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{-96,0},{-20,0}}, color={0,0,255}),Line(visible=true, points={{20,0},{96,0}}, color={0,0,255})}));
  equation 
    i=C*der(v);
  end Capacitor;

  model Inductor "Ideal linear electrical inductor"
    extends Interfaces.OnePort;
    parameter SI.Inductance L=1 "Inductance";
    annotation(Documentation(info="<HTML>
<P>
The linear inductor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by  <i>v = L * di/dt</i>.
The Inductance <i>L</i> is allowed to be positive, zero, or negative.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-60,-15},{-30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{-30,-15},{0,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{0,-15},{30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{30,-15},{60,15}}, endAngle=180),Line(visible=true, points={{60,0},{96,0}}, color={0,0,255}),Line(visible=true, points={{-96,0},{-60,0}}, color={0,0,255})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-60,-15},{-30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{-30,-15},{0,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{0,-15},{30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{30,-15},{60,15}}, endAngle=180),Line(visible=true, points={{60,0},{90,0}}, color={0,0,255}),Line(visible=true, points={{-90,0},{-60,0}}, color={0,0,255}),Text(visible=true, extent={{-138,-102},{144,-60}}, textString="L=%L", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, extent={{-146,38},{148,100}}, textString="%name", fontName="Arial")}));
  equation 
    L*der(i)=v;
  end Inductor;

  model SaturatingInductor "Simple model of an inductor with saturation"
    extends Modelica.Electrical.Analog.Interfaces.OnePort;
    parameter Modelica.SIunits.Current Inom=1 "Nominal current";
    parameter Modelica.SIunits.Inductance Lnom=1 "Nominal inductance at Nominal current";
    parameter Modelica.SIunits.Inductance Lzer=2*Lnom "Inductance near current=0";
    parameter Modelica.SIunits.Inductance Linf=Lnom/2 "Inductance at large currents";
    Modelica.SIunits.Inductance Lact(start=Lzer, stateSelect=StateSelect.avoid);
    Modelica.SIunits.MagneticFlux Psi;
    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, extent={{-60.0,-15.0},{-30.0,15.0}}, endAngle=180),Ellipse(visible=true, extent={{-30.0,-15.0},{0.0,15.0}}, endAngle=180),Ellipse(visible=true, extent={{0.0,-15.0},{30.0,15.0}}, endAngle=180),Ellipse(visible=true, extent={{30.0,-15.0},{60.0,15.0}}, endAngle=180),Line(visible=true, points={{60.0,0.0},{90.0,0.0}}),Line(visible=true, points={{-90.0,0.0},{-60.0,0.0}}),Rectangle(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Sphere, extent={{-60.0,-10.0},{60.0,-20.0}}),Text(visible=true, fillColor={0,0,255}, extent={{-142.0,40.0},{148.0,102.0}}, textString="%name", fontName="Arial"),Text(visible=true, fillPattern=FillPattern.Solid, extent={{-150.0,-92.0},{150.0,-48.0}}, textString="Lnom=%Lnom", fontName="Arial")}), Documentation(info="<HTML>
<p>
This model approximates the behaviour of an inductor with the influence of saturation,
i.e. the value of the inductance depends on the current flowing through the inductor.
The inductance decreases as current increases.<br>
The parameters are:
<ul>
<li>Inom...nominal current</li>
<li>Lnom...nominal inductance at nominal current</li>
<li>Lzer...inductance near current = 0; Lzer has to be greater than Lnom</li>
<li>Linf...inductance at large currents; Linf has to be less than Lnom</li>
</ul>
</p>
</HTML>
", revisions="<html>
<dl>
<p>
  <dt><b>Main Author:</b></dt>
  <dd>
  <a href=\"http://www.haumer.at/\">Anton Haumer</a><br>
  Technical Consulting & Electrical Engineering<br>
  A-3423 St.Andrae-Woerdern<br>Austria<br>
  email: <a href=\"mailto:a.haumer@haumer.at\">a.haumer@haumer.at</a>
  </dd>
</p>
<p>
  <dt><b>Release Notes:</b></dt>
  <dd>
  <ul>
  <li> May 27, 2004: Implemented by Anton Haumer</li>
  </ul>
  </dd>
</dl>
</html>"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, extent={{-60,-15},{-30,15}}, endAngle=180),Ellipse(visible=true, extent={{-30,-15},{0,15}}, endAngle=180),Ellipse(visible=true, extent={{0,-15},{30,15}}, endAngle=180),Ellipse(visible=true, extent={{30,-15},{60,15}}, endAngle=180),Line(visible=true, points={{60,0},{96,0}}),Line(visible=true, points={{-96,0},{-60,0}}),Rectangle(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Sphere, extent={{-60,-10},{60,-20}})}));
  protected 
    parameter Modelica.SIunits.Current Ipar(start=Inom/10, fixed=false);
  initial equation 
    Lnom - Linf=(Lzer - Linf)*Ipar/Inom*(Modelica.Constants.pi/2 - atan(Ipar/Inom));
  equation 
    assert(Lzer > Lnom + Modelica.Constants.eps, "Lzer (= " + String(Lzer) + ") has to be > Lnom (= " + String(Lnom) + ")");
    assert(Linf < Lnom - Modelica.Constants.eps, "Linf (= " + String(Linf) + ") has to be < Lnom (= " + String(Lnom) + ")");
    (Lact - Linf)*i/Ipar=(Lzer - Linf)*noEvent(atan(i/Ipar));
    Psi=Lact*i;
    v=der(Psi);
  end SaturatingInductor;

  model Transformer "Transformer with two ports"
    extends Interfaces.TwoPort;
    parameter SI.Inductance L1=1 "Primary inductance";
    parameter SI.Inductance L2=1 "Secondary inductance";
    parameter SI.Inductance M=1 "Coupling inductance";
    annotation(Documentation(info="<HTML>
<p>The transformer is a two port. The left port voltage <i>v1</i>, left port current <i>i1</i>,
right port voltage <i>v2</i> and right port current <i>i2</i> are connected by the following
relation:</p>
<pre>         | v1 |         | L1   M  |  | i1' |
         |    |    =    |         |  |     |
         | v2 |         | M    L2 |  | i2' |</pre>
<p><i>L1</i>, <i>L2</i>, and <i>M</i> are the primary, secondary, and coupling inductances respectively.</p>
</html>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,0,255}, extent={{-100,68.94},{100,126.9}}, textString="%name", fontName="Arial"),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,-50},{-20,-25}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,-25},{-20,0}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,0},{-20,25}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,25},{-20,50}}, startAngle=-90, endAngle=90),Line(visible=true, points={{-90,50},{-32,50}}, color={0,0,255}),Line(visible=true, points={{-90,-50},{-32,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,-50},{45,-25}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,-25},{45,0}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,0},{45,25}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,25},{45,50}}, startAngle=90, endAngle=-90),Line(visible=true, points={{32,50},{90,50}}, color={0,0,255}),Line(visible=true, points={{32,-50},{90,-50}}, color={0,0,255}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-89,-10},{-60,18}}, textString="L1", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{64,-10},{90,18}}, textString="L2", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-18,-98},{20,-70}}, textString="M", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,-50},{-20,-25}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,-25},{-20,0}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,0},{-20,25}}, startAngle=-90, endAngle=90),Ellipse(visible=true, lineColor={0,0,255}, extent={{-45,25},{-20,50}}, startAngle=-90, endAngle=90),Line(visible=true, points={{-96,50},{-32,50}}, color={0,0,255}),Line(visible=true, points={{-96,-50},{-32,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,-50},{45,-25}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,-25},{45,0}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,0},{45,25}}, startAngle=90, endAngle=-90),Ellipse(visible=true, lineColor={0,0,255}, extent={{20,25},{45,50}}, startAngle=90, endAngle=-90),Line(visible=true, points={{32,50},{96,50}}, color={0,0,255}),Line(visible=true, points={{32,-50},{96,-50}}, color={0,0,255})}));
  equation 
    v1=L1*der(i1) + M*der(i2);
    v2=M*der(i1) + L2*der(i2);
  end Transformer;

  model Gyrator "Gyrator"
    extends Interfaces.TwoPort;
    parameter SI.Conductance G1=1 "Gyration conductance";
    parameter SI.Conductance G2=1 "Gyration conductance";
    annotation(Documentation(info="<HTML>
<P>
A gyrator is a two-port element defined by the following equations:
</P>
<PRE>
    i1 =  G2 * v2
    i2 = -G1 * v1
</PRE>
<P>
where the constants <i>G1</i>, <i>G2</i> are called the gyration conductance.
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, extent={{-60,-60},{60,60}}),Line(visible=true, points={{-96,50},{-60,50}}, color={0,0,255}),Line(visible=true, points={{-96,-50},{-60,-50}}, color={0,0,255}),Line(visible=true, points={{60,50},{96,50}}, color={0,0,255}),Line(visible=true, points={{60,-50},{96,-50}}, color={0,0,255}),Line(visible=true, points={{-40,30},{40,30}}, color={0,0,255}),Line(visible=true, points={{-21,-22},{19,-22}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{30,34},{40,30},{30,26},{30,34}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{-30,-22.5},{-20,-18.5},{-20,-26.5},{-30,-22.5}}),Line(visible=true, points={{-4,5},{-6,-5}}, color={0,0,255}, thickness=1),Line(visible=true, points={{3,5},{1,-5}}, color={0,0,255}, thickness=1),Line(visible=true, points={{-8,5},{7,5}}, color={0,0,255}, thickness=1),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-20,35.34},{20,50.34}}, textString="G1", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-20,-45},{20,-30}}, textString="G2", fontName="Arial")}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-60,-60},{60,60}}),Line(visible=true, points={{-90,50},{-60,50}}, color={0,0,255}),Line(visible=true, points={{-90,-50},{-60,-50}}, color={0,0,255}),Line(visible=true, points={{60,50},{90,50}}, color={0,0,255}),Line(visible=true, points={{60,-50},{90,-50}}, color={0,0,255}),Line(visible=true, points={{-40,30},{40,30}}, color={0,0,255}),Line(visible=true, points={{-20,-20},{20,-20}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{30,34},{40,30},{30,26},{30,34}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{-26,-19},{-16,-15},{-16,-23},{-26,-19}}),Line(visible=true, points={{-5,10},{-10,-10}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{9,10},{4,-9}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{-14,9},{16,10}}, color={0,0,255}, thickness=0.5),Text(visible=true, fillColor={0,0,255}, extent={{-100,69},{100,130}}, textString="%name", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-29,30},{30,59}}, textString="G1", fontName="Arial"),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-29,-58},{29,-29}}, textString="G2", fontName="Arial")}));
  equation 
    i1=G2*v2;
    i2=-G1*v1;
  end Gyrator;

  model EMF "Electromotoric force (electric/mechanic transformer)"
    parameter Real k(final unit="N.m/A")=1 "Transformation coefficient";
    SI.Voltage v "Voltage drop between the two pins";
    SI.Current i "Current flowing from positive to negative pin";
    SI.AngularVelocity w "Angular velocity of flange_b";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{0,90},{0,40}}, color={0,0,255}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{40,-10},{100,10}}),Ellipse(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-40,-40},{40,40}}),Line(visible=true, points={{0,-90},{0,-40}}, color={0,0,255}),Text(visible=true, fillColor={0,0,255}, extent={{20,-100},{100,-40}}, textString="%name", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{30,40},{119,100}}, textString="k=%k", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-17,95},{-20,85},{-23,95},{-17,95}}),Line(visible=true, points={{-20,110},{-20,85}}, color={160,160,160}),Text(visible=true, fillColor={160,160,160}, extent={{-40,90},{-30,110}}, textString="i", fontName="Arial"),Line(visible=true, points={{9,75},{19,75}}, color={192,192,192}),Line(visible=true, points={{0,96},{0,40}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-40,-40},{40,40}}),Rectangle(visible=true, fillColor={192,192,192}, fillPattern=FillPattern.HorizontalCylinder, extent={{40,-10},{96,10}}),Line(visible=true, points={{-20,-110},{-20,-85}}, color={160,160,160}),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{-17,-100},{-20,-110},{-23,-100},{-17,-100}}),Text(visible=true, fillColor={160,160,160}, extent={{-40,-110},{-30,-90}}, textString="i", fontName="Arial"),Line(visible=true, points={{8,-79},{18,-79}}, color={192,192,192}),Line(visible=true, points={{0,-96},{0,-40}}, color={0,0,255}),Line(visible=true, points={{14,80},{14,70}}, color={192,192,192}),Line(visible=true, points={{140,0},{110,0}}),Text(visible=true, extent={{114,-14},{148,-4}}, textString="flange_b.phi", fontName="Arial"),Polygon(visible=true, fillPattern=FillPattern.Solid, points={{140,3},{150,0},{140,-3},{140,3},{140,3}}),Text(visible=true, extent={{112,6},{148,16}}, textString="flange_b.tau", fontName="Arial"),Polygon(visible=true, lineColor={128,128,128}, fillColor={128,128,128}, fillPattern=FillPattern.Solid, points={{120,35},{100,40},{100,30},{120,35}}),Line(visible=true, points={{30,35},{101,35}}, color={128,128,128}),Text(visible=true, fillColor={128,128,128}, extent={{37,46},{105,59}}, textString="rotation axis", fontName="Arial")}), Documentation(info="<HTML>
<p>
EMF transforms electrical energy into rotational mechanical energy.
It is used as basic building block of an electrical motor. The mechanical
connector flange_b can be connected to elements of the
Modelica.Mechanics.Rotational library. flange_b.tau is the cut-torque,
flange_b.phi is the angle at the rotational connection.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Martin Otter<br> initially implemented<br>
       </li>
</ul>
</html>"));
    Interfaces.PositivePin p annotation(Placement(visible=true, transformation(origin={0,100}, extent={{-10,-10},{10,10}}, rotation=-90), iconTransformation(origin={0,100}, extent={{-10,-10},{10,10}}, rotation=-90)));
    Interfaces.NegativePin n annotation(Placement(visible=true, transformation(origin={0,-100}, extent={{-10,-10},{10,10}}, rotation=-90), iconTransformation(origin={0,-100}, extent={{-10,-10},{10,10}}, rotation=-90)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b annotation(Placement(visible=true, transformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{-10,-10},{10,10}}, rotation=0)));
  equation 
    v=p.v - n.v;
    0=p.i + n.i;
    i=p.i;
    w=der(flange_b.phi);
    k*w=v;
    flange_b.tau=-k*i;
  end EMF;

  model VCV "Linear voltage-controlled voltage source"
    extends Interfaces.TwoPort;
    parameter Real gain=1 "Voltage gain";
    annotation(Documentation(info="<HTML>
<p>
The linear voltage-controlled voltage source is a TwoPort.
The right port voltage v2 is controlled by the left port voltage v1
via
</p>
<pre>
    v2 = v1 * gain.
</pre>
<p>
The left port current is zero. Any voltage gain can be chosen.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-70},{70,70}}),Text(visible=true, fillColor={0,0,255}, extent={{-99,-129},{100,-79}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-90,50},{-30,50}}, color={0,0,255}),Line(visible=true, points={{-30,-50},{-90,-50}}, color={0,0,255}),Line(visible=true, points={{100,50},{30,50},{30,-50},{100,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{10,-20},{50,20}}),Line(visible=true, points={{-20,60},{20,60}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{20,60},{10,63},{10,57},{20,60}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-96,50},{-31,50}}, color={0,0,255}),Line(visible=true, points={{-30,-50},{-96,-50}}, color={0,0,255}),Line(visible=true, points={{96,50},{30,50},{30,-50},{96,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{10,-20},{50,20}}),Rectangle(visible=true, lineColor={0,0,255}, extent={{-70,-70},{70,70}}),Line(visible=true, points={{-20,60},{20,60}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{20,60},{10,63},{10,57},{20,60}})}));
  equation 
    v2=v1*gain;
    i1=0;
  end VCV;

  model VCC "Linear voltage-controlled current source"
    extends Interfaces.TwoPort;
    parameter SI.Conductance transConductance=1 "Transconductance";
    annotation(Documentation(info="<HTML>
<p>
The linear voltage-controlled current source is a TwoPort.
The right port current i2 is controlled by the left port voltage v1
via
</p>
<pre>
    i2 = v1 * transConductance.
</pre>
<p>
The left port current is zero. Any transConductance can be chosen.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-70},{70,70}}),Text(visible=true, fillColor={0,0,255}, extent={{-99,-129},{100,-80}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-90,50},{-30,50}}, color={0,0,255}),Line(visible=true, points={{-30,-50},{-90,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{10,-20},{50,20}}),Line(visible=true, points={{-20,60},{20,60}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{20,60},{10,63},{10,57},{20,60}}),Line(visible=true, points={{90,50},{30,50},{30,20}}, color={0,0,255}),Line(visible=true, points={{91,-50},{30,-50},{30,-20}}, color={0,0,255}),Line(visible=true, points={{10,0},{50,0}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-96,50},{-30,50}}, color={0,0,255}),Line(visible=true, points={{-30,-50},{-96,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{10,-20},{50,20}}),Rectangle(visible=true, lineColor={0,0,255}, extent={{-70,-70},{70,70}}),Line(visible=true, points={{-20,60},{20,60}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{20,60},{10,63},{10,57},{20,60}}),Line(visible=true, points={{96,50},{30,50},{30,20}}, color={0,0,255}),Line(visible=true, points={{96,-50},{30,-50},{30,-20}}, color={0,0,255}),Line(visible=true, points={{10,0},{50,0}}, color={0,0,255})}));
  equation 
    i2=v1*transConductance;
    i1=0;
  end VCC;

  model CCV "Linear current-controlled voltage source"
    extends Interfaces.TwoPort;
    parameter SI.Resistance transResistance=1 "Transresistance";
    annotation(Documentation(info="<HTML>
<p>
The linear current-controlled voltage source is a TwoPort.
The right port voltage v2 is controlled by the left port current i1
via
</p>
<pre>
    v2 = i1 * transResistance.
</pre>
<p>
The left port voltage is zero. Any transResistance can be chosen.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-70},{70,70}}),Text(visible=true, fillColor={0,0,255}, extent={{-99,-130},{100,-80}}, textString="%name", fontName="Arial"),Line(visible=true, points={{100,50},{30,50},{30,-50},{100,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{10,-20},{50,20}}),Line(visible=true, points={{-20,60},{20,60}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{20,60},{10,63},{10,57},{20,60}}),Line(visible=true, points={{-90,50},{-20,50},{-20,-50},{-90,-50}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{10,-20},{50,20}}),Rectangle(visible=true, lineColor={0,0,255}, extent={{-70,-70},{70,70}}),Line(visible=true, points={{-20,60},{20,60}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{20,60},{10,63},{10,57},{20,60}}),Line(visible=true, points={{96,50},{30,50},{30,-50},{96,-50}}, color={0,0,255}),Line(visible=true, points={{-96,50},{-30,50},{-30,-50},{-96,-50}}, color={0,0,255})}));
  equation 
    v2=i1*transResistance;
    v1=0;
  end CCV;

  model CCC "Linear current-controlled current source"
    extends Interfaces.TwoPort;
    parameter Real gain=1 "Current gain";
    annotation(Documentation(info="<HTML>
<p>
The linear current-controlled current source is a TwoPort.
The right port current i2 is controlled by the left port current i1
via
</p>
<pre>
    i2 = i1 * gain.
</pre>
<p>
The left port voltage is zero. Any current gain can be chosen.
</p>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 1998   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-70},{70,70}}),Text(visible=true, fillColor={0,0,255}, extent={{-104,-127},{97,-76}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-100,50},{-30,50},{-30,-50},{-100,-50}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{10,-20},{50,20}}),Line(visible=true, points={{-20,60},{20,60}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{20,60},{10,63},{10,57},{20,60}}),Line(visible=true, points={{90,50},{30,50},{30,20}}, color={0,0,255}),Line(visible=true, points={{91,-50},{30,-50},{30,-20}}, color={0,0,255}),Line(visible=true, points={{10,0},{50,0}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Ellipse(visible=true, lineColor={0,0,255}, extent={{10,-20},{50,20}}),Rectangle(visible=true, lineColor={0,0,255}, extent={{-70,-70},{70,70}}),Line(visible=true, points={{-20,60},{20,60}}, color={0,0,255}),Polygon(visible=true, lineColor={0,0,255}, fillColor={0,0,255}, fillPattern=FillPattern.Solid, points={{20,60},{10,63},{10,57},{20,60}}),Line(visible=true, points={{96,50},{30,50},{30,20}}, color={0,0,255}),Line(visible=true, points={{96,-50},{30,-50},{30,-20}}, color={0,0,255}),Line(visible=true, points={{10,0},{50,0}}, color={0,0,255}),Line(visible=true, points={{-96,50},{-30,50},{-30,-50},{-96,-50}}, color={0,0,255})}));
  equation 
    i2=i1*gain;
    v1=0;
  end CCC;

  model OpAmp "Simple nonideal model of an OpAmp with limitation"
    annotation(Documentation(info="<HTML>
<P>
The OpAmp is a simle nonideal model with a smooth out.v = f(vin) characteristic,
where \"vin = in_p.v - in_n.v\".
The characteristic is limited by VMax.v and VMin.v. Its slope at vin=0
is the parameter Slope, which must be positive. (Therefore, the absolute 
value of Slope is taken into calculation.)
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>  </i>
       </li>
<li><i> 2000   </i>
       by Christoph Clauss<br> initially implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,0,255}, extent={{-95,88},{115,146}}, textString="%name", fontName="Arial"),Polygon(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{60,0},{-60,70},{-60,-70},{60,0}}),Line(visible=true, points={{-45,-10},{-20,-10},{-14,-9},{-11,-7},{-9,7},{-6,9},{0,10},{20,10}}),Line(visible=true, points={{0,35},{0,80}}),Line(visible=true, points={{0,-35},{0,-80}}),Line(visible=true, points={{-90,50},{-60,50}}),Line(visible=true, points={{-90,-50},{-60,-50}}),Line(visible=true, points={{60,0},{90,0}}),Line(visible=true, points={{-48,32},{-28,32}}),Line(visible=true, points={{-39,-20},{-39,-41}}),Line(visible=true, points={{-50,-31},{-28,-31}})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Polygon(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, points={{60,0},{-60,70},{-60,-70},{60,0}}),Line(visible=true, points={{-45,-10},{-20,-10},{-14,-9},{-11,-7},{-9,7},{-6,9},{0,10},{20,10}}),Line(visible=true, points={{0,35},{0,70}}),Line(visible=true, points={{0,-35},{0,-70}}),Line(visible=true, points={{-96,50},{-60,50}}),Line(visible=true, points={{-96,-50},{-60,-50}}),Line(visible=true, points={{60,0},{96,0}}),Line(visible=true, points={{-55,50},{-45,50}}),Line(visible=true, points={{-50,-45},{-50,-55}}),Line(visible=true, points={{-55,-50},{-45,-50}}),Text(visible=true, fillColor={160,160,160}, extent={{-112,-93},{-91,-73}}, textString="in_p.i=0", fontName="Arial"),Polygon(visible=true, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid, points={{120,3},{110,0},{120,-3},{120,3}}),Line(visible=true, points={{111,0},{136,0}}, color={160,160,160}),Text(visible=true, fillColor={160,160,160}, extent={{118,2},{135,17}}, textString="i2", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{-111,60},{-85,80}}, textString="in_n.i=0", fontName="Arial"),Line(visible=true, points={{-100,-35},{-100,23},{-100,24}}, color={160,160,160}, arrow={Arrow.None,Arrow.Filled}),Text(visible=true, fillColor={160,160,160}, extent={{-97,-16},{-74,4}}, textString="vin", fontName="Arial")}));
    parameter Real Slope=1 "Slope of the out.v/vin characteristic at vin=0";
    SI.Voltage vin "input voltagae";
    Modelica.Electrical.Analog.Interfaces.PositivePin in_p "Positive pin of the input port" annotation(Placement(visible=true, transformation(origin={-100,-50}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={-100,-50}, extent={{-10,-10},{10,10}}, rotation=0)));
    Modelica.Electrical.Analog.Interfaces.NegativePin in_n "Negative pin of the input port" annotation(Placement(visible=true, transformation(origin={-100,50}, extent={{10,-10},{-10,10}}, rotation=0), iconTransformation(origin={-100,50}, extent={{10,-10},{-10,10}}, rotation=0)));
    Modelica.Electrical.Analog.Interfaces.PositivePin out "Output pin" annotation(Placement(visible=true, transformation(origin={100,0}, extent={{10,-10},{-10,10}}, rotation=0), iconTransformation(origin={100,0}, extent={{10,-10},{-10,10}}, rotation=0)));
    Modelica.Electrical.Analog.Interfaces.PositivePin VMax "Positive output voltage limitation" annotation(Placement(visible=true, transformation(origin={0,70}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={0,70}, extent={{-10,-10},{10,10}}, rotation=0)));
    Modelica.Electrical.Analog.Interfaces.NegativePin VMin "Negative output voltage limitation" annotation(Placement(visible=true, transformation(origin={0,-70}, extent={{-10,-10},{10,10}}, rotation=0), iconTransformation(origin={0,-70}, extent={{-10,-10},{10,10}}, rotation=0)));
  protected 
    Real f "auxiliary variable";
    Real absSlope;
  equation 
    in_p.i=0;
    in_n.i=0;
    VMax.i=0;
    VMin.i=0;
    vin=in_p.v - in_n.v;
    f=2/(VMax.v - VMin.v);
    absSlope=if Slope < 0 then -Slope else Slope;
    out.v=(VMax.v + VMin.v)/2 + absSlope*vin/(1 + absSlope*noEvent(if f*vin < 0 then -f*vin else f*vin));
  end OpAmp;

  model VariableResistor "Ideal linear electrical resistor with variable resistance"
    extends Modelica.Electrical.Analog.Interfaces.OnePort;
    annotation(Documentation(info="<HTML>
<P>
The linear resistor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by <br><br>
      <b> <i>i*R = v</i></b>
</P>
<P>
The Resistance <i>R</i> is given as input signal.
<P>
<b>Attention!!!</b><br>
  It is recommended that the R signal should not cross the zero value. Otherwise 
  depending on the surrounding circuit the probability of singularities is high. <br>
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>June 7, 2004   </i>
       by Christoph Clauss<br>changed, docu added<br>
       </li>
<li><i>April 30, 2004</i>
       by Anton Haumer<br>implemented.
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,0,255}, extent={{-148,-100},{144,-40}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-90,0},{-70,0}}, color={0,0,255}),Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-30},{70,30}}),Line(visible=true, points={{70,0},{90,0}}, color={0,0,255}),Line(visible=true, points={{0,90},{0,30}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-30},{70,30}}),Line(visible=true, points={{-96,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{0,90},{0,30}}, color={0,0,255}),Line(visible=true, points={{70,0},{96,0}}, color={0,0,255})}));
    Modelica.Blocks.Interfaces.RealInput R(redeclare type SignalType= Modelica.SIunits.Resistance ) annotation(Placement(visible=true, transformation(origin={0,110}, extent={{-20,-20},{20,20}}, rotation=-90), iconTransformation(origin={0,110}, extent={{-20,-20},{20,20}}, rotation=-90)));
  equation 
    v=R*i;
  end VariableResistor;

  model VariableConductor "Ideal linear electrical conductor with variable conductance"
    extends Modelica.Electrical.Analog.Interfaces.OnePort;
    annotation(Documentation(info="<HTML>
<P>
The linear conductor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by <br><br>
      <b> <i>i = G*v</i></b>
</P>
<P>
The Conductance <i>G</i> is given as input signal.
</P>
<P>
<b>Attention!!!</b><br>
  It is recommended that the G signal should not cross the zero value. Otherwise 
  depending on the surrounding circuit the probability of singularities is high. <br>
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>June 7, 2004   </i>
       by Christoph Clauss<br> implemented<br>
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,0,255}, extent={{-144,-102},{142,-40}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-90,0},{-70,0}}, color={0,0,255}),Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-30},{70,30}}),Line(visible=true, points={{70,0},{90,0}}, color={0,0,255}),Line(visible=true, points={{0,90},{0,30}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{0,90},{0,30}}, color={0,0,255}),Line(visible=true, points={{-96,0},{-70,0}}, color={0,0,255}),Line(visible=true, points={{70,0},{96,0}}, color={0,0,255}),Rectangle(visible=true, lineColor={0,0,255}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-70,-30},{70,30}})}));
    Modelica.Blocks.Interfaces.RealInput G(redeclare type SignalType= Modelica.SIunits.Conductance ) annotation(Placement(visible=true, transformation(origin={0,110}, extent={{-20,-20},{20,20}}, rotation=-90), iconTransformation(origin={0,110}, extent={{-20,-20},{20,20}}, rotation=-90)));
  equation 
    i=G*v;
  end VariableConductor;

  model VariableCapacitor "Ideal linear electrical capacitor with variable capacitance"
    extends Modelica.Electrical.Analog.Interfaces.OnePort;
    parameter Modelica.SIunits.Capacitance Cmin=Modelica.Constants.eps;
    Modelica.SIunits.ElectricCharge Q;
    annotation(Documentation(info="<HTML>
<P>
The linear capacitor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by <br><br>
      <b> <i>i = dQ/dt</i></b>  with <b><i>Q = C * v</i> </b>.
</P>
<P>
The capacitance <i>C</i> is given as input signal.
</P>
<P>
It is required that C &ge; 0, otherwise an 
assertion is raised. To avoid a variable index system,<br>
C = Cmin, if 0 &le; C &lt; Cmin, where
Cmin is a parameter with default value Modelica.Constants.eps.
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>June 7, 2004   </i>
       by Christoph Clauss<br>changed, docu added<br>
       </li>
<li><i>April 30, 2004</i>
       by Anton Haumer<br>implemented.
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,0,255}, extent={{-134,-100},{136,-40}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-90,0},{-14,0}}, color={0,0,255}),Line(visible=true, points={{14,0},{90,0}}, color={0,0,255}),Line(visible=true, points={{0,90},{0,30}}, color={0,0,255}),Line(visible=true, points={{-14,28},{-14,-28}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{14,28},{14,-28}}, color={0,0,255}, thickness=0.5)}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-96,0},{-14,0}}, color={0,0,255}),Line(visible=true, points={{14,0},{96,0}}, color={0,0,255}),Line(visible=true, points={{0,90},{0,30}}, color={0,0,255}),Line(visible=true, points={{-14,28},{-14,-28}}, color={0,0,255}, thickness=0.5),Line(visible=true, points={{14,28},{14,-28}}, color={0,0,255}, thickness=0.5)}));
    Modelica.Blocks.Interfaces.RealInput C(redeclare type SignalType= Modelica.SIunits.Capacitance ) annotation(Placement(visible=true, transformation(origin={0,110}, extent={{-20,-20},{20,20}}, rotation=-90), iconTransformation(origin={0,110}, extent={{-20,-20},{20,20}}, rotation=-90)));
  equation 
    assert(C >= 0, "Capacitance C (= " + String(C) + ") has to be >= 0!");
    Q=noEvent(max(C, Cmin))*v;
    i=der(Q);
  end VariableCapacitor;

  model VariableInductor "Ideal linear electrical inductor with variable inductance"
    extends Modelica.Electrical.Analog.Interfaces.OnePort;
    Modelica.SIunits.MagneticFlux Psi;
    parameter Modelica.SIunits.Inductance Lmin=Modelica.Constants.eps;
    annotation(Documentation(info="<HTML>
<P>
The linear inductor connects the branch voltage <i>v</i> with the
branch current <i>i</i> by <br><br>
      <b> <i>v = d Psi/dt </i></b>   with  <b><i>Psi = L * i </i></b>.
</P>
<P>
The inductance <i>L</i> is as input signal.
</P>
<P>
It is required that L &ge; 0, otherwise an 
assertion is raised. To avoid a variable index system,<br>
L = Lmin, if 0 &le; L &lt; Lmin, where
Lmin is a parameter with default value Modelica.Constants.eps.
</P>
</HTML>
", revisions="<html>
<ul>
<li><i>June 7, 2004   </i>
       by Christoph Clauss<br>changed, docu added<br>
       </li>
<li><i>April 30, 2004</i>
       by Anton Haumer<br>implemented.
       </li>
</ul>
</html>"), Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, fillColor={0,0,255}, extent={{-138,-100},{136,-40}}, textString="%name", fontName="Arial"),Line(visible=true, points={{-90,0},{-60,0}}, color={0,0,255}),Line(visible=true, points={{60,0},{90,0}}, color={0,0,255}),Line(visible=true, points={{0,90},{0,8}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-60,-15},{-30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{-30,-15},{0,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{0,-15},{30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{30,-15},{60,15}}, endAngle=180)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-96,0},{-60,0}}, color={0,0,255}),Line(visible=true, points={{0,90},{0,8}}, color={0,0,255}),Ellipse(visible=true, lineColor={0,0,255}, extent={{-60,-15},{-30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{-30,-15},{0,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{0,-15},{30,15}}, endAngle=180),Ellipse(visible=true, lineColor={0,0,255}, extent={{30,-15},{60,15}}, endAngle=180),Line(visible=true, points={{60,0},{96,0}}, color={0,0,255})}));
    Modelica.Blocks.Interfaces.RealInput L(redeclare type SignalType= Modelica.SIunits.Inductance ) annotation(Placement(visible=true, transformation(origin={0,108}, extent={{-20,-20},{20,20}}, rotation=-90), iconTransformation(origin={0,108}, extent={{-20,-20},{20,20}}, rotation=-90)));
  equation 
    assert(L >= 0, "Inductance L_ (= " + String(L) + ") has to be >= 0!");
    Psi=noEvent(max(L, Lmin))*i;
    v=der(Psi);
  end VariableInductor;

end Basic;
