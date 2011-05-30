within Modelica_LinearSystems2.Examples.StateSpace;
function analysisInitialResponse "Initial response example"

  import Modelica_LinearSystems2.StateSpace;

  annotation (interactive=true, Documentation(info="<html>
<p>
Computes and plots the step response
</html>"));

protected
  Modelica_LinearSystems2.StateSpace sc=Modelica_LinearSystems2.StateSpace(
      A=[-1,1; 0,-2],
      B=[1,0; 0,1],
      C=[1,0; 0,1],
      D=[0,0; 0,0]);

  Real t[:] "Time vector: (number of samples)";
 Real x_continuous[:,2,2]
    "State trajectories: (number of samples) x (number of states) x (number of inputs)";
 Real x0[2]=ones(2) "Initial state vector";

public
output Real y[:,size(sc.C, 1),size(sc.B, 2)]
    "Output response: (number of samples) x (number of outputs) x (number of inuputs)";

algorithm
 (y,t,x_continuous) := Modelica_LinearSystems2.StateSpace.Analysis.initialResponse(x0=x0,sc=sc,dt=0.1,tSpan=5);

 Modelica_LinearSystems2.Utilities.Plot.diagramVector({
       Modelica_LinearSystems2.Utilities.Plot.Records.Diagram(
                 curve={Modelica_LinearSystems2.Utilities.Plot.Records.Curve(
                          x=t,
                          y=y[:,1,1],
                          legend="y1"),
                          Modelica_LinearSystems2.Utilities.Plot.Records.Curve(
                          x=t,
                          y=y[:,1,2],
                          legend="y2")},
                 heading="Initial response to u1",
                 xLabel="time [s]",
                 yLabel="y1, y2"),
       Modelica_LinearSystems2.Utilities.Plot.Records.Diagram(
                 curve={Modelica_LinearSystems2.Utilities.Plot.Records.Curve(
                          x=t,
                          y=y[:,2,1],
                          legend="y1"),
                          Modelica_LinearSystems2.Utilities.Plot.Records.Curve(
                          x=t,
                          y=y[:,2,2],
                          legend="y2")},
                 heading="Initial response to u2",
                 xLabel="time [s]",
                 yLabel="y1, y2")});

end analysisInitialResponse;