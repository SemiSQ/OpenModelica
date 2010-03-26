within Modelica;
package Math "Mathematical functions (e.g., sin, cos) and operations on matrices (e.g., norm, solve, eig, exp)"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;
  annotation(preferedView="info", Invisible=true, Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-59,-56},{42,-9}}, textString="f(x)", fontName="Arial")}), Documentation(info="<HTML>
<p>
This package contains <b>basic mathematical functions</b> (such as sin(..)),
as well as functions operating on <b>matrices</b>.
</p>

<dl>
<dt><b>Main Author:</b>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
    Institut f&uuml;r Robotik und Mechatronik<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    Germany<br>
    email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
</dl>

<p>
Copyright &copy; 1998-2006, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b> 
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
</HTML>
", revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Function tempInterpol2 added.</li>
<li><i>Oct. 24, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Icons for icon and diagram level introduced.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>

</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  package Matrices "Functions on matrices"
    extends Modelica.Icons.Library;
    annotation(preferedView="info", version="0.8.1", versionDate="2004-08-21", Documentation(info="<HTML>
<h3><font color=\"#008000\">Library content</font></h3>
<p>
This library provides functions operating on matrices:
</p>
<table border=1 cellspacing=0 cellpadding=2>
  <tr><th><i>Function</i></th>
      <th><i>Description</i></th>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.norm\">norm</a>(A)</td>
      <td>1-, 2- and infinity-norm of matrix A</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.isEqual\">isEqual</a>(M1, M2)</td>
      <td>determines whether two matrices have the same size and elements</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.solve\">solve</a>(A,b)</td>
      <td>Solve real system of linear equations A*x=b with a b vector</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.leastSquares\">leastSquares</a>(A,b)</td>
      <td>Solve overdetermined or underdetermined real system of <br>
          linear equations A*x=b in a least squares sense</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.equalityLeastSquares\">equalityLeastSquares</a>(A,a,B,b)</td>
      <td>Solve a linear equality constrained least squares problem:<br>
          min|A*x-a|^2 subject to B*x=b</td>
  </tr>
  <tr><td>(LU,p,info) = <a href=\"Modelica:Modelica.Math.Matrices.LU\">LU</a>(A)</td>
      <td>LU decomposition of square or rectangular matrix</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.LU_solve\">LU_solve</a>(LU,p,b)</td>
      <td>Solve real system of linear equations P*L*U*x=b with a<br>
          b vector and an LU decomposition from \"LU(..)\"</td>
  </tr>
  <tr><td>(Q,R,p) = <a href=\"Modelica:Modelica.Math.Matrices.QR\">QR</a>(A)</td>
      <td> QR decomposition with column pivoting of rectangular matrix (Q*R = A[:,p]) </td>
  </tr>
  <tr><td>eval = <a href=\"Modelica:Modelica.Math.Matrices.eigenValues\">eigenValues</a>(A)<br>
          (eval,evec) = <a href=\"Modelica:Modelica.Math.Matrices.eigenValues\">eigenValues</a>(A)</td>
      <td> compute eigenvalues and optionally eigenvectors<br>
           for a real, nonsymmetric matrix </td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.eigenValueMatrix\">eigenValueMatrix</a>(eigen)</td>
      <td> return real valued block diagonal matrix J of eigenvalues of 
            matrix A (A=V*J*Vinv) </td>
  </tr>
  <tr><td>sigma = <a href=\"Modelica:Modelica.Math.Matrices.singularValues\">singularValues</a>(A)<br>
      (sigma,U,VT) = <a href=\"Modelica:Modelica.Math.Matrices.singularValues\">singularValues</a>(A)</td>
      <td> compute singular values and optionally left and right singular vectors </td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.det\">det</a>(A)</td>
      <td> determinant of a matrix (do <b>not</b> use; use rank(..))</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.inv\">inv</a>(A)</td>
      <td> inverse of a matrix </td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.rank\">rank</a>(A)</td>
      <td> rank of a matrix </td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.balance\">balance</a>(A)</td>
      <td>balance a square matrix to improve the condition</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Math.Matrices.exp\">exp</a>(A)</td>
      <td> compute the exponential of a matrix by adaptive Taylor series<br> 
           expansion with scaling and balancing</td>
  </tr>
  <tr><td>(P, G) = <a href=\"Modelica:Modelica.Math.Matrices.integralExp\">integralExp</a>(A,B)</td>
      <td> compute the exponential of a matrix and its integral</td>
  </tr>
  <tr><td>(P, G, GT) = <a href=\"Modelica:Modelica.Math.Matrices.integralExpT\">integralExpT</a>(A,B)</td>
      <td> compute the exponential of a matrix and two integrals</td>
  </tr>
</table>

<p>
Most functions are solely an interface to the external LAPACK library
(<a href=\"http://www.netlib.org/lapack\">http://www.netlib.org/lapack</a>).
The details of this library are described in:
</p>

<dl>
<dt>Anderson E., Bai Z., Bischof C., Blackford S., Demmel J., Dongarra J.,
    Du Croz J., Greenbaum A., Hammarling S., McKenney A., and Sorensen D.:</dt>
<dd> <b>Lapack Users' Guide</b>.
     Third Edition, SIAM, 1999.</dd>
</dl>


</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    function norm "Returns the norm of a matrix"
      extends Modelica.Icons.Function;
      input Real A[:,:] "Input matrix";
      input Real p(min=1)=2 "Type of p-norm (only allowed: 1, 2 or Modelica.Constants.inf)";
      output Real result=0.0 "p-norm of matrix A";
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Matrices.<b>norm</b>(A);
Matrices.<b>norm</b>(A, p=2);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
The function call \"<code>Matrices.norm(A)</code>\" returns the
2-norm of matrix A, i.e., the largest singular value of A.<br>
The function call \"<code>Matrices.norm(A, p)</code>\" returns the
p-norm of matrix A. The only allowed values for p are</p>
<ul>
<li> \"p=1\": the largest column sum of A</li>
<li> \"p=2\": the largest singular value of A</li> 
<li> \"p=Modelica.Constants.inf\": the largest row sum of A</li>
</ul>
<p>
Note, for any matrices A1, A2 the following inequality holds:
</p>
<blockquote><pre>
Matrices.<b>norm</b>(A1+A2,p) &le; Matrices.<b>norm</b>(A1,p) + Matrices.<b>norm</b>(A2,p)
</pre></blockquote>
<p>
Note, for any matrix A and vector v the following inequality holds:
</p>
<blockquote><pre>
Vectors.<b>norm</b>(A*v,p) &le; Matrices.<b>norm</b>(A,p)*Vectors.<b>norm</b>(A,p)
</pre></blockquote>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    algorithm 
      if p == 1 then 
        for i in 1:size(A, 2) loop
          result:=max(result, sum(abs(A[:,i])));
        end for;
      elseif p == 2 then
        result:=max(singularValues(A));

      elseif p == Modelica.Constants.inf then
        for i in 1:size(A, 1) loop
          result:=max(result, sum(abs(A[i,:])));
        end for;
      else
        assert(false, "Optional argument \"p\" of function \"norm\" must be 
1, 2 or Modelica.Constants.inf");
      end if;
    end norm;

    function isEqual "Compare whether two Real matrices are identical"
      extends Modelica.Icons.Function;
      input Real M1[:,:] "First matrix";
      input Real M2[:,:] "Second matrix (may have different size as M1";
      input Real eps(min=0)=0 "Two elements e1 and e2 of the two matrices are identical if abs(e1-e2) <= eps";
      output Boolean result "= true, if matrices have the same size and the same elements";
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Matrices.<b>isEqual</b>(M1, M2);
Matrices.<b>isEqual</b>(M1, M2, eps=0);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
The function call \"<code>Matrices.isEqual(M1, M2)</code>\" returns <b>true</b>, 
if the two Real matrices M1 and M2 have the same dimensions and 
the same elements. Otherwise the function
returns <b>false</b>. Two elements e1 and e2 of the two matrices
are checked on equality by the test \"abs(e1-e2) &le; eps\", where \"eps\"
can be provided as third argument of the function. Default is \"eps = 0\".
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  Real A1[2,2] = [1,2; 3,4];
  Real A2[3,2] = [1,2; 3,4; 5,6];
  Real A3[2,2] = [1,2, 3,4.0001];
  Boolean result;
<b>algorithm</b>
  result := Matrices.isEqual(M1,M2);     // = <b>false</b>
  result := Matrices.isEqual(M1,M3);     // = <b>false</b>
  result := Matrices.isEqual(M1,M1);     // = <b>true</b>
  result := Matrices.isEqual(M1,M3,0.1); // = <b>true</b>
</pre></blockquote>
<h3><font color=\"#008000\">See also</font></h3>
<a href=\"Modelica:Modelica.Vectors.isEqual\">Vectors.isEqual</a>, 
<a href=\"Modelica:Modelica.Strings.isEqual\">Strings.isEqual</a>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer nrow=size(M1, 1) "Number of rows of matrix M1";
      Integer ncol=size(M1, 2) "Number of columns of matrix M1";
      Integer i=1;
      Integer j;
    algorithm 
      result:=false;
      if size(M2, 1) == nrow and size(M2, 2) == ncol then 
        result:=true;
        while (i <= nrow) loop
          j:=1;
          while (j <= ncol) loop
            if abs(M1[i,j] - M2[i,j]) > eps then 
              result:=false;
              i:=nrow;
              j:=ncol;
            end if;
            j:=j + 1;
          end while;
          i:=i + 1;
        end while;
      end if;
    end isEqual;

    function solve "Solve real system of linear equations A*x=b with a b vector (Gaussian elemination with partial pivoting)"
      extends Modelica.Icons.Function;
      input Real A[:,size(A, 1)] "Matrix A of A*x = b";
      input Real b[size(A, 1)] "Vector b of A*x = b";
      output Real x[size(b, 1)] "Vector x such that A*x = b";
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Matrices.<b>solve</b>(A,b);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
This function call returns the
solution <b>x</b> of the linear system of equations
</p>
<blockquote>
<p>
<b>A</b>*<b>x</b> = <b>b</b>
</p>
</blockquote>
<p>
If a unique solution <b>x</b> does not exist (since <b>A</b> is singular),
an exception is raised.
</p>
<p>
Note, the solution is computed with the LAPACK function \"dgesv\",
i.e., by Gaussian elemination with partial pivoting.
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  Real A[3,3] = [1,2,3; 
                 3,4,5;
                 2,1,4];
  Real b[3] = {10,22,12};
  Real x[3];
<b>algorithm</b>
  x := Matrices.solve(A,b);  // x = {3,2,1}
</pre></blockquote>
<h3><font color=\"#008000\">See also</font></h3>
<a href=\"Modelica:Modelica.Math.Matrices.LU\">Matrices.LU</a>,
<a href=\"Modelica:Modelica.Math.Matrices.LU_solve\">Matrices.LU_solve</a>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer info;
    algorithm 
      (x,info):=LAPACK.dgesv_vec(A, b);
      assert(info == 0, "Solving a linear system of equations with function
\"Matrices.solve\" is not possible, because the system has either 
no or infinitely many solutions (A is singular).");
    end solve;

    function leastSquares "Solve overdetermined or underdetermined real system of linear equations A*x=b in a least squares sense (A may be rank deficient)"
      extends Modelica.Icons.Function;
      input Real A[:,:] "Matrix A";
      input Real b[size(A, 1)] "Vector b";
      output Real x[size(A, 2)] "Vector x such that min|A*x-b|^2 if size(A,1) >= size(A,2) or min|x|^2 and A*x=b, if size(A,1) < size(A,2)";
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
x = Matrices.<b>leastSquares</b>(A,b);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
A linear system of equations A*x = b has no solutions or infinitely
many solutions if A is not square. Function \"leastSquares\" returns
a solution in a least squarse sense:
</p>
<pre>
  size(A,1) &gt; size(A,2):  returns x such that |A*x - b|^2 is a minimum
  size(A,1) = size(A,2):  returns x such that A*x = b
  size(A,1) &lt; size(A,2):  returns x such that |x|^2 is a minimum for all 
                          vectors x that fulfill A*x = b
</pre>
<p>
Note, the solution is computed with the LAPACK function \"dgelsx\",
i.e., QR or LQ factorization of A with column pivoting. 
If A does not have full rank,
the solution is not unique and from the infinitely many solutions
the one is selected that minimizes both |x|^2 and |A*x - b|^2.
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer info;
      Integer rank;
      Real xx[max(size(A, 1), size(A, 2))];
    algorithm 
      (xx,info,rank):=LAPACK.dgelsx_vec(A, b, 100*Modelica.Constants.eps);
      x:=xx[1:size(A, 2)];
      assert(info == 0, "Solving an overdetermined or underdetermined linear system of 
equations with function \"Matrices.leastSquares\" failed.");
    end leastSquares;

    function equalityLeastSquares "Solve a linear equality constrained least squares problem"
      extends Modelica.Icons.Function;
      input Real A[:,:] "Minimize |A*x - a|^2";
      input Real a[size(A, 1)];
      input Real B[:,size(A, 2)] "subject to B*x=b";
      input Real b[size(B, 1)];
      output Real x[size(A, 2)] "solution vector";
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
x = Matrices.<b>equalityLeastSquares</b>(A,a,B,b);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
This function returns the
solution <b>x</b> of the linear equality-constrained least squares problem:
</p>
<blockquote>
<p>
min|<b>A</b>*<b>x</b> - <b>a</b>|^2 over <b>x</b>, subject to <b>B</b>*<b>x</b> = <b>b</b>
</p>
</blockquote>

<p>
It is required that the dimensions of A and B fulfill the following
relationship:
</p>

<blockquote>
size(B,1) &le; size(A,2) &le; size(A,1) + size(B,1)
</blockquote>

<p>
Note, the solution is computed with the LAPACK function \"dgglse\"
using the generalized RQ factorization under the assumptions that
B has full row rank (= size(B,1)) and the matrix [A;B] has
full column rank (= size(A,2)). In this case, the problem
has a unique solution.
</p>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer info;
    algorithm 
      assert(size(A, 2) >= size(B, 1) and size(A, 2) <= size(A, 1) + size(B, 1), "It is required that size(B,1) <= size(A,2) <= size(A,1) + size(B,1)\n" + "This relationship is not fulfilled, since the matrices are declared as:\n" + "  A[" + String(size(A, 1)) + "," + String(size(A, 2)) + "], B[" + String(size(B, 1)) + "," + String(size(B, 2)) + "]\n");
      (x,info):=LAPACK.dgglse_vec(A, a, B, b);
      assert(info == 0, "Solving a linear equality-constrained least squares problem 
with function \"Matrices.equalityLeastSquares\" failed.");
    end equalityLeastSquares;

    function LU "LU decomposition of square or rectangular matrix"
      extends Modelica.Icons.Function;
      input Real A[:,:] "Square or rectangular matrix";
      output Real LU[size(A, 1),size(A, 2)]=A "L,U factors (used with LU_solve(..))";
      output Integer pivots[min(size(A, 1), size(A, 2))] "pivot indices (used with LU_solve(..))";
      output Integer info "Information";
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));

      external "FORTRAN 77" dgetrf(size(A, 1),size(A, 2),LU,size(A, 1),pivots,info)       annotation(Library="Lapack");
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
(LU, pivots)       = Matrices.<b>LU</b>(A);
(LU, pivots, info) = Matrices.<b>LU</b>(A);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
This function call returns the
LU decomposition of a \"Real[m,n]\" matrix A, i.e.,
</p>
<blockquote>
<p>
<b>P</b>*<b>L</b>*<b>U</b> = <b>A</b>
</p>
</blockquote>
<p>
where <b>P</b> is a permutation matrix (implicitely
defined by vector <code>pivots</code>),
<b>L</b> is a lower triangular matrix with unit
diagonal elements (lower trapezoidal if m &gt; n), and
<b>U</b> is an upper triangular matrix (upper trapezoidal if m &lt; n).
Matrices <b>L</b> and <b>U</b> are stored in the returned
matrix <code>LU</code> (the diagonal of <b>L</b> is not stored).
With the companion function 
<a href=\"Modelica:Modelica.Math.Matrices.LU_solve\">Matrices.LU_solve</a>,
this decomposition can be used to solve
linear systems (<b>P</b>*<b>L</b>*<b>U</b>)*<b>x</b> = <b>b</b> with different right
hand side vectors <b>b</b>. If a linear system of equations with
just one right hand side vector <b>b</b> shall be solved, it is
more convenient to just use the function
<a href=\"Modelica:Modelica.Math.Matrices.solve\">Matrices.solve</a>.
</p>
<p>
The optional third (Integer) output argument has the following meaning:
<table border=0 cellspacing=0 cellpadding=2>
  <tr><td>info = 0:</td
      <td>successful exit</td></tr>
  <tr><td>info &gt; 0:</td>
      <td>if info = i, U[i,i] is exactly zero. The factorization
          has been completed, <br> 
          but the factor U is exactly
          singular, and division by zero will occur<br> if it is used
          to solve a system of equations.</td></tr>
</table>
</p>
<p>
The LU factorization is computed
with the LAPACK function \"dgetrf\",
i.e., by Gaussian elemination using partial pivoting
with row interchanges. Vector \"pivots\" are the
pivot indices, i.e., for 1 &le; i &le; min(m,n), row i of 
matrix A was interchanged with row pivots[i].
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  Real A[3,3] = [1,2,3; 
                 3,4,5;
                 2,1,4];
  Real b1[3] = {10,22,12};
  Real b2[3] = { 7,13,10};
  Real    LU[3,3];
  Integer pivots[3];
  Real    x1[3];
  Real    x2[3];
<b>algorithm</b>
  (LU, pivots) := Matrices.LU(A);
  x1 := Matrices.LU_solve(LU, pivots, b1);  // x1 = {3,2,1}
  x2 := Matrices.LU_solve(LU, pivots, b2);  // x2 = {1,0,2}
</pre></blockquote>
<h3><font color=\"#008000\">See also</font></h3>
<a href=\"Modelica:Modelica.Math.Matrices.LU_solve\">Matrices.LU_solve</a>, 
<a href=\"Modelica:Modelica.Math.Matrices.solve\">Matrices.solve</a>,
</HTML>"));
    end LU;

    function LU_solve "Solve real system of linear equations P*L*U*x=b with a b vector and an LU decomposition (from LU(..))"
      extends Modelica.Icons.Function;
      input Real LU[:,size(LU, 1)] "L,U factors of Matrices.LU(..) for a square matrix";
      input Integer pivots[size(LU, 1)] "Pivots indices of Matrices.LU(..)";
      input Real b[size(LU, 1)] "Right hand side vector of P*L*U*x=b";
      output Real x[size(b, 1)] "Solution vector such that P*L*U*x = b";
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Matrices.<b>LU_solve</b>(LU, pivots, b);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
This function call returns the
solution <b>x</b> of the linear systems of equations
</p>
<blockquote>
<p>
<b>P</b>*<b>L</b>*<b>U</b>*<b>x</b> = <b>b</b>;
</p>
</blockquote>
<p>
where <b>P</b> is a permutation matrix (implicitely
defined by vector <code>pivots</code>),
<b>L</b> is a lower triangular matrix with unit
diagonal elements (lower trapezoidal if m &gt; n), and
<b>U</b> is an upper triangular matrix (upper trapezoidal if m &lt; n).
The matrices of this decomposition are computed with function
<a href=\"Modelica:Modelica.Math.Matrices.LU\">Matrices.LU</a> that
returns arguments <code>LU</code> and <code>pivots</code>
used as input arguments of <code>Matrices.LU_solve</code>.
With <code>Matrices.LU</code> and <code>Matrices.LU_solve</code>
it is possible to efficiently solve linear systems
with different right hand side vectors. If a linear system of equations with
just one right hand side vector shall be solved, it is
more convenient to just use the function
<a href=\"Modelica:Modelica.Math.Matrices.solve\">Matrices.solve</a>.
</p>
<p>
If a unique solution <b>x</b> does not exist (since the 
LU decomposition is singular), an exception is raised.
</p>
<p>
The LU factorization is computed
with the LAPACK function \"dgetrf\",
i.e., by Gaussian elemination using partial pivoting
with row interchanges. Vector \"pivots\" are the
pivot indices, i.e., for 1 &le; i &le; min(m,n), row i of 
matrix A was interchanged with row pivots[i].
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  Real A[3,3] = [1,2,3; 
                 3,4,5;
                 2,1,4];
  Real b1[3] = {10,22,12};
  Real b2[3] = { 7,13,10};
  Real    LU[3,3];
  Integer pivots[3];
  Real    x1[3];
  Real    x2[3];
<b>algorithm</b>
  (LU, pivots) := Matrices.LU(A);
  x1 := Matrices.LU_solve(LU, pivots, b1);  // x1 = {3,2,1}
  x2 := Matrices.LU_solve(LU, pivots, b2);  // x2 = {1,0,2}
</pre></blockquote>
<h3><font color=\"#008000\">See also</font></h3>
<a href=\"Modelica:Modelica.Math.Matrices.LU\">Matrices.LU</a>, 
<a href=\"Modelica:Modelica.Math.Matrices.solve\">Matrices.solve</a>,
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    algorithm 
      for i in 1:size(LU, 1) loop
        assert(LU[i,i] <> 0, "Solving a linear system of equations with function
\"Matrices.LU_solve\" is not possible, since the LU decomposition
is singular, i.e., no unique solution exists.");
      end for;
      x:=LAPACK.dgetrs_vec(LU, pivots, b);
    end LU_solve;

    function QR "QR decomposition of a square matrix with column pivoting (A(:,p) = Q*R)"
      extends Modelica.Icons.Function;
      input Real A[:,:] "Rectangular matrix with size(A,1) >= size(A,2)";
      output Real Q[size(A, 1),size(A, 2)] "Rectangular matrix with orthonormal columns such that Q*R=A[:,p]";
      output Real R[size(A, 2),size(A, 2)] "Square upper triangular matrix";
      output Integer p[size(A, 2)] "Column permutation vector";
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
(Q,R,p) = Matrices.<b>QR</b>(A);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
This function returns the QR decomposition of
a rectangular matrix <b>A</b> (the number of columns of <b>A</b>
must be less than or equal to the number of rows):
</p>
<blockquote>
<p>
<b>Q</b>*<b>R</b> = <b>A</b>[:,<b>p</b>]
</p>
</blockquote>
<p>
where <b>Q</b> is a rectangular matrix that has orthonormal columns and
has the same size as A (<b>Q</b><sup>T</sup><b>Q</b>=<b>I</b>),
<b>R</b> is a square, upper triangular matrix and <b>p</b> is a permutation
vector. Matrix <b>R</b> has the following important properties:
</p>
<ul>
<li> The absolute value of a diagonal element of <b>R</b> is the largest
     value in this row, i.e.,
     abs(R[i,i]) &ge; abs(R[i,j]).</li>
<li> The diagonal elements of <b>R</b> are sorted according to size, such that
     the largest absolute value is abs(R[1,1]) and
     abs(R[i,i]) &ge; abs(R[j,j]) with i &lt; j. </li>
</ul>
<p>
This means that if abs(R[i,i]) &le; &epsilon; then abs(R[j,k]) &le; &epsilon;
for j &ge; i, i.e., the i-th row up to the last row of <b>R</b> have
small elements and can be treated as being zero. 
This allows to, e.g., estimate the row-rank
of <b>R</b> (which is the same row-rank as <b>A</b>). Furthermore,
<b>R</b> can be partitioned in two parts
</p>
<blockquote>
<pre>
   <b>A</b>[:,<b>p</b>] = <b>Q</b> * [<b>R</b><sub>1</sub>, <b>R</b><sub>2</sub>;
                 <b>0</b>,  <b>0</b>]
</pre>
</blockquote>
<p>
where <b>R</b><sub>1</sub> is a regular, upper triangular matrix. 
</p>
<p>
Note, the solution is computed with the LAPACK functions \"dgeqpf\"
and \"dorgqr\", i.e., by Housholder transformations with
column pivoting. If <b>Q</b> is not needed, the function may be
called as: <code>(,R,p) = QR(A)</code>.
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  Real A[3,3] = [1,2,3; 
                 3,4,5;
                 2,1,4];
  Real R[3,3];
<b>algorithm</b>
  (,R) := Matrices.QR(A);  // R = [-7.07.., -4.24.., -3.67..;
                                    0     , -1.73.., -0.23..;
                                    0     ,  0     ,  0.65..];
</pre></blockquote>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer nrow=size(A, 1);
      Integer ncol=size(A, 2);
      Real tau[ncol];
    algorithm 
      assert(nrow >= ncol, "\nInput matrix A[" + String(nrow) + "," + String(ncol) + "] has more columns as rows.
This is not allowed when calling Modelica.Matrices.QR(A).");
      (Q,tau,p):=LAPACK.dgeqpf(A);
      R:=zeros(ncol, ncol);
      for i in 1:ncol loop
        for j in i:ncol loop
          R[i,j]:=Q[i,j];
        end for;
      end for;
      Q:=LAPACK.dorgqr(Q, tau);
    end QR;

    function eigenValues "Compute eigenvalues and eigenvectors for a real, nonsymmetric matrix"
      extends Modelica.Icons.Function;
      input Real A[:,size(A, 1)] "Matrix";
      output Real eigenvalues[size(A, 1),2] "Eigenvalues of matrix A (Re: first column, Im: second column)";
      output Real eigenvectors[size(A, 1),size(A, 2)] "Real-valued eigenvector matrix";
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
                eigenvalues = Matrices.<b>eigenValues</b>(A);
(eigenvalues, eigenvectors) = Matrices.<b>eigenValues</b>(A);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
This function call returns the eigenvalues and 
optionally the (right) eigenvectors of a square matrix 
<b>A</b>. The first column of \"eigenvalues\" contains the real and the
second column contains the imaginary part of the eigenvalues.
If the i-th eigenvalue has no imaginary part, then eigenvectors[:,i] is
the corresponding real eigenvector. If the i-th eigenvalue
has an imaginary part, then eigenvalues[i+1,:] is the conjugate complex
eigenvalue and eigenvectors[:,i] is the real and eigenvectors[:,i+1] is the
imaginary part of the eigenvector of the i-th eigenvalue.
With function 
<a href=\"Modelica:Modelica.Math.Matrices.eigenValueMatrix\">Matrices.eigenValueMatrix</a>,
a real block diagonal matrix is constructed from the eigenvalues 
such that 
</p>
<blockquote>
<pre>
A = eigenvectors * eigenValueMatrix(eigenvalues) * inv(eigenvectors)
</pre>
</blockquote>
<p>
provided the eigenvector matrix \"eigenvectors\" can be inverted
(an inversion is possible, if all eigenvalues are different
and no eigenvalue is zero).
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  Real A[3,3] = [1,2,3; 
                 3,4,5;
                 2,1,4];
  Real eval;
<b>algorithm</b>
  eval := Matrices.eigenValues(A);  // eval = [-0.618, 0; 
                                    //          8.0  , 0;
                                    //          1.618, 0];
</pre>
</blockquote>
<p>
i.e., matrix A has the 3 real eigenvalues -0.618, 8, 1.618.
</p>
</pre></blockquote>
<h3><font color=\"#008000\">See also</font></h3>
<a href=\"Modelica:Modelica.Math.Matrices.eigenValueMatrix\">Matrices.eigenValueMatrix</a>,
<a href=\"Modelica:Modelica.Math.Matrices.singularValues\">Matrices.singularValues</a>
</HTML>
"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer info;
      Boolean onlyEigenvalues=false;
    algorithm 
      if onlyEigenvalues then 
        (eigenvalues[:,1],eigenvalues[:,2],info):=LAPACK.dgeev_eigenValues(A);
        eigenvectors:=zeros(size(A, 1), size(A, 1));
      else
        (eigenvalues[:,1],eigenvalues[:,2],eigenvectors,info):=LAPACK.dgeev(A);
      end if;
      assert(info == 0, "Calculating the eigen values with function
\"Matrices.eigenvalues\" is not possible, since the
numerical algorithm does not converge.");
    end eigenValues;

    function eigenValueMatrix "Return real valued block diagonal matrix J of eigenvalues of matrix A (A=V*J*Vinv)"
      extends Modelica.Icons.Function;
      input Real eigenValues[:,2] "Eigen values from function eigenValues(..) (Re: first column, Im: second column)";
      output Real J[size(eigenValues, 1),size(eigenValues, 1)] "Real valued block diagonal matrix with eigen values (Re: 1x1 block, Im: 2x2 block)";
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Matrices.<b>eigenValueMatrix</b>(eigenvalues);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
The function call returns a block diagonal matrix <b>J</b>
from the the two-column matrix <code>eigenvalues</code>
(computed by function
<a href=\"Modelica:Modelica.Math.Matrices.eigenValues\">Matrices.eigenValues</a>).
Matrix <code>eigenvalues</code> must have the real part of the
eigenvalues in the first column and the imaginary part in the
second column. If an eigenvalue i has a vanishing imaginary
part, then <b>J</b>[i,i] = eigenvalues[i,1], i.e., the diagonal
element of <b>J</b> is the real eigenvalue. 
Otherwise, eigenvalue i and conjugate complex eigenvalue i+1
are used to construct a 2 by 2 diagonal block of <b>J</b>:
</p>
<blockquote>
<pre>
  J[i  , i]   := eigenvalues[i,1];
  J[i  , i+1] := eigenvalues[i,2];
  J[i+1, i]   := eigenvalues[i+1,2];
  J[i+1, i+1] := eigenvalues[i+1,1];
</pre>
</blockquote>
<h3><font color=\"#008000\">See also</font></h3>
<a href=\"Modelica:Modelica.Math.Matrices.eigenValues\">Matrices.eigenValues</a>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer n=size(eigenValues, 1);
      Integer i;
    algorithm 
      J:=zeros(n, n);
      i:=1;
      while (i <= n) loop
        if eigenValues[i,2] == 0 then 
          J[i,i]:=eigenValues[i,1];
          i:=i + 1;
        else
          J[i,i]:=eigenValues[i,1];
          J[i,i + 1]:=eigenValues[i,2];
          J[i + 1,i]:=eigenValues[i + 1,2];
          J[i + 1,i + 1]:=eigenValues[i + 1,1];
          i:=i + 2;
        end if;
      end while;
    end eigenValueMatrix;

    function singularValues "Compute singular values and left and right singular vectors"
      extends Modelica.Icons.Function;
      input Real A[:,:] "Matrix";
      output Real sigma[min(size(A, 1), size(A, 2))] "Singular values";
      output Real U[size(A, 1),size(A, 1)]=zeros(size(A, 1), size(A, 1)) "Left orthogonal matrix";
      output Real VT[size(A, 2),size(A, 2)]=zeros(size(A, 2), size(A, 2)) "Transposed right orthogonal matrix ";
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
         sigma = Matrices.<b>singularValues</b>(A);
(sigma, U, VT) = Matrices.<b>singularValues</b>(A);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
This function computes the singular values and optionally the
singular vectors of matrix A. Basically the singular
value decomposition of A is computed, i.e.,
</p>
<blockquote><pre>
<b>A</b> = <b>U</b> <b><font face=\"Symbol\">S</font></b> <b>V</b><sup>T</sup>
  = U*Sigma*VT
</blockquote></pre>
<p>
where <b>U </b>and <b>V</b> are orthogonal matrices (<b>UU</b><sup>T</sup>=<b>I,
</b><b>VV</b><sup>T</sup>=<b>I</b>). <b><font face=\"Symbol\">S
</font></b> = diag(<font face=\"Symbol\">s</font><sub>i</sub>) 
has the same size as matrix A with nonnegative diagonal elements 
in decreasing order and with all other elements zero
(<font face=\"Symbol\">s</font><sub>1</sub> is the largest element). The function
returns the singular values <font face=\"Symbol\">s</font><sub>i</sub>
in vector <tt>sigma</tt> and the orthogonal matrices in
matrices <tt>U</tt> and <tt>V</tt>.
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  A = [1, 2,  3,  4;
       3, 4,  5, -2;
      -1, 2, -3,  5];
  (sigma, U, VT) = singularValues(A);
  results in:
     sigma = {8.33, 6.94, 2.31}; 
  i.e.
     Sigma = [8.33,    0,    0, 0;
                 0, 6.94,    0, 0;
                 0,    0, 2.31, 0]
</pre></blockquote>
<h3><font color=\"#008000\">See also</font></h3>
<a href=\"Modelica:Modelica.Math.Matrices.eigenValues\">Matrices.eigenValues</a>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer info;
      Integer n=min(size(A, 1), size(A, 2)) "Number of singular values";
    algorithm 
      (sigma,U,VT,info):=Matrices.LAPACK.dgesvd(A);
      assert(info == 0, "The numerical algorithm to compute the
singular value decomposition did not converge");
    end singularValues;

    function det "Determinant of a matrix (computed by LU decomposition)"
      extends Modelica.Icons.Function;
      input Real A[:,size(A, 1)];
      output Real result "Determinant of matrix A";
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Real LU[size(A, 1),size(A, 1)];
      Integer pivots[size(A, 1)];
      annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Matrices.<b>det</b>(A);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
This function call returns the determinant of matrix A
computed by a LU decomposition.
Usally, this function should never be used, because
there are nearly always better numerical algorithms
as by computing the determinant. E.g., use function
<a href=\"Modelica:Modelica.Math.Matrices.rank\">Matrices.rank</a>
to compute the rank of a matrix.
<h3><font color=\"#008000\">See also</font></h3>
<a href=\"Modelica:Modelica.Math.Matrices.rank\">Matrices.rank</a>,
<a href=\"Modelica:Modelica.Math.Matrices.solve\">Matrices.solve</a>
</HTML>"));
    algorithm 
      (LU,pivots):=Matrices.LU(A);
      result:=product(LU[i,i] for i in 1:size(A, 1))*product(if pivots[i] == i then 1 else -1 for i in 1:size(pivots, 1));
    end det;

    function inv "Inverse of a matrix (try to avoid, use function solve(..) instead)"
      extends Modelica.Icons.Function;
      input Real A[:,size(A, 1)];
      output Real invA[size(A, 1),size(A, 2)] "Inverse of matrix A";
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer info;
      Integer pivots[size(A, 1)] "Pivot vector";
      Real LU[size(A, 1),size(A, 2)] "LU factors of A";
    algorithm 
      (LU,pivots,info):=LAPACK.dgetrf(A);
      assert(info == 0, "Calculating an inverse matrix with function
\"Matrices.inv\" is not possible, since matrix A is singular.");
      invA:=LAPACK.dgetri(LU, pivots);
      annotation(Documentation(info="<html>
  
</html>"));
    end inv;

    function rank "Rank of a matrix (computed with singular values)"
      extends Modelica.Icons.Function;
      input Real A[:,:] "Matrix";
      input Real eps=0 "If eps > 0, the singular values are checked against eps; otherwise eps=max(size(A))*norm(A)*Modelica.Constants.eps is used";
      output Integer result "Rank of matrix A";
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer n=min(size(A, 1), size(A, 2));
      Integer i=n;
      Real sigma[n]=singularValues(A) "Singular values";
      Real eps2=if eps > 0 then eps else max(size(A))*sigma[1]*Modelica.Constants.eps;
    algorithm 
      result:=n;
      while (i > 0) loop
        if sigma[i] > eps2 then 
          result:=i;
          i:=0;
        end if;
        i:=i - 1;
      end while;
      annotation(Documentation(info="<html>
  
</html>"));
    end rank;

    function balance "Balancing of matrix A to improve the condition of A"
      extends Modelica.Icons.Function;
      input Real A[:,size(A, 1)];
      output Real D[size(A, 1)] "diagonal(D)=T is transformation matrix, such that
          T*A*inv(T) has smaller condition as A";
      output Real B[size(A, 1),size(A, 1)] "Balanced matrix (= diagonal(D)*A*inv(diagonal(D)))";
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer na=size(A, 1);
      Integer radix=2 "Radix of exponent representation must be 'radix'
          or a multiple of 'radix'";
      Integer radix2=radix*radix;
      Boolean noconv=true;
      Integer i=1;
      Integer j=1;
      Real CO;
      Real RO;
      Real G;
      Real F;
      Real S;
      annotation(Documentation(info="<HTML>
<p>
The function transformates the matrix A, so that the norm of the i-th column
is nearby the i-th row. (D,B)=Matrices.balance(A) returns a vector D, such
that B=inv(diagonal(D))*A*diagonal(D) has better condition. The elements of D 
are multiples of 2. Balancing attempts to make the norm of each row equal to the
norm of the belonging column. <br>
Balancing is used to minimize roundoff errors inducted
through large matrix calculations like Taylor-series approximation
or computation of eigenvalues.
</p>
<b>Example:</b><br><br>
<pre>       - A = [1, 10,  1000; .01,  0,  10; .005,  .01,  10]
       - Matrices.norm(A, 1);
         = 1020.0
       - (T,B)=Matrices.balance(A)
       - T
         = {256, 16, 0.5}
       - B
         =  [1,     0.625,   1.953125;
             0.16,  0,       0.3125;
             2.56,  0.32,   10.0]
       - Matrices.norm(B, 1);
         = 12.265625
</pre>
<p>
The Algorithm is taken from
<dl>
<dt>H. D. Joos, G. Grbel:
<dd><b>RASP'91 Regulator Analysis and Synthesis Programs</b><br>
    DLR - Control Systems Group 1991
</dl>
which based on the balanc function from EISPACK.
</p>

</HTML>
", revisions="<html>
<p><b>Release Notes:</b></p>
<li><i>July 5, 2002</i>
       by H. D. Joos and Nico Walther<br>
       Implemented.
</li>
</html>"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
    algorithm 
      D:=ones(na);
      B:=A;
      while (noconv) loop
        noconv:=false;
        for i in 1:na loop
          CO:=sum(abs(B[:,i])) - abs(B[i,i]);
          RO:=sum(abs(B[i,:])) - abs(B[i,i]);
          G:=RO/radix;
          F:=1;
          S:=CO + RO;
          while (not (CO >= G or CO == 0)) loop
            F:=F*radix;
            CO:=CO*radix2;
          end while;
          G:=RO*radix;
          while (not (CO < G or RO == 0)) loop
            F:=F/radix;
            CO:=CO/radix2;
          end while;
          if not (CO + RO)/F >= 0.95*S then 
            G:=1/F;
            D[i]:=D[i]*F;
            B[i,:]:=B[i,:]*G;
            B[:,i]:=B[:,i]*F;
            noconv:=true;
          end if;
        end for;
      end while;
    end balance;

    function exp "Compute the exponential of a matrix by adaptive Taylor series expansion with scaling and balancing"
      extends Modelica.Icons.Function;
      input Real A[:,size(A, 1)];
      input Real T=1;
      output Real phi[size(A, 1),size(A, 1)] "= exp(A*T)";
      annotation(Documentation(info="<HTML>
<p>This function computes</p>
<pre>                            (<b>A</b>T)^2   (<b>A</b>T)^3 
     <font size=4> <b>&Phi;</b></font> = e^(<b>A</b>T) = <b>I</b> + <b>A</b>T + ------ + ------ + ....
                              2!       3!
</pre>
<p>where e=2.71828..., <b>A</b> is an n x n matrix with real elements and T is a real number, 
e.g., the sampling time.
<b>A</b> may be singular. With the exponential of a matrix it is, e.g., possible
to compute the solution of a linear system of differential equations</p>
<pre>    der(<b>x</b>) = <b>A</b>*<b>x</b>   ->   <b>x</b>(t0 + T) = e^(<b>A</b>T)*x(t0) 
</pre>
<p>
The function is called as
<pre>     Phi = Matrices.exp(A,T);</pre>
or 
<pre>       M = Matrices.exp(A);
</pre>
what calculates M as the exponential of matrix A.
</p>
<p><b>Algorithmic details:</b></p>
<p>The algorithm is taken from </p>
<dl>
<dt>H. D. Joos, G. Gruebel:
<dd><b>RASP'91 Regulator Analysis and Synthesis Programs</b><br>
    DLR - Control Systems Group 1991
</dl>
<p>The following steps are performed to calculate the exponential of A:</p>
<ol>
  <li>Matrix <b>A</b> is balanced <br>
  (= is transformed with a diagonal matrix <b>D</b>, such that inv(<b>D</b>)*<b>A</b>*<b>D</b> 
  has a smaller condition as <b>A</b>).</li>
  <li>The scalar T is divided by a multiple of 2 such that norm(
       inv(<b>D</b>)*<b>A</b>*<b>D</b>*T/2^k ) &lt; 0.5. Note, that (1) and (2) are implemented such that no round-off errors 
  are introduced.</li>
  <li>The matrix from (2) is approximated by explicitly performing the Taylor 
  series expansion with a variable number of terms. 
  Truncation occurs if a new term does no longer contribute to the value of <b>&Phi;</b>
  from the previous iteration.</li>
  <li>The resulting matrix is transformed back, by reverting the steps of (2) 
  and (1).</li>
</ol>
<p>In several sources it is not recommended to use Taylor series expansion to 
calculate the exponential of a matrix, such as in 'C.B. Moler and C.F. Van Loan: 
Nineteen dubious ways to compute the exponential of a matrix. SIAM Review 20, 
pp. 801-836, 1979' or in the documentation of m-file expm2 in Matlab version 6 
(http://www.MathWorks.com) where it is stated that 'As a practical numerical 
method, this is often slow and inaccurate'. These statements are valid for a 
direct implementation of the Taylor series expansion, but <i>not</i> for the 
implementation variant used in this function. 
</p>

</HTML>
", revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>July 5, 2002</i>
       by H. D. Joos and Nico Walther<br>
       Implemented.
</li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      parameter Integer nmax=21;
      parameter Integer na=size(A, 1);
      Integer j=1;
      Integer k=0;
      Boolean done=false;
      Real Anorm;
      Real Tscaled=1;
      Real Atransf[na,na];
      Real D[na,na];
      Real M[na,na];
      Real Diag[na];
      encapsulated function columnNorm "Returns the column norm of a matrix"
        input Real A[:,:] "Input matrix";
        output Real result=0.0 "1-norm of matrix A";
      algorithm 
        for i in 1:size(A, 2) loop
          result:=max(result, sum(abs(A[:,i])));
        end for;
      end columnNorm;

    algorithm 
      (Diag,Atransf):=balance(A);
      Tscaled:=T;
      Anorm:=columnNorm(Atransf);
      Anorm:=Anorm*T;
      while (Anorm >= 0.5) loop
        Anorm:=Anorm/2;
        Tscaled:=Tscaled/2;
        k:=k + 1;
      end while;
      M:=identity(na);
      D:=M;
      while (j < nmax and not done) loop
        M:=Atransf*M*Tscaled/j;
        if columnNorm(D + M - D) == 0 then 
          done:=true;
        else
          D:=M + D;
          j:=j + 1;
        end if;
      end while;
      for i in 1:k loop
        D:=D*D;
      end for;
      for j in 1:na loop
        for k in 1:na loop
          phi[j,k]:=D[j,k]*Diag[j]/Diag[k];
        end for;
      end for;
    end exp;

    function integralExp "Computation of the transition-matrix phi and its integral gamma"
      extends Modelica.Icons.Function;
      input Real A[:,size(A, 1)];
      input Real B[size(A, 1),:];
      input Real T=1;
      output Real phi[size(A, 1),size(A, 1)] "= exp(A*T)";
      output Real gamma[size(A, 1),size(B, 2)] "= integral(phi)*B";
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      parameter Integer nmax=21;
      parameter Integer na=size(A, 1);
      Integer j=2;
      Integer k=0;
      Boolean done=false;
      Real Anorm;
      Real Tscaled=1;
      Real Atransf[na,na];
      Real Psi[na,na];
      Real M[na,na];
      Real Diag[na];
      annotation(Documentation(info="<HTML>
<p>
The function uses a Taylor series expansion with Balancing and
scaling/squaring to approximate the integral <b>&Psi;</b> of the matrix
exponential <b>&Phi;</b>=e^(AT):
</p>
<pre>                                 AT^2   A^2 * T^3          A^k * T^(k+1)
        <b>&Psi;</b> = int(e^(As))ds = IT + ---- + --------- + ... + --------------
                                  2!        3!                (k+1)!
</pre>
<p>
<b>&Phi;</b> is calculated through <b>&Phi;</b> = I + A*<b>&Psi;</b>, so A may be singular. <b>&Gamma;</b> is
simple <b>&Psi;</b>*B.
</p>
<p>The algorithm runs in the following steps: </p>
<ol>
  <li>Balancing</li>
  <li>Scaling</li>
  <li>Taylor series expansion</li>
  <li>Re-scaling</li>
  <li>Re-Balancing</li>
</ol>
<p>Balancing put the bad condition of a square matrix <i>A</i> into a diagonal
transformation matrix <i>D</i>. This reduce the effort of following calculations.
Afterwards the result have to be re-balanced by transformation D*A<small>transf</small>
 *inv(D).<br>
Scaling halfen T&nbsp; k-times, until the norm of A*T is less than 0.5. This
garantees minumum rounding errors in the following series
expansion. The re-scaling based on the equation&nbsp; exp(A*2T) = exp(AT)^2.
The needed re-scaling formula for psi thus becomes:</p>
<pre>         <b>&Phi;</b> = <b>&Phi;</b>'*<b>&Phi;</b>'
   I + A*<b>&Psi;</b> = I + 2A*<b>&Psi;</b>' + A^2*<b>&Psi;</b>'^2
         <b>&Psi;</b> = A*<b>&Psi;</b>'^2 + 2*<b>&Psi;</b>'
</pre>
<p>
where psi' is the scaled result from the series expansion while psi is the
re-scaled matrix.
</p>
<p>
The function is normally used to discretize a state-space system as the
zero-order-hold equivalent:
</p>
<pre>      x(k+1) = <b>&Phi;</b>*x(k) + <b>&Gamma;</b>*u(k)
        y(k) = C*x(k) + D*u(k)
</pre>
<p>
The zero-order-hold sampling, also known as step-invariant method, gives
exact values of the state variables, under the assumption that the control
signal u is constant between the sampling instants. Zero-order-hold sampling
is discribed in
</p>
<dl>
<dt>K. J. Astroem, B. Wittenmark:
<dd><b>Computer Controlled Systems - Theory and Design</b><br>
    Third Edition, p. 32
</dl>
<pre><b>Syntax:</b>
      (phi,gamma) = Matrices.expIntegral(A,B,T)
                       A,phi: [n,n] square matrices
                     B,gamma: [n,m] input matrix
                           T: scalar, e.g. sampling time
</pre>
<p>
The Algorithm to calculate psi is taken from
<dl>
<dt>H. D. Joos, G. Gruebel:
<dd><b>RASP'91 Regulator Analysis and Synthesis Programs</b><br>
    DLR - Control Systems Group 1991
</dl>
</p>

</HTML>
", revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>July 5, 2002</i>
       by H. D. Joos and Nico Walther<br>
       Implemented.
</li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
      encapsulated function columnNorm "Returns the column norm of a matrix"
        input Real A[:,:] "Input matrix";
        output Real result=0.0 "1-norm of matrix A";
      algorithm 
        for i in 1:size(A, 2) loop
          result:=max(result, sum(abs(A[:,i])));
        end for;
      end columnNorm;

    algorithm 
      (Diag,Atransf):=balance(A);
      Tscaled:=T;
      Anorm:=columnNorm(Atransf);
      Anorm:=Anorm*T;
      while (Anorm >= 0.5) loop
        Anorm:=Anorm/2;
        Tscaled:=Tscaled/2;
        k:=k + 1;
      end while;
      M:=identity(na)*Tscaled;
      Psi:=M;
      while (j < nmax and not done) loop
        M:=Atransf*M*Tscaled/j;
        if columnNorm(Psi + M - Psi) == 0 then 
          done:=true;
        else
          Psi:=M + Psi;
          j:=j + 1;
        end if;
      end while;
      for j in 1:k loop
        Psi:=Atransf*Psi*Psi + 2*Psi;
      end for;
      for j in 1:na loop
        for k in 1:na loop
          Psi[j,k]:=Psi[j,k]*Diag[j]/Diag[k];
        end for;
      end for;
      gamma:=Psi*B;
      phi:=A*Psi + identity(na);
    end integralExp;

    function integralExpT "Computation of the transition-matrix phi and the integral gamma and gamma1"
      extends Modelica.Icons.Function;
      input Real A[:,size(A, 1)];
      input Real B[size(A, 1),:];
      input Real T=1;
      output Real phi[size(A, 1),size(A, 1)] "= exp(A*T)";
      output Real gamma[size(A, 1),size(B, 2)] "= integral(phi)*B";
      output Real gamma1[size(A, 1),size(B, 2)] "= integral((T-t)*exp(A*t))*B";
      annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    protected 
      Integer nmax=200;
      parameter Integer na=size(A, 1);
      parameter Integer nb=size(B, 2);
      Integer j=1;
      Boolean done=false;
      Real F[na + 2*nb,na + 2*nb];
      annotation(Documentation(info="<HTML>
<p>
The function calculates the matrices phi,gamma,gamma1 through the equation:
</p>
<pre>                                 [ A B 0 ]
[phi gamma gamma1] = [I 0 0]*exp([ 0 0 I ]*T)
                                 [ 0 0 0 ]
</pre>
<pre>
<b>Syntax:</b><br>
      (phi,gamma,gamma1) = Matrices.ExpIntegral2(A,B,T)
                     A,phi: [n,n] square matrices
            B,gamma,gamma1: [n,m] matrices
                         T: scalar, e.g. sampling time
</pre>
<p>
The matrices define the discretized first-order-hold equivalent of
a state-space system:
<pre>      x(k+1) = phi*x(k) + gamma*u(k) + gamma1/T*(u(k+1) - u(k))
</pre>
The first-order-hold sampling, also known as ramp-invariant method, gives
more smooth control signals as the ZOH equivalent. First-order-hold sampling
is discribed in
<dl>
<dt>K. J. Astroem, B. Wittenmark:
<dd><b>Computer Controlled Systems - Theory and Design</b><br>
    Third Edition, p. 256
</dl>
</p>

</HTML>
", revisions="<html>
<p><b>Release Notes:</b></p>
<ul>
<li><i>July 31, 2002</i>
       by Nico Walther<br>
       Realized.
</li>
</ul>
</html>"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
    algorithm 
      F:=[A,B,zeros(na, nb);zeros(2*nb, na),zeros(2*nb, nb),[identity(nb);zeros(nb, nb)]];
      F:=exp(F, T);
      phi:=F[1:na,1:na];
      gamma:=F[1:na,na + 1:na + nb];
      gamma1:=F[1:na,na + nb + 1:na + 2*nb];
    end integralExpT;

  protected 
    package LAPACK "Interface to LAPACK library"
      extends Modelica.Icons.Library;
      function dgeev "Compute eigenvalues and (right) eigenvectors for real nonsymmetrix matrix A"
        extends Modelica.Icons.Function;
        input Real A[:,size(A, 1)];
        output Real eigenReal[size(A, 1)] "Real part of eigen values";
        output Real eigenImag[size(A, 1)] "Imaginary part of eigen values";
        output Real eigenVectors[size(A, 1),size(A, 1)] "Right eigen vectors";
        output Integer info;
      protected 
        Integer n=size(A, 1);
        Integer lwork=12*n;
        Real Awork[n,n]=A;
        Real work[lwork];
        annotation(Documentation(info="Lapack documentation
    Purpose   
    =======   
    DGEEV computes for an N-by-N real nonsymmetric matrix A, the   
    eigenvalues and, optionally, the left and/or right eigenvectors.   
    The right eigenvector v(j) of A satisfies   
                     A * v(j) = lambda(j) * v(j)   
    where lambda(j) is its eigenvalue.   
    The left eigenvector u(j) of A satisfies   
                  u(j)**H * A = lambda(j) * u(j)**H   
    where u(j)**H denotes the conjugate transpose of u(j).   
    The computed eigenvectors are normalized to have Euclidean norm   
    equal to 1 and largest component real.   
    Arguments   
    =========   
    JOBVL   (input) CHARACTER*1   
            = 'N': left eigenvectors of A are not computed;   
            = 'V': left eigenvectors of A are computed.   
    JOBVR   (input) CHARACTER*1   
            = 'N': right eigenvectors of A are not computed;   
            = 'V': right eigenvectors of A are computed.   
    N       (input) INTEGER   
            The order of the matrix A. N >= 0.   
    A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)   
            On entry, the N-by-N matrix A.   
            On exit, A has been overwritten.   
    LDA     (input) INTEGER   
            The leading dimension of the array A.  LDA >= max(1,N).   
    WR      (output) DOUBLE PRECISION array, dimension (N)   
    WI      (output) DOUBLE PRECISION array, dimension (N)   
            WR and WI contain the real and imaginary parts,   
            respectively, of the computed eigenvalues.  Complex   
            conjugate pairs of eigenvalues appear consecutively   
            with the eigenvalue having the positive imaginary part   
            first.   
    VL      (output) DOUBLE PRECISION array, dimension (LDVL,N)   
            If JOBVL = 'V', the left eigenvectors u(j) are stored one   
            after another in the columns of VL, in the same order   
            as their eigenvalues.   
            If JOBVL = 'N', VL is not referenced.   
            If the j-th eigenvalue is real, then u(j) = VL(:,j),   
            the j-th column of VL.   
            If the j-th and (j+1)-st eigenvalues form a complex   
            conjugate pair, then u(j) = VL(:,j) + i*VL(:,j+1) and   
            u(j+1) = VL(:,j) - i*VL(:,j+1).   
    LDVL    (input) INTEGER   
            The leading dimension of the array VL.  LDVL >= 1; if   
            JOBVL = 'V', LDVL >= N.   
    VR      (output) DOUBLE PRECISION array, dimension (LDVR,N)   
            If JOBVR = 'V', the right eigenvectors v(j) are stored one   
            after another in the columns of VR, in the same order   
            as their eigenvalues.   
            If JOBVR = 'N', VR is not referenced.   
            If the j-th eigenvalue is real, then v(j) = VR(:,j),   
            the j-th column of VR.   
            If the j-th and (j+1)-st eigenvalues form a complex   
            conjugate pair, then v(j) = VR(:,j) + i*VR(:,j+1) and   
            v(j+1) = VR(:,j) - i*VR(:,j+1).   
    LDVR    (input) INTEGER   
            The leading dimension of the array VR.  LDVR >= 1; if   
            JOBVR = 'V', LDVR >= N.   
    WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK) 
  
            On exit, if INFO = 0, WORK(1) returns the optimal LWORK.   
    LWORK   (input) INTEGER   
            The dimension of the array WORK.  LWORK >= max(1,3*N), and   
            if JOBVL = 'V' or JOBVR = 'V', LWORK >= 4*N.  For good   
            performance, LWORK must generally be larger.   
    INFO    (output) INTEGER   
            = 0:  successful exit   
            < 0:  if INFO = -i, the i-th argument had an illegal value.   
            > 0:  if INFO = i, the QR algorithm failed to compute all the 
                  eigenvalues, and no eigenvectors have been computed;   
                  elements i+1:N of WR and WI contain eigenvalues which   
                  have converged.   
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "Fortran 77" dgeev("N","V",n,Awork,n,eigenReal,eigenImag,eigenVectors,n,eigenVectors,n,work,size(work, 1),info)         annotation(Library="Lapack");

      end dgeev;

      function dgeev_eigenValues "Compute eigenvalues for real nonsymmetrix matrix A"
        extends Modelica.Icons.Function;
        input Real A[:,size(A, 1)];
        output Real EigenReal[size(A, 1)];
        output Real EigenImag[size(A, 1)];
        output Integer info;
      protected 
        Integer lwork=8*size(A, 1);
        Real Awork[size(A, 1),size(A, 1)]=A;
        Real work[lwork];
        Real EigenvectorsL[size(A, 1),size(A, 1)]=zeros(size(A, 1), size(A, 1));
        annotation(Documentation(info="Lapack documentation
    Purpose   
    =======   
    DGEEV computes for an N-by-N real nonsymmetric matrix A, the   
    eigenvalues and, optionally, the left and/or right eigenvectors.   
    The right eigenvector v(j) of A satisfies   
                     A * v(j) = lambda(j) * v(j)   
    where lambda(j) is its eigenvalue.   
    The left eigenvector u(j) of A satisfies   
                  u(j)**H * A = lambda(j) * u(j)**H   
    where u(j)**H denotes the conjugate transpose of u(j).   
    The computed eigenvectors are normalized to have Euclidean norm   
    equal to 1 and largest component real.   
    Arguments   
    =========   
    JOBVL   (input) CHARACTER*1   
            = 'N': left eigenvectors of A are not computed;   
            = 'V': left eigenvectors of A are computed.   
    JOBVR   (input) CHARACTER*1   
            = 'N': right eigenvectors of A are not computed;   
            = 'V': right eigenvectors of A are computed.   
    N       (input) INTEGER   
            The order of the matrix A. N >= 0.   
    A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)   
            On entry, the N-by-N matrix A.   
            On exit, A has been overwritten.   
    LDA     (input) INTEGER   
            The leading dimension of the array A.  LDA >= max(1,N).   
    WR      (output) DOUBLE PRECISION array, dimension (N)   
    WI      (output) DOUBLE PRECISION array, dimension (N)   
            WR and WI contain the real and imaginary parts,   
            respectively, of the computed eigenvalues.  Complex   
            conjugate pairs of eigenvalues appear consecutively   
            with the eigenvalue having the positive imaginary part   
            first.   
    VL      (output) DOUBLE PRECISION array, dimension (LDVL,N)   
            If JOBVL = 'V', the left eigenvectors u(j) are stored one   
            after another in the columns of VL, in the same order   
            as their eigenvalues.   
            If JOBVL = 'N', VL is not referenced.   
            If the j-th eigenvalue is real, then u(j) = VL(:,j),   
            the j-th column of VL.   
            If the j-th and (j+1)-st eigenvalues form a complex   
            conjugate pair, then u(j) = VL(:,j) + i*VL(:,j+1) and   
            u(j+1) = VL(:,j) - i*VL(:,j+1).   
    LDVL    (input) INTEGER   
            The leading dimension of the array VL.  LDVL >= 1; if   
            JOBVL = 'V', LDVL >= N.   
    VR      (output) DOUBLE PRECISION array, dimension (LDVR,N)   
            If JOBVR = 'V', the right eigenvectors v(j) are stored one   
            after another in the columns of VR, in the same order   
            as their eigenvalues.   
            If JOBVR = 'N', VR is not referenced.   
            If the j-th eigenvalue is real, then v(j) = VR(:,j),   
            the j-th column of VR.   
            If the j-th and (j+1)-st eigenvalues form a complex   
            conjugate pair, then v(j) = VR(:,j) + i*VR(:,j+1) and   
            v(j+1) = VR(:,j) - i*VR(:,j+1).   
    LDVR    (input) INTEGER   
            The leading dimension of the array VR.  LDVR >= 1; if   
            JOBVR = 'V', LDVR >= N.   
    WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK) 
  
            On exit, if INFO = 0, WORK(1) returns the optimal LWORK.   
    LWORK   (input) INTEGER   
            The dimension of the array WORK.  LWORK >= max(1,3*N), and   
            if JOBVL = 'V' or JOBVR = 'V', LWORK >= 4*N.  For good   
            performance, LWORK must generally be larger.   
    INFO    (output) INTEGER   
            = 0:  successful exit   
            < 0:  if INFO = -i, the i-th argument had an illegal value.   
            > 0:  if INFO = i, the QR algorithm failed to compute all the 
                  eigenvalues, and no eigenvectors have been computed;   
                  elements i+1:N of WR and WI contain eigenvalues which   
                  have converged.   
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "Fortran 77" dgeev("N","N",size(A, 1),Awork,size(A, 1),EigenReal,EigenImag,EigenvectorsL,size(EigenvectorsL, 1),EigenvectorsL,size(EigenvectorsL, 1),work,size(work, 1),info)         annotation(Library="Lapack");

      end dgeev_eigenValues;

      function dgels_vec "Solves overdetermined or underdetermined real linear equations A*x=b with a b vector"
        extends Modelica.Icons.Function;
        input Real A[:,:];
        input Real b[size(A, 1)];
        output Real x[nx]=cat(1, b, zeros(nx - nrow)) "solution is in first size(A,2) rows";
        output Integer info;
      protected 
        Integer nrow=size(A, 1);
        Integer ncol=size(A, 2);
        Integer nx=max(nrow, ncol);
        Integer lwork=min(nrow, ncol) + nx;
        Real work[lwork];
        Real Awork[nrow,ncol]=A;

        external "FORTRAN 77" dgels("N",nrow,ncol,1,Awork,nrow,x,nx,work,lwork,info)         annotation(Library="Lapack");
        annotation(Coordsys(extent=[-100,-100;100,100], grid=[2,2], component=[20,20]), Window(x=0.25, y=0.3, width=0.6, height=0.6), Documentation(info="Lapack documentation
  Purpose                                                                 
  =======                                                                 
                                                                          
  DGELS solves overdetermined or underdetermined real linear systems      
  involving an M-by-N matrix A, or its transpose, using a QR or LQ        
  factorization of A.  It is assumed that A has full rank.                
                                                                          
  The following options are provided:                                     
                                                                          
  1. If TRANS = 'N' and m >= n:  find the least squares solution of       
     an overdetermined system, i.e., solve the least squares problem      
                  minimize || B - A*X ||.                                 
                                                                          
  2. If TRANS = 'N' and m < n:  find the minimum norm solution of         
     an underdetermined system A * X = B.                                 
                                                                          
  3. If TRANS = 'T' and m >= n:  find the minimum norm solution of        
     an undetermined system A**T * X = B.                                 
                                                                          
  4. If TRANS = 'T' and m < n:  find the least squares solution of        
     an overdetermined system, i.e., solve the least squares problem      
                  minimize || B - A**T * X ||.                            
                                                                          
  Several right hand side vectors b and solution vectors x can be         
  handled in a single call; they are stored as the columns of the         
  M-by-NRHS right hand side matrix B and the N-by-NRHS solution           
  matrix X.                                                               
                                                                          
  Arguments                                                               
  =========                                                               
                                                                          
  TRANS   (input) CHARACTER                                               
          = 'N': the linear system involves A;                            
          = 'T': the linear system involves A**T.                         
                                                                          
  M       (input) INTEGER                                                 
          The number of rows of the matrix A.  M >= 0.                    
                                                                          
  N       (input) INTEGER                                                 
          The number of columns of the matrix A.  N >= 0.                 
                                                                          
  NRHS    (input) INTEGER                                                 
          The number of right hand sides, i.e., the number of             
          columns of the matrices B and X. NRHS >=0.                      
                                                                          
  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)        
          On entry, the M-by-N matrix A.                                  
          On exit,                                                        
            if M >= N, A is overwritten by details of its QR              
                       factorization as returned by DGEQRF;               
            if M <  N, A is overwritten by details of its LQ              
                       factorization as returned by DGELQF.               
                                                                          
  LDA     (input) INTEGER                                                 
          The leading dimension of the array A.  LDA >= max(1,M).         
                                                                          
  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)     
          On entry, the matrix B of right hand side vectors, stored       
          columnwise; B is M-by-NRHS if TRANS = 'N', or N-by-NRHS         
          if TRANS = 'T'.                                                 
          On exit, B is overwritten by the solution vectors, stored       
          columnwise:  if TRANS = 'N' and m >= n, rows 1 to n of B        
          contain the least squares solution vectors; the residual        
          sum of squares for the solution in each column is given by      
          the sum of squares of elements N+1 to M in that column;         
          if TRANS = 'N' and m < n, rows 1 to N of B contain the          
          minimum norm solution vectors;                                  
          if TRANS = 'T' and m >= n, rows 1 to M of B contain the         
          minimum norm solution vectors;                                  
          if TRANS = 'T' and m < n, rows 1 to M of B contain the          
          least squares solution vectors; the residual sum of squares     
          for the solution in each column is given by the sum of          
          squares of elements M+1 to N in that column.                    
                                                                          
  LDB     (input) INTEGER                                                 
          The leading dimension of the array B. LDB >= MAX(1,M,N).        
                                                                          
  WORK    (workspace) DOUBLE PRECISION array, dimension (LWORK)           
          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.        
                                                                          
  LWORK   (input) INTEGER                                                 
          The dimension of the array WORK.                                
          LWORK >= min(M,N) + MAX(1,M,N,NRHS).                            
          For optimal performance,                                        
          LWORK >= min(M,N) + MAX(1,M,N,NRHS) * NB                        
          where NB is the optimum block size.                             
                                                                          
  INFO    (output) INTEGER                                                
          = 0:  successful exit                                           
          < 0:  if INFO = -i, the i-th argument had an illegal value      
                                                                          "));
      end dgels_vec;

      function dgelsx_vec "Computes the minimum-norm solution to a real linear least squares problem with rank deficient A"
        extends Modelica.Icons.Function;
        input Real A[:,:];
        input Real b[size(A, 1)];
        input Real rcond=0.0 "Reciprocal condition number to estimate rank";
        output Real x[max(nrow, ncol)]=cat(1, b, zeros(max(nrow, ncol) - nrow)) "solution is in first size(A,2) rows";
        output Integer info;
        output Integer rank "Effective rank of A";
      protected 
        Integer nrow=size(A, 1);
        Integer ncol=size(A, 2);
        Integer nx=max(nrow, ncol);
        Integer lwork=max(min(nrow, ncol) + 3*ncol, 2*min(nrow, ncol) + 1);
        Real work[lwork];
        Real Awork[nrow,ncol]=A;
        Integer jpvt[ncol]=zeros(ncol);

        external "FORTRAN 77" dgelsx(nrow,ncol,1,Awork,nrow,x,nx,jpvt,rcond,rank,work,lwork,info)         annotation(Library="Lapack");
        annotation(Coordsys(extent=[-100,-100;100,100], grid=[2,2], component=[20,20]), Window(x=0.25, y=0.3, width=0.6, height=0.6), Documentation(info="Lapack documentation
  Purpose                                                               
  =======                                                               
                                                                        
  DGELSX computes the minimum-norm solution to a real linear least      
  squares problem:                                                      
      minimize || A * X - B ||                                          
  using a complete orthogonal factorization of A.  A is an M-by-N       
  matrix which may be rank-deficient.                                   
                                                                        
  Several right hand side vectors b and solution vectors x can be       
  handled in a single call; they are stored as the columns of the       
  M-by-NRHS right hand side matrix B and the N-by-NRHS solution         
  matrix X.                                                             
                                                                        
  The routine first computes a QR factorization with column pivoting:   
      A * P = Q * [ R11 R12 ]                                           
                  [  0  R22 ]                                           
  with R11 defined as the largest leading submatrix whose estimated     
  condition number is less than 1/RCOND.  The order of R11, RANK,       
  is the effective rank of A.                                           
                                                                        
  Then, R22 is considered to be negligible, and R12 is annihilated      
  by orthogonal transformations from the right, arriving at the         
  complete orthogonal factorization:                                    
     A * P = Q * [ T11 0 ] * Z                                          
                 [  0  0 ]                                              
  The minimum-norm solution is then                                     
     X = P * Z' [ inv(T11)*Q1'*B ]                                      
                [        0       ]                                      
  where Q1 consists of the first RANK columns of Q.                     
                                                                        
  Arguments                                                             
  =========                                                             
                                                                        
  M       (input) INTEGER                                               
          The number of rows of the matrix A.  M >= 0.                  
                                                                        
  N       (input) INTEGER                                               
          The number of columns of the matrix A.  N >= 0.               
                                                                        
  NRHS    (input) INTEGER                                               
          The number of right hand sides, i.e., the number of           
          columns of matrices B and X. NRHS >= 0.                       
                                                                        
  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)      
          On entry, the M-by-N matrix A.                                
          On exit, A has been overwritten by details of its             
          complete orthogonal factorization.                            
                                                                        
  LDA     (input) INTEGER                                               
          The leading dimension of the array A.  LDA >= max(1,M).       
                                                                        
  B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)   
          On entry, the M-by-NRHS right hand side matrix B.             
          On exit, the N-by-NRHS solution matrix X.                     
          If m >= n and RANK = n, the residual sum-of-squares for       
          the solution in the i-th column is given by the sum of        
          squares of elements N+1:M in that column.                     
                                                                        
  LDB     (input) INTEGER                                               
          The leading dimension of the array B. LDB >= max(1,M,N).      
                                                                        
  JPVT    (input/output) INTEGER array, dimension (N)                   
          On entry, if JPVT(i) .ne. 0, the i-th column of A is an       
          initial column, otherwise it is a free column.  Before        
          the QR factorization of A, all initial columns are            
          permuted to the leading positions; only the remaining         
          free columns are moved as a result of column pivoting         
          during the factorization.                                     
          On exit, if JPVT(i) = k, then the i-th column of A*P          
          was the k-th column of A.                                     
                                                                        
  RCOND   (input) DOUBLE PRECISION                                      
          RCOND is used to determine the effective rank of A, which     
          is defined as the order of the largest leading triangular     
          submatrix R11 in the QR factorization with pivoting of A,     
          whose estimated condition number < 1/RCOND.                   
                                                                        
  RANK    (output) INTEGER                                              
          The effective rank of A, i.e., the order of the submatrix     
          R11.  This is the same as the order of the submatrix T11      
          in the complete orthogonal factorization of A.                
                                                                        
  WORK    (workspace) DOUBLE PRECISION array, dimension                 
                      (max( min(M,N)+3*N, 2*min(M,N)+NRHS )),           
                                                                        
  INFO    (output) INTEGER                                              
          = 0:  successful exit                                         
          < 0:  if INFO = -i, the i-th argument had an illegal value    "));
      end dgelsx_vec;

      function dgesv "Solve real system of linear equations A*X=B with a B matrix"
        extends Modelica.Icons.Function;
        input Real A[:,size(A, 1)];
        input Real B[size(A, 1),:];
        output Real X[size(A, 1),size(B, 2)]=B;
        output Integer info;
      protected 
        Real Awork[size(A, 1),size(A, 1)]=A;
        Integer ipiv[size(A, 1)];
        annotation(Documentation(info="Lapack documentation:
    Purpose   
    =======   
    DGESV computes the solution to a real system of linear equations   
       A * X = B,   
    where A is an N-by-N matrix and X and B are N-by-NRHS matrices.   
    The LU decomposition with partial pivoting and row interchanges is   
    used to factor A as   
       A = P * L * U,   
    where P is a permutation matrix, L is unit lower triangular, and U is 
  
    upper triangular.  The factored form of A is then used to solve the   
    system of equations A * X = B.   
    Arguments   
    =========   
    N       (input) INTEGER   
            The number of linear equations, i.e., the order of the   
            matrix A.  N >= 0.   
    NRHS    (input) INTEGER   
            The number of right hand sides, i.e., the number of columns   
            of the matrix B.  NRHS >= 0.   
    A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)   
            On entry, the N-by-N coefficient matrix A.   
            On exit, the factors L and U from the factorization   
            A = P*L*U; the unit diagonal elements of L are not stored.   
    LDA     (input) INTEGER   
            The leading dimension of the array A.  LDA >= max(1,N).   
    IPIV    (output) INTEGER array, dimension (N)   
            The pivot indices that define the permutation matrix P;   
            row i of the matrix was interchanged with row IPIV(i).   
    B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)   
            On entry, the N-by-NRHS matrix of right hand side matrix B.   
            On exit, if INFO = 0, the N-by-NRHS solution matrix X.   
    LDB     (input) INTEGER   
            The leading dimension of the array B.  LDB >= max(1,N).   
    INFO    (output) INTEGER   
            = 0:  successful exit   
            < 0:  if INFO = -i, the i-th argument had an illegal value   
            > 0:  if INFO = i, U(i,i) is exactly zero.  The factorization 
  
                  has been completed, but the factor U is exactly   
                  singular, so the solution could not be computed.   
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "FORTRAN 77" dgesv(size(A, 1),size(B, 2),Awork,size(A, 1),ipiv,X,size(A, 1),info)         annotation(Library="Lapack");

      end dgesv;

      function dgesv_vec "Solve real system of linear equations A*x=b with a b vector"
        extends Modelica.Icons.Function;
        input Real A[:,size(A, 1)];
        input Real b[size(A, 1)];
        output Real x[size(A, 1)]=b;
        output Integer info;
      protected 
        Real Awork[size(A, 1),size(A, 1)]=A;
        Integer ipiv[size(A, 1)];
        annotation(Documentation(info="
Same as function LAPACK.dgesv, but right hand side is a vector and not a matrix.
For details of the arguments, see documentation of dgesv.
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "FORTRAN 77" dgesv(size(A, 1),1,Awork,size(A, 1),ipiv,x,size(A, 1),info)         annotation(Library="Lapack");

      end dgesv_vec;

      function dgesvx "Solve real system of linear equations A*X=B with a B matrix, error bounds and condition estimate"
        extends Modelica.Icons.Function;
        input Real A[:,size(A, 1)];
        input Real B[size(A, 1),:];
        output Real X[size(A, 1),size(B, 2)]=zeros(size(B, 1), size(B, 2));
        output Real RCond;
        output Real FErrBound;
        output Real BErrBound;
        output Integer info;
      protected 
        Real Awork[size(A, 1),size(A, 2)]=A;
        Real Bwork[size(B, 1),size(B, 2)]=B;
        Real AF[size(A, 1),size(A, 2)];
        Integer ipiv[size(A, 1)];
        String equed=StringAllocate(1);
        Real R[size(A, 1)];
        Real C[size(A, 1)];
        Real work[4*size(A, 1)];
        Integer iwork[size(A, 1)];
        annotation(Documentation(info="Lapack documentation:
    Purpose   
    =======   
    DGESVX uses the LU factorization to compute the solution to a real   
    system of linear equations   
       A * X = B,   
    where A is an N-by-N matrix and X and B are N-by-NRHS matrices.   
    Error bounds on the solution and a condition estimate are also   
    provided.   
    Description   
    ===========   
    The following steps are performed:   
    1. If FACT = 'E', real scaling factors are computed to equilibrate   
       the system:   
          TRANS = 'N':  diag(R)*A*diag(C)     *inv(diag(C))*X = diag(R)*B 
  
          TRANS = 'T': (diag(R)*A*diag(C))**T *inv(diag(R))*X = diag(C)*B 
  
          TRANS = 'C': (diag(R)*A*diag(C))**H *inv(diag(R))*X = diag(C)*B 
  
       Whether or not the system will be equilibrated depends on the   
       scaling of the matrix A, but if equilibration is used, A is   
       overwritten by diag(R)*A*diag(C) and B by diag(R)*B (if TRANS='N') 
  
       or diag(C)*B (if TRANS = 'T' or 'C').   
    2. If FACT = 'N' or 'E', the LU decomposition is used to factor the   
       matrix A (after equilibration if FACT = 'E') as   
          A = P * L * U,   
       where P is a permutation matrix, L is a unit lower triangular   
       matrix, and U is upper triangular.   
    3. The factored form of A is used to estimate the condition number   
       of the matrix A.  If the reciprocal of the condition number is   
       less than machine precision, steps 4-6 are skipped.   
    4. The system of equations is solved for X using the factored form   
       of A.   
    5. Iterative refinement is applied to improve the computed solution   
       matrix and calculate error bounds and backward error estimates   
       for it.   
    6. If equilibration was used, the matrix X is premultiplied by   
       diag(C) (if TRANS = 'N') or diag(R) (if TRANS = 'T' or 'C') so   
       that it solves the original system before equilibration.   
    Arguments   
    =========   
    FACT    (input) CHARACTER*1   
            Specifies whether or not the factored form of the matrix A is 
  
            supplied on entry, and if not, whether the matrix A should be 
  
            equilibrated before it is factored.   
            = 'F':  On entry, AF and IPIV contain the factored form of A. 
  
                    If EQUED is not 'N', the matrix A has been   
                    equilibrated with scaling factors given by R and C.   
                    A, AF, and IPIV are not modified.   
            = 'N':  The matrix A will be copied to AF and factored.   
            = 'E':  The matrix A will be equilibrated if necessary, then 
  
                    copied to AF and factored.   
    TRANS   (input) CHARACTER*1   
            Specifies the form of the system of equations:   
            = 'N':  A * X = B     (No transpose)   
            = 'T':  A**T * X = B  (Transpose)   
            = 'C':  A**H * X = B  (Transpose)   
    N       (input) INTEGER   
            The number of linear equations, i.e., the order of the   
            matrix A.  N >= 0.   
    NRHS    (input) INTEGER   
            The number of right hand sides, i.e., the number of columns   
            of the matrices B and X.  NRHS >= 0.   
    A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)   
            On entry, the N-by-N matrix A.  If FACT = 'F' and EQUED is   
            not 'N', then A must have been equilibrated by the scaling   
            factors in R and/or C.  A is not modified if FACT = 'F' or   
            'N', or if FACT = 'E' and EQUED = 'N' on exit.   
            On exit, if EQUED .ne. 'N', A is scaled as follows:   
            EQUED = 'R':  A := diag(R) * A   
            EQUED = 'C':  A := A * diag(C)   
            EQUED = 'B':  A := diag(R) * A * diag(C).   
    LDA     (input) INTEGER   
            The leading dimension of the array A.  LDA >= max(1,N).   
    AF      (input or output) DOUBLE PRECISION array, dimension (LDAF,N) 
  
            If FACT = 'F', then AF is an input argument and on entry   
            contains the factors L and U from the factorization   
            A = P*L*U as computed by DGETRF.  If EQUED .ne. 'N', then   
            AF is the factored form of the equilibrated matrix A.   
            If FACT = 'N', then AF is an output argument and on exit   
            returns the factors L and U from the factorization A = P*L*U 
  
            of the original matrix A.   
            If FACT = 'E', then AF is an output argument and on exit   
            returns the factors L and U from the factorization A = P*L*U 
  
            of the equilibrated matrix A (see the description of A for   
            the form of the equilibrated matrix).   
    LDAF    (input) INTEGER   
            The leading dimension of the array AF.  LDAF >= max(1,N).   
    IPIV    (input or output) INTEGER array, dimension (N)   
            If FACT = 'F', then IPIV is an input argument and on entry   
            contains the pivot indices from the factorization A = P*L*U   
            as computed by DGETRF; row i of the matrix was interchanged   
            with row IPIV(i).   
            If FACT = 'N', then IPIV is an output argument and on exit   
            contains the pivot indices from the factorization A = P*L*U   
            of the original matrix A.   
            If FACT = 'E', then IPIV is an output argument and on exit   
            contains the pivot indices from the factorization A = P*L*U   
            of the equilibrated matrix A.   
    EQUED   (input or output) CHARACTER*1   
            Specifies the form of equilibration that was done.   
            = 'N':  No equilibration (always true if FACT = 'N').   
            = 'R':  Row equilibration, i.e., A has been premultiplied by 
  
                    diag(R).   
            = 'C':  Column equilibration, i.e., A has been postmultiplied 
  
                    by diag(C).   
            = 'B':  Both row and column equilibration, i.e., A has been   
                    replaced by diag(R) * A * diag(C).   
            EQUED is an input argument if FACT = 'F'; otherwise, it is an 
  
            output argument.   
    R       (input or output) DOUBLE PRECISION array, dimension (N)   
            The row scale factors for A.  If EQUED = 'R' or 'B', A is   
            multiplied on the left by diag(R); if EQUED = 'N' or 'C', R   
            is not accessed.  R is an input argument if FACT = 'F';   
            otherwise, R is an output argument.  If FACT = 'F' and   
            EQUED = 'R' or 'B', each element of R must be positive.   
    C       (input or output) DOUBLE PRECISION array, dimension (N)   
            The column scale factors for A.  If EQUED = 'C' or 'B', A is 
  
            multiplied on the right by diag(C); if EQUED = 'N' or 'R', C 
  
            is not accessed.  C is an input argument if FACT = 'F';   
            otherwise, C is an output argument.  If FACT = 'F' and   
            EQUED = 'C' or 'B', each element of C must be positive.   
    B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)   
            On entry, the N-by-NRHS right hand side matrix B.   
            On exit,   
            if EQUED = 'N', B is not modified;   
            if TRANS = 'N' and EQUED = 'R' or 'B', B is overwritten by   
            diag(R)*B;   
            if TRANS = 'T' or 'C' and EQUED = 'C' or 'B', B is   
            overwritten by diag(C)*B.   
    LDB     (input) INTEGER   
            The leading dimension of the array B.  LDB >= max(1,N).   
    X       (output) DOUBLE PRECISION array, dimension (LDX,NRHS)   
            If INFO = 0, the N-by-NRHS solution matrix X to the original 
  
            system of equations.  Note that A and B are modified on exit 
  
            if EQUED .ne. 'N', and the solution to the equilibrated   
            system is inv(diag(C))*X if TRANS = 'N' and EQUED = 'C' or   
            'B', or inv(diag(R))*X if TRANS = 'T' or 'C' and EQUED = 'R' 
  
            or 'B'.   
    LDX     (input) INTEGER   
            The leading dimension of the array X.  LDX >= max(1,N).   
    RCOND   (output) DOUBLE PRECISION   
            The estimate of the reciprocal condition number of the matrix 
  
            A after equilibration (if done).  If RCOND is less than the   
            machine precision (in particular, if RCOND = 0), the matrix   
            is singular to working precision.  This condition is   
            indicated by a return code of INFO > 0, and the solution and 
  
            error bounds are not computed.   
    FERR    (output) DOUBLE PRECISION array, dimension (NRHS)   
            The estimated forward error bound for each solution vector   
            X(j) (the j-th column of the solution matrix X).   
            If XTRUE is the true solution corresponding to X(j), FERR(j) 
  
            is an estimated upper bound for the magnitude of the largest 
  
            element in (X(j) - XTRUE) divided by the magnitude of the   
            largest element in X(j).  The estimate is as reliable as   
            the estimate for RCOND, and is almost always a slight   
            overestimate of the true error.   
    BERR    (output) DOUBLE PRECISION array, dimension (NRHS)   
            The componentwise relative backward error of each solution   
            vector X(j) (i.e., the smallest relative change in   
            any element of A or B that makes X(j) an exact solution).   
    WORK    (workspace/output) DOUBLE PRECISION array, dimension (4*N)   
            On exit, WORK(1) contains the reciprocal pivot growth   
            factor norm(A)/norm(U). The \"max absolute element\" norm is   
            used. If WORK(1) is much less than 1, then the stability   
            of the LU factorization of the (equilibrated) matrix A   
            could be poor. This also means that the solution X, condition 
  
            estimator RCOND, and forward error bound FERR could be   
            unreliable. If factorization fails with 0<INFO<=N, then   
            WORK(1) contains the reciprocal pivot growth factor for the   
            leading INFO columns of A.   
    IWORK   (workspace) INTEGER array, dimension (N)   
    INFO    (output) INTEGER   
            = 0:  successful exit   
            < 0:  if INFO = -i, the i-th argument had an illegal value   
            > 0:  if INFO = i, and i is   
                  <= N:  U(i,i) is exactly zero.  The factorization has   
                         been completed, but the factor U is exactly   
                         singular, so the solution and error bounds   
                         could not be computed.   
                  = N+1: RCOND is less than machine precision.  The   
                         factorization has been completed, but the   
                         matrix is singular to working precision, and   
                         the solution and error bounds have not been   
                         computed.   
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "FORTRAN 77" dgesvx("E","N",size(A, 1),size(B, 2),Awork,size(A, 1),AF,size(A, 1),ipiv,equed,R,C,Bwork,size(B, 1),X,size(X, 1),RCond,FErrBound,BErrBound,work,iwork,info)         annotation(Library="Lapack");

      end dgesvx;

      function dgesvx_vec "Solve real system of linear equations A*x=b with a b vector, error bounds and condition estimate"
        extends Modelica.Icons.Function;
        input Real A[:,size(A, 1)];
        input Real b[size(A, 1)];
        output Real x[size(A, 1)]=zeros(size(A, 1));
        output Real RCond;
        output Real FErrBound;
        output Real BErrBound;
        output Integer info;
      protected 
        Real Awork[size(A, 1),size(A, 2)]=A;
        Real Bwork[size(A, 1)]=b;
        Real AF[size(A, 1),size(A, 2)];
        Integer ipiv[size(A, 1)];
        String equed=StringAllocate(1);
        Real R[size(A, 1)];
        Real C[size(A, 1)];
        Real work[4*size(A, 1)];
        Integer iwork[size(A, 1)];
        annotation(Documentation(info="
Same as function LAPACK.dgesvx, but right hand side is a vector and not a matrix.
For details of the arguments, see documentation of dgesvx.
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "FORTRAN 77" dgesvx("E","N",size(A, 1),1,Awork,size(A, 1),AF,size(A, 1),ipiv,equed,R,C,Bwork,size(b, 1),x,size(x, 1),RCond,FErrBound,BErrBound,work,iwork,info)         annotation(Library="Lapack");

      end dgesvx_vec;

      function dgglse_vec "Solve a linear equality constrained least squares problem"
        extends Modelica.Icons.Function;
        input Real A[:,:] "Minimize |A*x - c|^2";
        input Real c[size(A, 1)];
        input Real B[:,size(A, 2)] "subject to B*x=d";
        input Real d[size(B, 1)];
        output Real x[size(A, 2)] "solution vector";
        output Integer info;
      protected 
        Integer nrow_A=size(A, 1);
        Integer nrow_B=size(B, 1);
        Integer ncol_A=size(A, 2) "(min=nrow_B,max=nrow_A+nrow_B) required";
        Real Awork[nrow_A,ncol_A]=A;
        Real Bwork[nrow_B,ncol_A]=B;
        Real cwork[nrow_A]=c;
        Real dwork[nrow_B]=d;
        Integer lwork=ncol_A + nrow_B + max(nrow_A, max(ncol_A, nrow_B))*5;
        Real work[lwork];

        external "FORTRAN 77" dgglse(nrow_A,ncol_A,nrow_B,Awork,nrow_A,Bwork,nrow_B,cwork,dwork,x,work,lwork,info)         annotation(Library="Lapack");
        annotation(Coordsys(extent=[-100,-100;100,100], grid=[2,2], component=[20,20]), Documentation(info="Lapack documentation
 
  Purpose
  =======
 
  DGGLSE solves the linear equality constrained least squares (LSE)
  problem:
 
          minimize || A*x - c ||_2   subject to B*x = d
 
  using a generalized RQ factorization of matrices A and B, where A is
  M-by-N, B is P-by-N, assume P <= N <= M+P, and ||.||_2 denotes vector
  2-norm. It is assumed that
 
                       rank(B) = P                                  (1)
 
  and the null spaces of A and B intersect only trivially, i.e.,
 
   intersection of Null(A) and Null(B) = {0} <=> rank( ( A ) ) = N  (2)
                                                     ( ( B ) )
 
  where N(A) denotes the null space of matrix A. Conditions (1) and (2)
  ensure that the problem LSE has a unique solution.
 
  Arguments
  =========
 
  M       (input) INTEGER
          The number of rows of the matrix A.  M >= 0.
 
  N       (input) INTEGER
          The number of columns of the matrices A and B. N >= 0.
          Assume that P <= N <= M+P.
 
  P       (input) INTEGER
          The number of rows of the matrix B.  P >= 0.
 
  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
          On entry, the P-by-M matrix A.
          On exit, A is destroyed.
 
  LDA     (input) INTEGER
          The leading dimension of the array A. LDA >= max(1,M).
 
  B       (input/output) DOUBLE PRECISION array, dimension (LDB,N)
          On entry, the P-by-N matrix B.
          On exit, B is destroyed.
 
  LDB     (input) INTEGER
          The leading dimension of the array B. LDB >= max(1,P).
 
  C       (input/output) DOUBLE PRECISION array, dimension (M)
          On entry, C contains the right hand side vector for the
          least squares part of the LSE problem.
          On exit, the residual sum of squares for the solution
          is given by the sum of squares of elements N-P+1 to M of
          vector C.
 
  D       (input/output) DOUBLE PRECISION array, dimension (P)
          On entry, D contains the right hand side vector for the
          constrained equation.
          On exit, D is destroyed.
 
  X       (output) DOUBLE PRECISION array, dimension (N)
          On exit, X is the solution of the LSE problem.
 
  WORK    (workspace) DOUBLE PRECISION array, dimension (LWORK)
          On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
 
  LWORK   (input) INTEGER
          The dimension of the array WORK. LWORK >= N+P+max(N,M,P).
          For optimum performance LWORK >=
          N+P+max(M,P,N)*max(NB1,NB2), where NB1 is the optimal
          blocksize for the QR factorization of M-by-N matrix A.
          NB2 is the optimal blocksize for the RQ factorization of
          P-by-N matrix B.
 
  INFO    (output) INTEGER
          = 0:  successful exit.
          < 0:  if INFO = -i, the i-th argument had an illegal value.
"), Window(x=0.34, y=0.06, width=0.6, height=0.6));
      end dgglse_vec;

      function dgtsv "Solve real system of linear equations A*X=B with B matrix and tridiagonal A"
        extends Modelica.Icons.Function;
        input Real superdiag[:];
        input Real diag[size(superdiag, 1) + 1];
        input Real subdiag[size(superdiag, 1)];
        input Real B[size(diag, 1),:];
        output Real X[size(B, 1),size(B, 2)]=B;
        output Integer info;
      protected 
        Real superdiagwork[size(superdiag, 1)]=superdiag;
        Real diagwork[size(diag, 1)]=diag;
        Real subdiagwork[size(subdiag, 1)]=subdiag;
        annotation(Documentation(info="Lapack documentation:
    Purpose   
    =======   
    DGTSV  solves the equation   
       A*X = B,   
    where A is an N-by-N tridiagonal matrix, by Gaussian elimination with 
  
    partial pivoting.   
    Note that the equation  A'*X = B  may be solved by interchanging the 
  
    order of the arguments DU and DL.   
    Arguments   
    =========   
    N       (input) INTEGER   
            The order of the matrix A.  N >= 0.   
    NRHS    (input) INTEGER   
            The number of right hand sides, i.e., the number of columns   
            of the matrix B.  NRHS >= 0.   
    DL      (input/output) DOUBLE PRECISION array, dimension (N-1)   
            On entry, DL must contain the (n-1) subdiagonal elements of   
            A.   
            On exit, DL is overwritten by the (n-2) elements of the   
            second superdiagonal of the upper triangular matrix U from   
            the LU factorization of A, in DL(1), ..., DL(n-2).   
    D       (input/output) DOUBLE PRECISION array, dimension (N)   
            On entry, D must contain the diagonal elements of A.   
            On exit, D is overwritten by the n diagonal elements of U.   
    DU      (input/output) DOUBLE PRECISION array, dimension (N-1)   
            On entry, DU must contain the (n-1) superdiagonal elements   
            of A.   
            On exit, DU is overwritten by the (n-1) elements of the first 
  
            superdiagonal of U.   
    B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)   
            On entry, the N-by-NRHS right hand side matrix B.   
            On exit, if INFO = 0, the N-by-NRHS solution matrix X.   
    LDB     (input) INTEGER   
            The leading dimension of the array B.  LDB >= max(1,N).   
    INFO    (output) INTEGER   
            = 0:  successful exit   
            < 0:  if INFO = -i, the i-th argument had an illegal value   
            > 0:  if INFO = i, U(i,i) is exactly zero, and the solution   
                  has not been computed.  The factorization has not been 
  
                  completed unless i = N.   
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "FORTRAN 77" dgtsv(size(diag, 1),size(B, 2),subdiagwork,diagwork,superdiagwork,X,size(B, 1),info)         annotation(Library="Lapack");

      end dgtsv;

      function dgtsv_vec "Solve real system of linear equations A*x=b with b vector and tridiagonal A"
        extends Modelica.Icons.Function;
        input Real superdiag[:];
        input Real diag[size(superdiag, 1) + 1];
        input Real subdiag[size(superdiag, 1)];
        input Real b[size(diag, 1)];
        output Real x[size(b, 1)]=b;
        output Integer info;
      protected 
        Real superdiagwork[size(superdiag, 1)]=superdiag;
        Real diagwork[size(diag, 1)]=diag;
        Real subdiagwork[size(subdiag, 1)]=subdiag;
        annotation(Documentation(info="
Same as function LAPACK.dgtsv, but right hand side is a vector and not a matrix.
For details of the arguments, see documentation of dgtsv.
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "FORTRAN 77" dgtsv(size(diag, 1),1,subdiagwork,diagwork,superdiagwork,x,size(b, 1),info)         annotation(Library="Lapack");

      end dgtsv_vec;

      function dgbsv "Solve real system of linear equations A*X=B with a B matrix"
        extends Modelica.Icons.Function;
        input Integer n "Number of equations";
        input Integer kLower "Number of lower bands";
        input Integer kUpper "Number of upper bands";
        input Real A[2*kLower + kUpper + 1,n];
        input Real B[n,:];
        output Real X[n,size(B, 2)]=B;
        output Integer info;
      protected 
        Real Awork[size(A, 1),size(A, 2)]=A;
        Integer ipiv[n];
        annotation(Documentation(info="Lapack documentation:  
Purpose
=======
DGBSV computes the solution to a real system of linear equations
A * X = B, where A is a band matrix of order N with KL subdiagonals
and KU superdiagonals, and X and B are N-by-NRHS matrices.
The LU decomposition with partial pivoting and row interchanges is
used to factor A as A = L * U, where L is a product of permutation
and unit lower triangular matrices with KL subdiagonals, and U is
upper triangular with KL+KU superdiagonals.  The factored form of A
is then used to solve the system of equations A * X = B.
Arguments
=========
N       (input) INTEGER
        The number of linear equations, i.e., the order of the
        matrix A.  N >= 0.
KL      (input) INTEGER
        The number of subdiagonals within the band of A.  KL >= 0.
KU      (input) INTEGER
        The number of superdiagonals within the band of A.  KU >= 0.
NRHS    (input) INTEGER
        The number of right hand sides, i.e., the number of columns
        of the matrix B.  NRHS >= 0.
AB      (input/output) DOUBLE PRECISION array, dimension (LDAB,N)
        On entry, the matrix A in band storage, in rows KL+1 to
        2*KL+KU+1; rows 1 to KL of the array need not be set.
        The j-th column of A is stored in the j-th column of the
        array AB as follows:
        AB(KL+KU+1+i-j,j) = A(i,j) for max(1,j-KU)<=i<=min(N,j+KL)
        On exit, details of the factorization: U is stored as an
        upper triangular band matrix with KL+KU superdiagonals in
        rows 1 to KL+KU+1, and the multipliers used during the
        factorization are stored in rows KL+KU+2 to 2*KL+KU+1.
        See below for further details.
LDAB    (input) INTEGER
        The leading dimension of the array AB.  LDAB >= 2*KL+KU+1.
IPIV    (output) INTEGER array, dimension (N)
        The pivot indices that define the permutation matrix P;
        row i of the matrix was interchanged with row IPIV(i).
B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
        On entry, the N-by-NRHS right hand side matrix B.
        On exit, if INFO = 0, the N-by-NRHS solution matrix X.
LDB     (input) INTEGER
        The leading dimension of the array B.  LDB >= max(1,N).
INFO    (output) INTEGER
        = 0:  successful exit
        < 0:  if INFO = -i, the i-th argument had an illegal value
        > 0:  if INFO = i, U(i,i) is exactly zero.  The factorization
              has been completed, but the factor U is exactly
              singular, and the solution has not been computed.
Further Details
===============
The band storage scheme is illustrated by the following example, when
M = N = 6, KL = 2, KU = 1:
On entry:                       On exit:
    *    *    *    +    +    +       *    *    *   u14  u25  u36
    *    *    +    +    +    +       *    *   u13  u24  u35  u46
    *   a12  a23  a34  a45  a56      *   u12  u23  u34  u45  u56
   a11  a22  a33  a44  a55  a66     u11  u22  u33  u44  u55  u66
   a21  a32  a43  a54  a65   *      m21  m32  m43  m54  m65   *
   a31  a42  a53  a64   *    *      m31  m42  m53  m64   *    *
Array elements marked * are not used by the routine; elements marked
+ need not be set on entry, but are required by the routine to store
elements of U because of fill-in resulting from the row interchanges."), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "FORTRAN 77" dgbsv(n,kLower,kUpper,size(B, 2),Awork,size(Awork, 1),ipiv,X,n,info)         annotation(Library="Lapack");

      end dgbsv;

      function dgbsv_vec "Solve real system of linear equations A*x=b with a b vector"
        extends Modelica.Icons.Function;
        input Integer n "Number of equations";
        input Integer kLower "Number of lower bands";
        input Integer kUpper "Number of upper bands";
        input Real A[2*kLower + kUpper + 1,n];
        input Real b[n];
        output Real x[n]=b;
        output Integer info;
      protected 
        Real Awork[size(A, 1),size(A, 2)]=A;
        Integer ipiv[n];
        annotation(Documentation(info="Lapack documentation:  
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "FORTRAN 77" dgbsv(n,kLower,kUpper,1,Awork,size(Awork, 1),ipiv,x,n,info)         annotation(Library="Lapack");

      end dgbsv_vec;

      function dgesvd "Determine singular value decomposition"
        extends Modelica.Icons.Function;
        input Real A[:,:];
        output Real sigma[min(size(A, 1), size(A, 2))];
        output Real U[size(A, 1),size(A, 1)]=zeros(size(A, 1), size(A, 1));
        output Real VT[size(A, 2),size(A, 2)]=zeros(size(A, 2), size(A, 2));
        output Integer info;
      protected 
        Real Awork[size(A, 1),size(A, 2)]=A;
        Integer lwork=5*size(A, 1) + 5*size(A, 2);
        Real work[lwork];
        annotation(Documentation(info="Lapack documentation:
    Purpose   
    =======   
    DGESVD computes the singular value decomposition (SVD) of a real   
    M-by-N matrix A, optionally computing the left and/or right singular 
  
    vectors. The SVD is written   
         A = U * SIGMA * transpose(V)   
    where SIGMA is an M-by-N matrix which is zero except for its   
    min(m,n) diagonal elements, U is an M-by-M orthogonal matrix, and   
    V is an N-by-N orthogonal matrix.  The diagonal elements of SIGMA   
    are the singular values of A; they are real and non-negative, and   
    are returned in descending order.  The first min(m,n) columns of   
    U and V are the left and right singular vectors of A.   
    Note that the routine returns V**T, not V.   
    Arguments   
    =========   
    JOBU    (input) CHARACTER*1   
            Specifies options for computing all or part of the matrix U: 
  
            = 'A':  all M columns of U are returned in array U:   
            = 'S':  the first min(m,n) columns of U (the left singular   
                    vectors) are returned in the array U;   
            = 'O':  the first min(m,n) columns of U (the left singular   
                    vectors) are overwritten on the array A;   
            = 'N':  no columns of U (no left singular vectors) are   
                    computed.   
    JOBVT   (input) CHARACTER*1   
            Specifies options for computing all or part of the matrix   
            V**T:   
            = 'A':  all N rows of V**T are returned in the array VT;   
            = 'S':  the first min(m,n) rows of V**T (the right singular   
                    vectors) are returned in the array VT;   
            = 'O':  the first min(m,n) rows of V**T (the right singular   
                    vectors) are overwritten on the array A;   
            = 'N':  no rows of V**T (no right singular vectors) are   
                    computed.   
            JOBVT and JOBU cannot both be 'O'.   
    M       (input) INTEGER   
            The number of rows of the input matrix A.  M >= 0.   
    N       (input) INTEGER   
            The number of columns of the input matrix A.  N >= 0.   
    A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)   
            On entry, the M-by-N matrix A.   
            On exit,   
            if JOBU = 'O',  A is overwritten with the first min(m,n)   
                            columns of U (the left singular vectors,   
                            stored columnwise);   
            if JOBVT = 'O', A is overwritten with the first min(m,n)   
                            rows of V**T (the right singular vectors,   
                            stored rowwise);   
            if JOBU .ne. 'O' and JOBVT .ne. 'O', the contents of A   
                            are destroyed.   
    LDA     (input) INTEGER   
            The leading dimension of the array A.  LDA >= max(1,M).   
    S       (output) DOUBLE PRECISION array, dimension (min(M,N))   
            The singular values of A, sorted so that S(i) >= S(i+1).   
    U       (output) DOUBLE PRECISION array, dimension (LDU,UCOL)   
            (LDU,M) if JOBU = 'A' or (LDU,min(M,N)) if JOBU = 'S'.   
            If JOBU = 'A', U contains the M-by-M orthogonal matrix U;   
            if JOBU = 'S', U contains the first min(m,n) columns of U   
            (the left singular vectors, stored columnwise);   
            if JOBU = 'N' or 'O', U is not referenced.   
    LDU     (input) INTEGER   
            The leading dimension of the array U.  LDU >= 1; if   
            JOBU = 'S' or 'A', LDU >= M.   
    VT      (output) DOUBLE PRECISION array, dimension (LDVT,N)   
            If JOBVT = 'A', VT contains the N-by-N orthogonal matrix   
            V**T;   
            if JOBVT = 'S', VT contains the first min(m,n) rows of   
            V**T (the right singular vectors, stored rowwise);   
            if JOBVT = 'N' or 'O', VT is not referenced.   
    LDVT    (input) INTEGER   
            The leading dimension of the array VT.  LDVT >= 1; if   
            JOBVT = 'A', LDVT >= N; if JOBVT = 'S', LDVT >= min(M,N).   
    WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK) 
  
            On exit, if INFO = 0, WORK(1) returns the optimal LWORK;   
            if INFO > 0, WORK(2:MIN(M,N)) contains the unconverged   
            superdiagonal elements of an upper bidiagonal matrix B   
            whose diagonal is in S (not necessarily sorted). B   
            satisfies A = U * B * VT, so it has the same singular values 
  
            as A, and singular vectors related by U and VT.   
    LWORK   (input) INTEGER   
            The dimension of the array WORK. LWORK >= 1.   
            LWORK >= MAX(3*MIN(M,N)+MAX(M,N),5*MIN(M,N)-4).   
            For good performance, LWORK should generally be larger.   
    INFO    (output) INTEGER   
            = 0:  successful exit.   
            < 0:  if INFO = -i, the i-th argument had an illegal value.   
            > 0:  if DBDSQR did not converge, INFO specifies how many   
                  superdiagonals of an intermediate bidiagonal form B   
                  did not converge to zero. See the description of WORK   
                  above for details.   
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "Fortran 77" dgesvd("A","A",size(A, 1),size(A, 2),Awork,size(A, 1),sigma,U,size(A, 1),VT,size(A, 2),work,lwork,info)         annotation(Library="Lapack");

      end dgesvd;

      function dgesvd_sigma "Determine singular values"
        extends Modelica.Icons.Function;
        input Real A[:,:];
        output Real sigma[min(size(A, 1), size(A, 2))];
        output Integer info;
      protected 
        Real Awork[size(A, 1),size(A, 2)]=A;
        Real U[size(A, 1),size(A, 1)];
        Real VT[size(A, 2),size(A, 2)];
        Integer lwork=5*size(A, 1) + 5*size(A, 2);
        Real work[lwork];
        annotation(Documentation(info="Lapack documentation:
    Purpose   
    =======   
    DGESVD computes the singular value decomposition (SVD) of a real   
    M-by-N matrix A, optionally computing the left and/or right singular 
  
    vectors. The SVD is written   
         A = U * SIGMA * transpose(V)   
    where SIGMA is an M-by-N matrix which is zero except for its   
    min(m,n) diagonal elements, U is an M-by-M orthogonal matrix, and   
    V is an N-by-N orthogonal matrix.  The diagonal elements of SIGMA   
    are the singular values of A; they are real and non-negative, and   
    are returned in descending order.  The first min(m,n) columns of   
    U and V are the left and right singular vectors of A.   
    Note that the routine returns V**T, not V.   
    Arguments   
    =========   
    JOBU    (input) CHARACTER*1   
            Specifies options for computing all or part of the matrix U: 
  
            = 'A':  all M columns of U are returned in array U:   
            = 'S':  the first min(m,n) columns of U (the left singular   
                    vectors) are returned in the array U;   
            = 'O':  the first min(m,n) columns of U (the left singular   
                    vectors) are overwritten on the array A;   
            = 'N':  no columns of U (no left singular vectors) are   
                    computed.   
    JOBVT   (input) CHARACTER*1   
            Specifies options for computing all or part of the matrix   
            V**T:   
            = 'A':  all N rows of V**T are returned in the array VT;   
            = 'S':  the first min(m,n) rows of V**T (the right singular   
                    vectors) are returned in the array VT;   
            = 'O':  the first min(m,n) rows of V**T (the right singular   
                    vectors) are overwritten on the array A;   
            = 'N':  no rows of V**T (no right singular vectors) are   
                    computed.   
            JOBVT and JOBU cannot both be 'O'.   
    M       (input) INTEGER   
            The number of rows of the input matrix A.  M >= 0.   
    N       (input) INTEGER   
            The number of columns of the input matrix A.  N >= 0.   
    A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)   
            On entry, the M-by-N matrix A.   
            On exit,   
            if JOBU = 'O',  A is overwritten with the first min(m,n)   
                            columns of U (the left singular vectors,   
                            stored columnwise);   
            if JOBVT = 'O', A is overwritten with the first min(m,n)   
                            rows of V**T (the right singular vectors,   
                            stored rowwise);   
            if JOBU .ne. 'O' and JOBVT .ne. 'O', the contents of A   
                            are destroyed.   
    LDA     (input) INTEGER   
            The leading dimension of the array A.  LDA >= max(1,M).   
    S       (output) DOUBLE PRECISION array, dimension (min(M,N))   
            The singular values of A, sorted so that S(i) >= S(i+1).   
    U       (output) DOUBLE PRECISION array, dimension (LDU,UCOL)   
            (LDU,M) if JOBU = 'A' or (LDU,min(M,N)) if JOBU = 'S'.   
            If JOBU = 'A', U contains the M-by-M orthogonal matrix U;   
            if JOBU = 'S', U contains the first min(m,n) columns of U   
            (the left singular vectors, stored columnwise);   
            if JOBU = 'N' or 'O', U is not referenced.   
    LDU     (input) INTEGER   
            The leading dimension of the array U.  LDU >= 1; if   
            JOBU = 'S' or 'A', LDU >= M.   
    VT      (output) DOUBLE PRECISION array, dimension (LDVT,N)   
            If JOBVT = 'A', VT contains the N-by-N orthogonal matrix   
            V**T;   
            if JOBVT = 'S', VT contains the first min(m,n) rows of   
            V**T (the right singular vectors, stored rowwise);   
            if JOBVT = 'N' or 'O', VT is not referenced.   
    LDVT    (input) INTEGER   
            The leading dimension of the array VT.  LDVT >= 1; if   
            JOBVT = 'A', LDVT >= N; if JOBVT = 'S', LDVT >= min(M,N).   
    WORK    (workspace/output) DOUBLE PRECISION array, dimension (LWORK) 
  
            On exit, if INFO = 0, WORK(1) returns the optimal LWORK;   
            if INFO > 0, WORK(2:MIN(M,N)) contains the unconverged   
            superdiagonal elements of an upper bidiagonal matrix B   
            whose diagonal is in S (not necessarily sorted). B   
            satisfies A = U * B * VT, so it has the same singular values 
  
            as A, and singular vectors related by U and VT.   
    LWORK   (input) INTEGER   
            The dimension of the array WORK. LWORK >= 1.   
            LWORK >= MAX(3*MIN(M,N)+MAX(M,N),5*MIN(M,N)-4).   
            For good performance, LWORK should generally be larger.   
    INFO    (output) INTEGER   
            = 0:  successful exit.   
            < 0:  if INFO = -i, the i-th argument had an illegal value.   
            > 0:  if DBDSQR did not converge, INFO specifies how many   
                  superdiagonals of an intermediate bidiagonal form B   
                  did not converge to zero. See the description of WORK   
                  above for details.   
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "Fortran 77" dgesvd("N","N",size(A, 1),size(A, 2),Awork,size(A, 1),sigma,U,size(A, 1),VT,size(A, 2),work,lwork,info)         annotation(Library="Lapack");

      end dgesvd_sigma;

      function StringAllocate "Utility function to provide storage for characters"
        extends Modelica.Icons.Function;
        input Integer n;
        output String s;

        external "C"         annotation(doNotDeclare);

      end StringAllocate;

      function dgetrf "Compute LU factorization of square or rectangular matrix A (A = P*L*U)"
        extends Modelica.Icons.Function;
        input Real A[:,:] "Square or rectangular matrix";
        output Real LU[size(A, 1),size(A, 2)]=A;
        output Integer pivots[min(size(A, 1), size(A, 2))] "Pivot vector";
        output Integer info "Information";
        annotation(Documentation(info="Lapack documentation:
  SUBROUTINE DGETRF( M, N, A, LDA, IPIV, INFO )
-- LAPACK routine (version 1.1) --
   Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
   Courant Institute, Argonne National Lab, and Rice University
   March 31, 1993
   .. Scalar Arguments ..
   INTEGER            INFO, LDA, M, N
   ..
   .. Array Arguments ..
   INTEGER            IPIV( * )
   DOUBLE PRECISION   A( LDA, * )
   ..
Purpose
=======
DGETRF computes an LU factorization of a general M-by-N matrix A
using partial pivoting with row interchanges.
The factorization has the form
   A = P * L * U
where P is a permutation matrix, L is lower triangular with unit
diagonal elements (lower trapezoidal if m > n), and U is upper
triangular (upper trapezoidal if m < n).
This is the right-looking Level 3 BLAS version of the algorithm.
Arguments
=========
M       (input) INTEGER
        The number of rows of the matrix A.  M >= 0.
N       (input) INTEGER
        The number of columns of the matrix A.  N >= 0.
A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
        On entry, the M-by-N matrix to be factored.
        On exit, the factors L and U from the factorization
        A = P*L*U; the unit diagonal elements of L are not stored.
LDA     (input) INTEGER
        The leading dimension of the array A.  LDA >= max(1,M).
IPIV    (output) INTEGER array, dimension (min(M,N))
        The pivot indices; for 1 <= i <= min(M,N), row i of the
        matrix was interchanged with row IPIV(i).
INFO    (output) INTEGER
        = 0:  successful exit
        < 0:  if INFO = -i, the i-th argument had an illegal value
        > 0:  if INFO = i, U(i,i) is exactly zero. The factorization
              has been completed, but the factor U is exactly
              singular, and division by zero will occur if it is used
              to solve a system of equations.
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));

        external "FORTRAN 77" dgetrf(size(A, 1),size(A, 2),LU,size(A, 1),pivots,info)         annotation(Library="Lapack");

      end dgetrf;

      function dgetrs_vec "Solves a system of linear equations with the LU decomposition from dgetrf(..)"
        extends Modelica.Icons.Function;
        input Real LU[:,size(LU, 1)] "LU factorization of dgetrf of a square matrix";
        input Integer pivots[size(LU, 1)] "Pivot vector of dgetrf";
        input Real b[size(LU, 1)] "Right hand side vector b";
        output Real x[size(b, 1)]=b;
        annotation(Documentation(info="Lapack documentation:
  SUBROUTINE DGETRS( TRANS, N, NRHS, A, LDA, IPIV, B, LDB, INFO )
-- LAPACK routine (version 1.1) --
   Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
   Courant Institute, Argonne National Lab, and Rice University
   March 31, 1993
   .. Scalar Arguments ..
   CHARACTER          TRANS
   INTEGER            INFO, LDA, LDB, N, NRHS
   ..
   .. Array Arguments ..
   INTEGER            IPIV( * )
   DOUBLE PRECISION   A( LDA, * ), B( LDB, * )
   ..
Purpose
=======
DGETRS solves a system of linear equations
   A * X = B  or  A' * X = B
with a general N-by-N matrix A using the LU factorization computed
by DGETRF.
Arguments
=========
TRANS   (input) CHARACTER*1
        Specifies the form of the system of equations:
        = 'N':  A * X = B  (No transpose)
        = 'T':  A'* X = B  (Transpose)
        = 'C':  A'* X = B  (Conjugate transpose = Transpose)
N       (input) INTEGER
        The order of the matrix A.  N >= 0.
NRHS    (input) INTEGER
        The number of right hand sides, i.e., the number of columns
        of the matrix B.  NRHS >= 0.
A       (input) DOUBLE PRECISION array, dimension (LDA,N)
        The factors L and U from the factorization A = P*L*U
        as computed by DGETRF.
LDA     (input) INTEGER
        The leading dimension of the array A.  LDA >= max(1,N).
IPIV    (input) INTEGER array, dimension (N)
        The pivot indices from DGETRF; for 1<=i<=N, row i of the
        matrix was interchanged with row IPIV(i).
B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
        On entry, the right hand side matrix B.
        On exit, the solution matrix X.
LDB     (input) INTEGER
        The leading dimension of the array B.  LDB >= max(1,N).
INFO    (output) INTEGER
        = 0:  successful exit
        < 0:  if INFO = -i, the i-th argument had an illegal value
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
      protected 
        Real work[size(LU, 1),size(LU, 1)]=LU;
        Integer info;

        external "FORTRAN 77" dgetrs("N",size(LU, 1),1,work,size(LU, 1),pivots,x,size(b, 1),info)         annotation(Library="Lapack");

      end dgetrs_vec;

      function dgetri "Computes the inverse of a matrix using the LU factorization from dgetrf(..)"
        extends Modelica.Icons.Function;
        input Real LU[:,size(LU, 1)] "LU factorization of dgetrf of a square matrix";
        input Integer pivots[size(LU, 1)] "Pivot vector of dgetrf";
        output Real inv[size(LU, 1),size(LU, 2)]=LU "Inverse of matrix P*L*U";
        annotation(Documentation(info="Lapack documentation:
   SUBROUTINE DGETRI( N, A, LDA, IPIV, WORK, LWORK, INFO )
-- LAPACK routine (version 1.1) --
   Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
   Courant Institute, Argonne National Lab, and Rice University
   March 31, 1993
   .. Scalar Arguments ..
   INTEGER            INFO, LDA, LWORK, N
   ..
   .. Array Arguments ..
   INTEGER            IPIV( * )
   DOUBLE PRECISION   A( LDA, * ), WORK( LWORK )
   ..
Purpose
=======
DGETRI computes the inverse of a matrix using the LU factorization
computed by DGETRF.
This method inverts U and then computes inv(A) by solving the system
inv(A)*L = inv(U) for inv(A).
Arguments
=========
N       (input) INTEGER
        The order of the matrix A.  N >= 0.
A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
        On entry, the factors L and U from the factorization
        A = P*L*U as computed by DGETRF.
        On exit, if INFO = 0, the inverse of the original matrix A.
LDA     (input) INTEGER
        The leading dimension of the array A.  LDA >= max(1,N).
IPIV    (input) INTEGER array, dimension (N)
        The pivot indices from DGETRF; for 1<=i<=N, row i of the
        matrix was interchanged with row IPIV(i).
WORK    (workspace) DOUBLE PRECISION array, dimension (LWORK)
        On exit, if INFO=0, then WORK(1) returns the optimal LWORK.
LWORK   (input) INTEGER
        The dimension of the array WORK.  LWORK >= max(1,N).
        For optimal performance LWORK >= N*NB, where NB is
        the optimal blocksize returned by ILAENV.
INFO    (output) INTEGER
        = 0:  successful exit
        < 0:  if INFO = -i, the i-th argument had an illegal value
        > 0:  if INFO = i, U(i,i) is exactly zero; the matrix is
              singular and its inverse could not be computed."), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
      protected 
        Integer lwork=min(10, size(LU, 1))*size(LU, 1) "Length of work array";
        Real work[lwork];
        Integer info;

        external "FORTRAN 77" dgetri(size(LU, 1),inv,size(LU, 1),pivots,work,lwork,info)         annotation(Library="Lapack");

      end dgetri;

      function dgeqpf "Compute QR factorization of square or rectangular matrix A with column pivoting (A(:,p) = Q*R)"
        extends Modelica.Icons.Function;
        input Real A[:,:] "Square or rectangular matrix";
        output Real QR[size(A, 1),size(A, 2)]=A "QR factorization in packed format";
        output Real tau[min(size(A, 1), size(A, 2))] "The scalar factors of the elementary reflectors of Q";
        output Integer p[size(A, 2)]=zeros(size(A, 2)) "Pivot vector";
        annotation(Documentation(info="Lapack documentation:
   SUBROUTINE DGEQPF( M, N, A, LDA, JPVT, TAU, WORK, INFO )
-- LAPACK test routine (version 1.1) --
   Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
   Courant Institute, Argonne National Lab, and Rice University
   March 31, 1993
   .. Scalar Arguments ..
   INTEGER            INFO, LDA, M, N
   ..
   .. Array Arguments ..
   INTEGER            JPVT( * )
   DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( * )
   ..
Purpose
=======
DGEQPF computes a QR factorization with column pivoting of a
real M-by-N matrix A: A*P = Q*R.
Arguments
=========
M       (input) INTEGER
        The number of rows of the matrix A. M >= 0.
N       (input) INTEGER
        The number of columns of the matrix A. N >= 0
A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
        On entry, the M-by-N matrix A.
        On exit, the upper triangle of the array contains the
        min(M,N)-by-N upper triangular matrix R; the elements
        below the diagonal, together with the array TAU,
        represent the orthogonal matrix Q as a product of
        min(m,n) elementary reflectors.
LDA     (input) INTEGER
        The leading dimension of the array A. LDA >= max(1,M).
JPVT    (input/output) INTEGER array, dimension (N)
        On entry, if JPVT(i) .ne. 0, the i-th column of A is permuted
        to the front of A*P (a leading column); if JPVT(i) = 0,
        the i-th column of A is a free column.
        On exit, if JPVT(i) = k, then the i-th column of A*P
        was the k-th column of A.
TAU     (output) DOUBLE PRECISION array, dimension (min(M,N))
        The scalar factors of the elementary reflectors.
WORK    (workspace) DOUBLE PRECISION array, dimension (3*N)
INFO    (output) INTEGER
        = 0:  successful exit
        < 0:  if INFO = -i, the i-th argument had an illegal value
Further Details
===============
The matrix Q is represented as a product of elementary reflectors
   Q = H(1) H(2) . . . H(n)
Each H(i) has the form
   H = I - tau * v * v'
where tau is a real scalar, and v is a real vector with
v(1:i-1) = 0 and v(i) = 1; v(i+1:m) is stored on exit in A(i+1:m,i).
The matrix P is represented in jpvt as follows: If
   jpvt(j) = i
then the jth column of P is the ith canonical unit vector."), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
      protected 
        Integer info;
        Integer ncol=size(A, 2) "Column dimension of A";
        Real work[3*ncol] "work array";

        external "FORTRAN 77" dgeqpf(size(A, 1),ncol,QR,size(A, 1),p,tau,work,info)         annotation(Library="Lapack");

      end dgeqpf;

      function dorgqr "Generates a Real orthogonal matrix Q which is defined as the product of elementary reflectors as returned from dgeqpf"
        extends Modelica.Icons.Function;
        input Real QR[:,:] "QR from dgeqpf";
        input Real tau[min(size(QR, 1), size(QR, 2))] "The scalar factors of the elementary reflectors of Q";
        output Real Q[size(QR, 1),size(QR, 2)]=QR "Orthogonal matrix Q";
        annotation(Documentation(info="Lapack documentation:
   SUBROUTINE DORGQR( M, N, K, A, LDA, TAU, WORK, LWORK, INFO )
-- LAPACK routine (version 1.1) --
   Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
   Courant Institute, Argonne National Lab, and Rice University
   March 31, 1993
   .. Scalar Arguments ..
   INTEGER            INFO, K, LDA, LWORK, M, N
   ..
   .. Array Arguments ..
   DOUBLE PRECISION   A( LDA, * ), TAU( * ), WORK( LWORK )
   ..
Purpose
=======
DORGQR generates an M-by-N real matrix Q with orthonormal columns,
which is defined as the first N columns of a product of K elementary
reflectors of order M
      Q  =  H(1) H(2) . . . H(k)
as returned by DGEQRF.
Arguments
=========
M       (input) INTEGER
        The number of rows of the matrix Q. M >= 0.
N       (input) INTEGER
        The number of columns of the matrix Q. M >= N >= 0.
K       (input) INTEGER
        The number of elementary reflectors whose product defines the
        matrix Q. N >= K >= 0.
A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
        On entry, the i-th column must contain the vector which
        defines the elementary reflector H(i), for i = 1,2,...,k, as
        returned by DGEQRF in the first k columns of its array
        argument A.
        On exit, the M-by-N matrix Q.
LDA     (input) INTEGER
        The first dimension of the array A. LDA >= max(1,M).
TAU     (input) DOUBLE PRECISION array, dimension (K)
        TAU(i) must contain the scalar factor of the elementary
        reflector H(i), as returned by DGEQRF.
WORK    (workspace) DOUBLE PRECISION array, dimension (LWORK)
        On exit, if INFO = 0, WORK(1) returns the optimal LWORK.
LWORK   (input) INTEGER
        The dimension of the array WORK. LWORK >= max(1,N).
        For optimum performance LWORK >= N*NB, where NB is the
        optimal blocksize.
INFO    (output) INTEGER
        = 0:  successful exit
        < 0:  if INFO = -i, the i-th argument has an illegal value
"), Diagram(coordinateSystem(extent={{-100,-100},{100,100}})), Icon(coordinateSystem(extent={{-100,-100},{100,100}})));
      protected 
        Integer info;
        Integer lwork=min(10, size(QR, 2))*size(QR, 2) "Length of work array";
        Real work[lwork];

        external "FORTRAN 77" dorgqr(size(QR, 1),size(QR, 2),size(tau, 1),Q,size(Q, 1),tau,work,lwork,info)         annotation(Library="Lapack");

      end dorgqr;

    end LAPACK;

  end Matrices;

  function sin "sine"
    extends baseIcon1;
    input SI.Angle u;
    output Real y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{12,36},{84,84}}, textString="sin", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-80,0},{-68.7,34.2},{-61.5,53.1},{-55.1,66.4},{-49.4,74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{-26.9,69.7},{-21.3,59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,-50.2},{23.7,-64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},{51.9,-71.5},{57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-105,72},{-85,88}}, textString="1", fontName="Arial"),Text(visible=true, extent={{70,5},{90,25}}, textString="2*pi", fontName="Arial"),Text(visible=true, extent={{-105,-88},{-85,-72}}, textString="-1", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>
 
</html>"));

    external "C" y=sin(u) ;

  end sin;

  function cos "cosine"
    extends baseIcon1;
    input SI.Angle u;
    output Real y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,80},{-74.4,78.1},{-68.7,72.3},{-63.1,63},{-56.7,48.7},{-48.6,26.6},{-29.3,-32.5},{-22.1,-51.7},{-15.7,-65.3},{-10.1,-73.8},{-4.42,-78.8},{1.21,-79.9},{6.83,-77.1},{12.5,-70.6},{18.1,-60.6},{24.5,-45.7},{32.6,-23},{50.3,31.3},{57.5,50.7},{63.9,64.6},{69.5,73.4},{75.2,78.6},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-36,34},{36,82}}, textString="cos", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-105,72},{-85,88}}, textString="1", fontName="Arial"),Text(visible=true, extent={{-105,-88},{-85,-72}}, textString="-1", fontName="Arial"),Text(visible=true, extent={{70,5},{90,25}}, textString="2*pi", fontName="Arial"),Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-80,80},{-74.4,78.1},{-68.7,72.3},{-63.1,63},{-56.7,48.7},{-48.6,26.6},{-29.3,-32.5},{-22.1,-51.7},{-15.7,-65.3},{-10.1,-73.8},{-4.42,-78.8},{1.21,-79.9},{6.83,-77.1},{12.5,-70.6},{18.1,-60.6},{24.5,-45.7},{32.6,-23},{50.3,31.3},{57.5,50.7},{63.9,64.6},{69.5,73.4},{75.2,78.6},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>
 
</html>"));

    external "C" y=cos(u) ;

  end cos;

  function tan "tangent (u shall not be -pi/2, pi/2, 3*pi/2, ...)"
    extends baseIcon2;
    input SI.Angle u;
    output Real y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,-80},{-78.4,-68.4},{-76.8,-59.7},{-74.4,-50},{-71.2,-40.9},{-67.1,-33},{-60.7,-24.8},{-51.1,-17.2},{-35.8,-9.98},{-4.42,-1.07},{33.4,9.12},{49.4,16.2},{59.1,23.2},{65.5,30.6},{70.4,39.1},{73.6,47.4},{76,56.1},{77.6,63.8},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-90,24},{-18,72}}, textString="tan", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-37,-88},{-17,-72}}, textString="-5.8", fontName="Arial"),Text(visible=true, extent={{-33,70},{-13,86}}, textString=" 5.8", fontName="Arial"),Text(visible=true, extent={{70,5},{90,25}}, textString="1.4", fontName="Arial"),Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-80,-80},{-78.4,-68.4},{-76.8,-59.7},{-74.4,-50},{-71.2,-40.9},{-67.1,-33},{-60.7,-24.8},{-51.1,-17.2},{-35.8,-9.98},{-4.42,-1.07},{33.4,9.12},{49.4,16.2},{59.1,23.2},{65.5,30.6},{70.4,39.1},{73.6,47.4},{76,56.1},{77.6,63.8},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>
 
</html>"));

    external "C" y=tan(u) ;

  end tan;

  function asin "inverse sine (-1 <= u <= 1)"
    extends baseIcon2;
    input Real u;
    output SI.Angle y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,-49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,52.7},{75.2,62.2},{77.6,67.5},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-88,30},{-16,78}}, textString="asin", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Text(visible=true, extent={{-40,-88},{-15,-72}}, textString="-pi/2", fontName="Arial"),Text(visible=true, extent={{-38,72},{-13,88}}, textString=" pi/2", fontName="Arial"),Text(visible=true, extent={{70,5},{90,25}}, textString="+1", fontName="Arial"),Text(visible=true, extent={{-90,1},{-70,21}}, textString="-1", fontName="Arial"),Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,-49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,52.7},{75.2,62.2},{77.6,67.5},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>
 
</html>"));

    external "C" y=asin(u) ;

  end asin;

  function acos "inverse cosine (-1 <= u <= 1)"
    extends baseIcon2;
    input Real u;
    output SI.Angle y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,-80},{68,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-80},{68,-72},{68,-88},{90,-80}}),Line(visible=true, points={{-80,80},{-79.2,72.8},{-77.6,67.5},{-73.6,59.4},{-66.3,49.8},{-53.5,37.3},{-30.2,19.7},{37.4,-24.8},{57.5,-40.8},{68.7,-52.7},{75.2,-62.2},{77.6,-67.5},{80,-80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-86,-62},{-14,-14}}, textString="acos", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,-80},{84,-80}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,-80},{84,-74},{84,-86},{100,-80}}),Line(visible=true, points={{-80,80},{-79.2,72.8},{-77.6,67.5},{-73.6,59.4},{-66.3,49.8},{-53.5,37.3},{-30.2,19.7},{37.4,-24.8},{57.5,-40.8},{68.7,-52.7},{75.2,-62.2},{77.6,-67.5},{80,-80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-30,72},{-5,88}}, textString=" pi", fontName="Arial"),Text(visible=true, extent={{-94,-77},{-74,-57}}, textString="-1", fontName="Arial"),Text(visible=true, extent={{80,-65},{100,-45}}, textString="+1", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{90,-102},{110,-82}}, textString="u", fontName="Arial")}), Documentation(info="<html>
  
</html>"));

    external "C" y=acos(u) ;

  end acos;

  function atan "inverse tangent"
    extends baseIcon2;
    input Real u;
    output SI.Angle y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,-80},{-52.7,-75.2},{-37.4,-69.7},{-26.9,-63},{-19.7,-55.2},{-14.1,-45.8},{-10.1,-36.4},{-6.03,-23.9},{-1.21,-5.06},{5.23,21},{9.25,34.1},{13.3,44.2},{18.1,52.9},{24.5,60.8},{33.4,67.6},{47,73.6},{69.5,78.6},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-86,20},{-14,68}}, textString="atan", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-80,-80},{-52.7,-75.2},{-37.4,-69.7},{-26.9,-63},{-19.7,-55.2},{-14.1,-45.8},{-10.1,-36.4},{-6.03,-23.9},{-1.21,-5.06},{5.23,21},{9.25,34.1},{13.3,44.2},{18.1,52.9},{24.5,60.8},{33.4,67.6},{47,73.6},{69.5,78.6},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-32,71},{-12,91}}, textString="1.4", fontName="Arial"),Text(visible=true, extent={{-32,-91},{-12,-71}}, textString="-1.4", fontName="Arial"),Text(visible=true, extent={{73,10},{93,26}}, textString=" 5.8", fontName="Arial"),Text(visible=true, extent={{-103,4},{-83,20}}, textString="-5.8", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>
  
</html>"));

    external "C" y=atan(u) ;

  end atan;

  function atan2 "four quadrant inverse tangent"
    extends baseIcon2;
    input Real u1;
    input Real u2;
    output SI.Angle y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{0,-80},{8.93,-67.2},{17.1,-59.3},{27.3,-53.6},{42.1,-49.4},{69.9,-45.8},{80,-45.1}}, smooth=Smooth.Bezier),Line(visible=true, points={{-80,-34.9},{-46.1,-31.4},{-29.4,-27.1},{-18.3,-21.5},{-10.3,-14.5},{-2.03,-3.17},{7.97,11.6},{15.5,19.4},{24.3,25},{39,30},{62.1,33.5},{80,34.9}}, smooth=Smooth.Bezier),Line(visible=true, points={{-80,45.1},{-45.9,48.7},{-29.1,52.9},{-18.1,58.6},{-10.2,65.8},{-1.82,77.2},{0,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-90,-94},{-18,-46}}, textString="atan2", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{0,-80},{8.93,-67.2},{17.1,-59.3},{27.3,-53.6},{42.1,-49.4},{69.9,-45.8},{80,-45.1}}, smooth=Smooth.Bezier),Line(visible=true, points={{-80,-34.9},{-46.1,-31.4},{-29.4,-27.1},{-18.3,-21.5},{-10.3,-14.5},{-2.03,-3.17},{7.97,11.6},{15.5,19.4},{24.3,25},{39,30},{62.1,33.5},{80,34.9}}, smooth=Smooth.Bezier),Line(visible=true, points={{-80,45.1},{-45.9,48.7},{-29.1,52.9},{-18.1,58.6},{-10.2,65.8},{-1.82,77.2},{0,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-30,70},{-10,89}}, textString="pi", fontName="Arial"),Text(visible=true, extent={{-30,-88},{-10,-69}}, textString="-pi", fontName="Arial"),Text(visible=true, extent={{-30,30},{-10,49}}, textString="pi/2", fontName="Arial"),Line(visible=true, points={{0,40},{-8,40}}, color={192,192,192}),Line(visible=true, points={{0,-40},{-8,-40}}, color={192,192,192}),Text(visible=true, extent={{-30,-50},{-10,-31}}, textString="-pi/2", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<HTML>
y = atan2(u1,u2) computes y such that tan(y) = u1/u2 and
y is in the range -pi &lt; y &le; pi. u2 may be zero, provided
u1 is not zero.
</HTML>
"));

    external "C" y=atan2(u1,u2) ;

  end atan2;

  function sinh "hyperbolic sine"
    extends baseIcon2;
    input Real u;
    output Real y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,-80},{-76,-65.4},{-71.2,-51.4},{-65.5,-38.8},{-59.1,-28.1},{-51.1,-18.7},{-41.4,-11.4},{-27.7,-5.5},{-4.42,-0.653},{24.5,4.57},{39,10.1},{49.4,17.2},{57.5,25.9},{63.9,35.8},{69.5,47.4},{74.4,60.4},{78.4,73.8},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-88,32},{-16,80}}, textString="sinh", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-80,-80},{-76,-65.4},{-71.2,-51.4},{-65.5,-38.8},{-59.1,-28.1},{-51.1,-18.7},{-41.4,-11.4},{-27.7,-5.5},{-4.42,-0.653},{24.5,4.57},{39,10.1},{49.4,17.2},{57.5,25.9},{63.9,35.8},{69.5,47.4},{74.4,60.4},{78.4,73.8},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-31,72},{-11,88}}, textString="27", fontName="Arial"),Text(visible=true, extent={{-35,-88},{-15,-72}}, textString="-27", fontName="Arial"),Text(visible=true, extent={{70,5},{90,25}}, textString="4", fontName="Arial"),Text(visible=true, extent={{-98,1},{-78,21}}, textString="-4", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>
  
</html>"));

    external "C" y=sinh(u) ;

  end sinh;

  function cosh "hyperbolic cosine"
    extends baseIcon2;
    input Real u;
    output Real y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,-86.083},{68,-86.083}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-86.083},{68,-78.083},{68,-94.083},{90,-86.083}}),Line(visible=true, points={{-80,80},{-77.6,61.1},{-74.4,39.3},{-71.2,20.7},{-67.1,1.29},{-63.1,-14.6},{-58.3,-29.8},{-52.7,-43.5},{-46.2,-55.1},{-39,-64.3},{-30.2,-71.7},{-18.9,-77.1},{-4.42,-79.9},{10.9,-79.1},{23.7,-75.2},{34.2,-68.7},{42.2,-60.6},{48.6,-51.2},{54.3,-40},{59.1,-27.5},{63.1,-14.6},{67.1,1.29},{71.2,20.7},{74.4,39.3},{77.6,61.1},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{4,20},{66,66}}, textString="cosh", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,-86.083},{84,-86.083}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,-86.083},{84,-80.083},{84,-92.083},{100,-86.083}}),Line(visible=true, points={{-80,80},{-77.6,61.1},{-74.4,39.3},{-71.2,20.7},{-67.1,1.29},{-63.1,-14.6},{-58.3,-29.8},{-52.7,-43.5},{-46.2,-55.1},{-39,-64.3},{-30.2,-71.7},{-18.9,-77.1},{-4.42,-79.9},{10.9,-79.1},{23.7,-75.2},{34.2,-68.7},{42.2,-60.6},{48.6,-51.2},{54.3,-40},{59.1,-27.5},{63.1,-14.6},{67.1,1.29},{71.2,20.7},{74.4,39.3},{77.6,61.1},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-31,72},{-11,88}}, textString="27", fontName="Arial"),Text(visible=true, extent={{76,-81},{96,-61}}, textString="4", fontName="Arial"),Text(visible=true, extent={{-104,-83},{-84,-63}}, textString="-4", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{90,-108},{110,-88}}, textString="u", fontName="Arial")}), Documentation(info="<html>
  
</html>
"));

    external "C" y=cosh(u) ;

  end cosh;

  function tanh "hyperbolic tangent"
    extends baseIcon2;
    input Real u;
    output Real y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,-80},{-47.8,-78.7},{-35.8,-75.7},{-27.7,-70.6},{-22.1,-64.2},{-17.3,-55.9},{-12.5,-44.3},{-7.64,-29.2},{-1.21,-4.82},{6.83,26.3},{11.7,42},{16.5,54.2},{21.3,63.1},{26.9,69.9},{34.2,75},{45.4,78.4},{72,79.9},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-88,24},{-16,72}}, textString="tanh", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-80,-80},{-47.8,-78.7},{-35.8,-75.7},{-27.7,-70.6},{-22.1,-64.2},{-17.3,-55.9},{-12.5,-44.3},{-7.64,-29.2},{-1.21,-4.82},{6.83,26.3},{11.7,42},{16.5,54.2},{21.3,63.1},{26.9,69.9},{34.2,75},{45.4,78.4},{72,79.9},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{70,5},{90,25}}, textString="4", fontName="Arial"),Text(visible=true, extent={{-106,1},{-86,21}}, textString="-4", fontName="Arial"),Text(visible=true, extent={{-29,72},{-9,88}}, textString="1", fontName="Arial"),Text(visible=true, extent={{3,-88},{23,-72}}, textString="-1", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>
   
</html>"));

    external "C" y=tanh(u) ;

  end tanh;

  function exp "exponential, base e"
    extends baseIcon2;
    input Real u;
    output Real y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,-80.3976},{68,-80.3976}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,-80.3976},{68,-72.3976},{68,-88.3976},{90,-80.3976}}),Line(visible=true, points={{-80,-80},{-31,-77.9},{-6.03,-74},{10.9,-68.4},{23.7,-61},{34.2,-51.6},{43,-40.3},{50.3,-27.8},{56.7,-13.5},{62.3,2.23},{67.1,18.6},{72,38.2},{76,57.6},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-86,2},{-14,50}}, textString="exp", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,-80.3976},{84,-80.3976}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,-80.3976},{84,-74.3976},{84,-86.3976},{100,-80.3976}}),Line(visible=true, points={{-80,-80},{-31,-77.9},{-6.03,-74},{10.9,-68.4},{23.7,-61},{34.2,-51.6},{43,-40.3},{50.3,-27.8},{56.7,-13.5},{62.3,2.23},{67.1,18.6},{72,38.2},{76,57.6},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-31,72},{-11,88}}, textString="20", fontName="Arial"),Text(visible=true, extent={{-92,-103},{-72,-83}}, textString="-3", fontName="Arial"),Text(visible=true, extent={{70,-103},{90,-83}}, textString="3", fontName="Arial"),Text(visible=true, extent={{-18,-73},{2,-53}}, textString="1", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{96,-102},{116,-82}}, textString="u", fontName="Arial")}));

    external "C" y=exp(u) ;

  end exp;

  function log "natural (base e) logarithm (u shall be > 0)"
    extends baseIcon1;
    input Real u;
    output Real y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-80,-80},{-79.2,-50.6},{-78.4,-37},{-77.6,-28},{-76.8,-21.3},{-75.2,-11.4},{-72.8,-1.31},{-69.5,8.08},{-64.7,17.9},{-57.5,28},{-47,38.1},{-31.8,48.1},{-10.1,58},{22.1,68},{68.7,78.1},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-6,-72},{66,-24}}, textString="log", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-80,-80},{-79.2,-50.6},{-78.4,-37},{-77.6,-28},{-76.8,-21.3},{-75.2,-11.4},{-72.8,-1.31},{-69.5,8.08},{-64.7,17.9},{-57.5,28},{-47,38.1},{-31.8,48.1},{-10.1,58},{22.1,68},{68.7,78.1},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{-105,72},{-85,88}}, textString="3", fontName="Arial"),Text(visible=true, extent={{-109,-88},{-89,-72}}, textString="-3", fontName="Arial"),Text(visible=true, extent={{70,-23},{90,-3}}, textString="20", fontName="Arial"),Text(visible=true, extent={{-78,-21},{-58,-1}}, textString="1", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>
    
</html>"));

    external "C" y=log(u) ;

  end log;

  function log10 "base 10 logarithm (u shall be > 0)"
    extends baseIcon1;
    input Real u;
    output Real y;
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-90,0},{68,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{90,0},{68,8},{68,-8},{90,0}}),Line(visible=true, points={{-79.8,-80},{-79.2,-50.6},{-78.4,-37},{-77.6,-28},{-76.8,-21.3},{-75.2,-11.4},{-72.8,-1.31},{-69.5,8.08},{-64.7,17.9},{-57.5,28},{-47,38.1},{-31.8,48.1},{-10.1,58},{22.1,68},{68.7,78.1},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, fillColor={192,192,192}, extent={{-30,-70},{60,-22}}, textString="log10", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-100,0},{84,0}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{100,0},{84,6},{84,-6},{100,0}}),Line(visible=true, points={{-79.8,-80},{-79.2,-50.6},{-78.4,-37},{-77.6,-28},{-76.8,-21.3},{-75.2,-11.4},{-72.8,-1.31},{-69.5,8.08},{-64.7,17.9},{-57.5,28},{-47,38.1},{-31.8,48.1},{-10.1,58},{22.1,68},{68.7,78.1},{80,80}}, smooth=Smooth.Bezier),Text(visible=true, extent={{70,-23},{90,-3}}, textString="20", fontName="Arial"),Text(visible=true, extent={{-78,-21},{-58,-1}}, textString="1", fontName="Arial"),Text(visible=true, extent={{-109,72},{-89,88}}, textString=" 1.3", fontName="Arial"),Text(visible=true, extent={{-109,-88},{-89,-72}}, textString="-1.3", fontName="Arial"),Text(visible=true, fillColor={160,160,160}, extent={{92,-22},{112,-2}}, textString="u", fontName="Arial")}), Documentation(info="<html>
  
</html>"));

    external "C" y=log10(u) ;

  end log10;

  partial function baseIcon1 "Basic icon for mathematical function with y-axis on left side"
    annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{-80,80},{-88,80}}, color={192,192,192}),Line(visible=true, points={{-80,-80},{-88,-80}}, color={192,192,192}),Line(visible=true, points={{-80,-90},{-80,84}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{-75,90},{-55,110}}, textString="y", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,100},{-86,84},{-74,84},{-80,100}})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Line(visible=true, points={{-80,-80},{-80,68}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{-80,90},{-88,68},{-72,68},{-80,90}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,110},{150,150}}, textString="%name", fontName="Arial")}));
  end baseIcon1;

  partial function baseIcon2 "Basic icon for mathematical function with y-axis in middle"
    annotation(Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, points={{0,80},{-8,80}}, color={192,192,192}),Line(visible=true, points={{0,-80},{-8,-80}}, color={192,192,192}),Line(visible=true, points={{0,-90},{0,84}}, color={192,192,192}),Text(visible=true, fillColor={160,160,160}, extent={{5,90},{25,110}}, textString="y", fontName="Arial"),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{0,100},{-6,84},{6,84},{0,100}})}), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{-100,-100},{100,100}}),Line(visible=true, points={{0,-80},{0,68}}, color={192,192,192}),Polygon(visible=true, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, points={{0,90},{-8,68},{8,68},{0,90}}),Text(visible=true, fillColor={0,0,255}, fillPattern=FillPattern.Solid, extent={{-150,110},{150,150}}, textString="%name", fontName="Arial")}));
  end baseIcon2;

  function tempInterpol1 "temporary routine for linear interpolation (will be removed)"
    extends Modelica.Icons.Function;
    input Real u "input value (first column of table)";
    input Real table[:,:] "table to be interpolated";
    input Integer icol "column of table to be interpolated";
    output Real y "interpolated input value (icol column of table)";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  protected 
    Integer i;
    Integer n "number of rows of table";
    Real u1;
    Real u2;
    Real y1;
    Real y2;
  algorithm 
    n:=size(table, 1);
    if n <= 1 then 
      y:=table[1,icol];
    else
      if u <= table[1,1] then 
        i:=1;
      else
        i:=2;
        while (i < n and u >= table[i,1]) loop
          i:=i + 1;
        end while;
        i:=i - 1;
      end if;
      u1:=table[i,1];
      u2:=table[i + 1,1];
      y1:=table[i,icol];
      y2:=table[i + 1,icol];
      assert(u2 > u1, "Table index must be increasing");
      y:=y1 + (y2 - y1)*(u - u1)/(u2 - u1);
    end if;
    annotation(Documentation(info="<html>
  
</html>"));
  end tempInterpol1;

  function tempInterpol2 "temporary routine for vectorized linear interpolation (will be removed)"
    extends Modelica.Icons.Function;
    input Real u "input value (first column of table)";
    input Real table[:,:] "table to be interpolated";
    input Integer icol[:] "column(s) of table to be interpolated";
    output Real y[1,size(icol, 1)] "interpolated input value(s) (column(s) icol of table)";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  protected 
    Integer i;
    Integer n "number of rows of table";
    Real u1;
    Real u2;
    Real y1[1,size(icol, 1)];
    Real y2[1,size(icol, 1)];
  algorithm 
    n:=size(table, 1);
    if n <= 1 then 
      y:=transpose([table[1,icol]]);
    else
      if u <= table[1,1] then 
        i:=1;
      else
        i:=2;
        while (i < n and u >= table[i,1]) loop
          i:=i + 1;
        end while;
        i:=i - 1;
      end if;
      u1:=table[i,1];
      u2:=table[i + 1,1];
      y1:=transpose([table[i,icol]]);
      y2:=transpose([table[i + 1,icol]]);
      assert(u2 > u1, "Table index must be increasing");
      y:=y1 + (y2 - y1)*(u - u1)/(u2 - u1);
    end if;
    annotation(Documentation(info="<html>
  
</html>"));
  end tempInterpol2;

end Math;
