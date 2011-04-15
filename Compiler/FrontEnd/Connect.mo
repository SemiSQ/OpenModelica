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

encapsulated package Connect
" file:        Connect.mo
  package:     Connect
  description: Connection set management

  RCS: $Id$

  Connections generate connection sets (datatype SET is described below)
  which are constructed during instantiation.  When a connection
  set is generated, it is used to create a number of equations.
  The kind of equations created depends on the type of the set.

  Connect.mo is called from Inst.mo and is responsible for
  creation of all connect-equations later passed to the DAE module
  in DAE.mo."

public import DAE;
public import Prefix;
public import Absyn;

public
uniontype Face"This type indicates whether a connector is an inside or an outside connector.
 Note: this is not the same as inner and outer references.
       A connector is inside if it connects from the outside into a
       component and it is outside if it connects out from the component.
       This is important when generating equations for flow variables,
       where outside connectors are multiplied with -1 (since flow is always into a component)."
  record INSIDE "This is an inside connection" end INSIDE;
  record OUTSIDE "This is an outside connection" end OUTSIDE;
end Face;

type EquSetElement    = tuple<DAE.ComponentRef, Face, DAE.ElementSource>;
type FlowSetElement   = tuple<DAE.ComponentRef, Face, DAE.ElementSource>;
type StreamSetElement = tuple<DAE.ComponentRef, DAE.ComponentRef, Face, DAE.ElementSource>;

// FlowStreamConnect models an association between a stream variable and a flow
// variable, which is needed to implement the stream operators. The Sets type
// have a list of these associations that are added when a connector is
// instantiated, and when two streams are connected their associated flow
// variables are looked up in that list.
type StreamFlowConnect = tuple<DAE.ComponentRef, DAE.ComponentRef>;

public
uniontype Set "A connection set is represented using the Set type."

  record EQU "a list of component references"
    list<EquSetElement> expComponentRefLst;
  end EQU;

  record FLOW "a list of component reference and a face"
    list<FlowSetElement> tplExpComponentRefFaceLst;
  end FLOW;

  record STREAM "a list of component reference for stream, a component reference for corresponding flow and a face"
    list<StreamSetElement> tplExpComponentRefFaceLst;
  end STREAM;

end Set;

public
uniontype Sets "The connection \'Sets\' contains
   - the connection set
   - a list of component references occuring in connect statemens
   - a list of deleted components
   - connect statements to propagate upwards in instance hierachy (inner/outer connectors)

  The list of componentReferences are used only when evaluating the cardinality operator.
  It is passed -into- classes to be instantiated, while the Set list is returned -from-
  instantiated classes.
  The list of deleted components is required to be able to remove connections to them."
  record SETS
    list<Set> setLst "the connection set";
    list<DAE.ComponentRef> connection "connection_set connect_refs - list of
                crefs in connect statements. This is used to be able to evaluate cardinality.
                It is registered in env by Inst.addConnnectionSetToEnv.";
    list<DAE.ComponentRef> deletedComponents "list of components with conditional declaration = false";
    list<OuterConnect> outerConnects "connect statements to propagate upwards";
    list<StreamFlowConnect> streamFlowConnects "list of stream-flow associations.";
  end SETS;
end Sets;

uniontype OuterConnect
  record OUTERCONNECT
    Prefix.Prefix scope "the scope where this connect was created";
    DAE.ComponentRef cr1 "the lhs component reference";
    Absyn.InnerOuter io1 "inner/outer attribute for cr1 component";
    Face f1 "the face of the lhs component";
    DAE.ComponentRef cr2 "the rhs component reference";
    Absyn.InnerOuter io2 "inner/outer attribute for cr2 component";
    Face f2 "the face of the rhs component";
    DAE.ElementSource source "the element origin";
  end OUTERCONNECT;
end OuterConnect;

public constant Sets emptySet=SETS({},{},{},{},{});

end Connect;

