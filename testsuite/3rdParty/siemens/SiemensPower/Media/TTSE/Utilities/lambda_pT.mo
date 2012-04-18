within SiemensPower.Media.TTSE.Utilities;
function lambda_pT "lambda(p,T)"
  import SI = Modelica.SIunits;
  input Integer phase "-1: water, 0: unknown, 1: sat water, 2: steam";
  input SI.Pressure p "Pressure";
  input SI.Temperature T "Temperature";

  output Real lambda "Conductivity";

  external "C" lambda= TTSE_lambda_pT(phase, p,T);
  annotation(Library={"TTSEmoI", "TTSE"}, Documentation(info="<html>
<p>This function returns thermal conductivity as function of p and T. The water/steam functions are computed according to TTSE. </p>
</html>
<HTML> 
       <p>  
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\"mailto:\"julien.bonifay@siemens.com>Julien Bonifay</a> </td>
                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr> 
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td>internal </td>
                </tr> 

           </table>
                Copyright &copy  2007 Siemens AG. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. 
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
        revisions="<html>
  <ul>
  <li> May 2011 by Julien Bonifay
  </ul>
  </html>"));

end lambda_pT;
