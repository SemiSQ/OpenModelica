/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Parser
" file:        Parser.mo
  package:     Parser
  description: Interface to external code for parsing

  $Id$

  The parser module is used for both parsing of files and statements in
  interactive mode."

public import Absyn;
public import Interactive;
protected import Config;
protected import ParserExt;

public function parse "Parse a mo-file"
  input String filename;
  output Absyn.Program outProgram;
algorithm
  outProgram := ParserExt.parse(filename, Config.acceptedGrammar(),
    Config.getRunningTestsuite());
end parse;

public function parseexp "Parse a mos-file"
  input String filename;
  output Interactive.Statements outStatements;
algorithm
  outStatements := ParserExt.parseexp(filename,
    Config.acceptedGrammar(), Config.getRunningTestsuite());
end parseexp;

public function parsestring "Parse a string as if it were a stored definition"
  input String str;
  input String infoFilename := "<interactive>";
  output Absyn.Program outProgram;
algorithm
  outProgram := ParserExt.parsestring(str,infoFilename,
    Config.acceptedGrammar(), Config.getRunningTestsuite());
end parsestring;

public function parsestringexp "Parse a string as if it was a sequence of statements"
  input String str;
  input String infoFilename := "<interactive>";
  output Interactive.Statements outStatements;
algorithm
  outStatements := ParserExt.parsestringexp(str,infoFilename,
    Config.acceptedGrammar(), Config.getRunningTestsuite());
end parsestringexp;
end Parser;

