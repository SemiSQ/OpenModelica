within SiemensPowerOMCtest.Media.TTSE.Utilities;
function T_ph_dp "T(p,h)/dp"
  import SI = Modelica.SIunits;
    input SI.Pressure p "Pressure";
    input SI.SpecificEnthalpy h "Specific Enthalpy";
    input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
    output Real dT_dp "Partial derivative dT/dp";

    external "C" dT_dp=TTSE_d1_T_ph_dp(p,h,phase);
    annotation (Library={"TTSEmoI", "TTSE"}, Documentation(info="<html>
<p>This function returns the partial derivative of T wrt p versus p and h according to TTSE. </p>
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
                           <td> </td>
                </tr> 
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td> </td>
                  </tr> 
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY. 
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
        revisions="<html>
  <ul>
  <li> May 2011 by Julien Bonifay
  </ul>
  </html>"));

end T_ph_dp;
