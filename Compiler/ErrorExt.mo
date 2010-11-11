/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�ping University, either from the above address,
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

package ErrorExt
"
  file:	       ErrorExt.mo
  package:     ErrorExt
  description: Error handling External interface

  RCS: $Id$

  This file contains the external interface to the error handling.
  Error messages are stored externally, impl. in C++."


public import Error;

public function updateCurrentComponent
  input String str;
  input Boolean writeable;
  input String fileName;
  input Integer rowstart;
  input Integer rowend;
  input Integer colstart;
  input Integer colend;
  external "C";
end updateCurrentComponent;

public function addMessage
  input Error.ErrorID id;
  input String msg_type;
  input String msg_severity;
  input String msg;
  input list<String> msg_tokens;

  external "C" Error_addMessage(id,msg_type,msg_severity,msg,msg_tokens) annotation(Library = "omcruntime");
end addMessage;

public function addSourceMessage
  input Error.ErrorID inErrorID1;
  input String inString2;
  input String inString3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Integer inInteger7;
  input Boolean inBoolean8;
  input String inString9;
  input String inString10;
  input list<String> inStringLst11;

  external "C" ;
end addSourceMessage;

public function printMessagesStr
  output String outString;

  external "C" ;
end printMessagesStr;

public function getNumMessages
  output Integer num;

  external "C";
end getNumMessages;

public function getNumErrorMessages
  output Integer num;

  external "C";
end getNumErrorMessages;

public function getMessagesStr
  output String outString;

  external "C" ;
end getMessagesStr;

public function clearMessages
  external "C" ;
end clearMessages;

public function errorOff

  external "C" ;
end errorOff;

public function errorOn

  external "C" ;
end errorOn;

public function setCheckpoint "sets a checkpoint for the error messages, so error messages can be rolled back (i.e. deleted) up to this point
A unique identifier for this checkpoint must be provided. It is checked when doing rollback or deletion"
  input String id "uniqe identifier for the checkpoint (up to the programmer to guarantee uniqueness)";
  external "C" ;
end setCheckpoint;

public function delCheckpoint "deletes the checkpoint at the top of the stack without 
removing the error messages issued since that checkpoint.
If the checkpoint id doesn't match, the application exits with -1.
"

  input String id "unique identifier";
  external "C" ;
end delCheckpoint;

public function printErrorsNoWarning
  output String outString;
  external "C" ;
end printErrorsNoWarning;

public function rollBack "rolls back error messages until the latest checkpoint, 
deleting all error messages added since that point in time. A unique identifier for the checkpoint must be provided
The application will exit with return code -1 if this identifier does not match."
  input String id "unique identifier";
  external "C" ;
end rollBack;

public function isTopCheckpoint 
"@author: adrpo
  This function checks if the specified checkpoint exists AT THE TOP OF THE STACK!.
  You can use it to rollBack/delete a checkpoint, but you're
  not sure that it exists (due to MetaModelica backtracking)."
  input String id "unique identifier";
  output Boolean isThere "tells us if the checkpoint exists (true) or doesn't (false)";
  external "C" ;
end isTopCheckpoint;

public function getLastDeletedCheckpoint 
"@author: adrpo
  This function returns the last deleted checkpoint id.
  Is needed to see if the previous phase generated some
  error messages or not"
  output String lastCheckpoint ;
  external "C" ;
end getLastDeletedCheckpoint;

end ErrorExt;

