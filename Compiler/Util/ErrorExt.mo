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

encapsulated package ErrorExt
"
  file:         ErrorExt.mo
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
  external "C" ErrorImpl__updateCurrentComponent(str,writeable,fileName,rowstart,rowend,colstart,colend) annotation(Library = "omcruntime");
end updateCurrentComponent;

public function addMessage
  input Error.ErrorID id;
  input Error.MessageType msg_type;
  input Error.Severity msg_severity;
  input String msg;
  input list<String> msg_tokens;

  external "C" Error_addMessage(id,msg_type,msg_severity,msg,msg_tokens) annotation(Library = "omcruntime");
end addMessage;

public function addSourceMessage
  input Error.ErrorID id;
  input Error.MessageType msg_type;
  input Error.Severity msg_severity;
  input Integer sline;
  input Integer scol;
  input Integer eline;
  input Integer ecol;
  input Boolean read_only;
  input String filename;
  input String msg;
  input list<String> tokens;

  external "C" Error_addSourceMessage(id,msg_type,msg_severity,sline,scol,eline,ecol,read_only,filename,msg,tokens) annotation(Library = "omcruntime");
end addSourceMessage;

public function printMessagesStr
  output String outString;

  external "C" outString=Error_printMessagesStr() annotation(Library = "omcruntime");
end printMessagesStr;

public function getNumMessages
  output Integer num;

  external "C" num=Error_getNumMessages() annotation(Library = "omcruntime");
end getNumMessages;

public function getNumErrorMessages
  output Integer num;

  external "C" num=ErrorImpl__getNumErrorMessages() annotation(Library = "omcruntime");
end getNumErrorMessages;

public function getMessages
  output list<Error.TotalMessage> res;

  external "C" res=Error_getMessagesStr() annotation(Library = "omcruntime");
end getMessages;

public function clearMessages
  external "C" ErrorImpl__clearMessages() annotation(Library = "omcruntime");
end clearMessages;

public function errorOff

  external "C" Error_errorOff() annotation(Library = "omcruntime");
end errorOff;

public function errorOn

  external "C" Error_errorOn() annotation(Library = "omcruntime");
end errorOn;

public function setCheckpoint "sets a checkpoint for the error messages, so error messages can be rolled back (i.e. deleted) up to this point
A unique identifier for this checkpoint must be provided. It is checked when doing rollback or deletion"
  input String id "uniqe identifier for the checkpoint (up to the programmer to guarantee uniqueness)";
  external "C" ErrorImpl__setCheckpoint(id) annotation(Library = "omcruntime");
end setCheckpoint;

public function delCheckpoint "deletes the checkpoint at the top of the stack without 
removing the error messages issued since that checkpoint.
If the checkpoint id doesn't match, the application exits with -1.
"

  input String id "unique identifier";
  external "C" ErrorImpl__delCheckpoint(id) annotation(Library = "omcruntime");
end delCheckpoint;

public function printErrorsNoWarning
  output String outString;
  external "C" outString=Error_printErrorsNoWarning() annotation(Library = "omcruntime");
end printErrorsNoWarning;

public function rollBack "rolls back error messages until the latest checkpoint, 
deleting all error messages added since that point in time. A unique identifier for the checkpoint must be provided
The application will exit with return code -1 if this identifier does not match."
  input String id "unique identifier";
  external "C" ErrorImpl__rollBack(id) annotation(Library = "omcruntime");
end rollBack;

public function isTopCheckpoint 
"@author: adrpo
  This function checks if the specified checkpoint exists AT THE TOP OF THE STACK!.
  You can use it to rollBack/delete a checkpoint, but you're
  not sure that it exists (due to MetaModelica backtracking)."
  input String id "unique identifier";
  output Boolean isThere "tells us if the checkpoint exists (true) or doesn't (false)";
  external "C" isThere=ErrorImpl__isTopCheckpoint(id) annotation(Library = "omcruntime");
end isTopCheckpoint;

public function getLastDeletedCheckpoint 
"@author: adrpo
  This function returns the last deleted checkpoint id.
  Is needed to see if the previous phase generated some
  error messages or not"
  output String lastCheckpoint ;
  external "C" lastCheckpoint=Error_getLastDeletedCheckpoint() annotation(Library = "omcruntime");
end getLastDeletedCheckpoint;

end ErrorExt;

